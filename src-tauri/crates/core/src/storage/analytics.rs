//! 训练分析的落库与查询。
//!
//! 纯算法在 `crate::analytics`；这里负责取数、物化、回放和给 App 的查询门面。
//! 页面只读 `daily_performance` / `workout_analytics`，不扫描逐秒采样。

use super::*;

use crate::analytics::{
    current_power, display_load, instant_power, recovery, trimp, AthleteThresholds, DatedPower,
    RecoveryInput, TrainingSample,
};

use chrono::{Duration, Local, NaiveDate};

use serde::Serialize;

use std::collections::{BTreeMap, HashMap};

/// 分析结果的结构版本。算法或参数变化时往前走一格，触发一次全量回放。
pub const ANALYTICS_REVISION: &str = "pacebridge-analytics-2026-11-v1";

const ANALYTICS_META_KEY: &str = "analytics_revision";

/// 日常增量重算的窗口。
pub const DEFAULT_ANALYTICS_DAYS: i64 = 180;

/// 第一次生成分析时回填多久。当前跑力需要 42 天历史，恢复需要 28 天；
/// 两年足够，且不会让老库第一次打开等太久。
const BACKFILL_ANALYTICS_DAYS: i64 = 730;

const RUN_TYPES: [&str; 3] = ["run", "trail_running", "treadmill"];

const RUN_TYPES_SQL: &str = "'run', 'trail_running', 'treadmill'";

/// 一次窗口查询的五个核心指标 + 上一周期同长度窗口的对照。
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MetricSummary {
    pub window_days: i64,
    pub current_power: Option<f64>,
    pub previous_power: Option<f64>,
    pub distance_meters: f64,
    pub previous_distance_meters: f64,
    pub avg_pace_sec_per_km: Option<f64>,
    pub previous_avg_pace_sec_per_km: Option<f64>,
    pub training_load: Option<f64>,
    pub previous_training_load: Option<f64>,
    /// 周均负荷映射到 0–1000。
    pub training_load_score: Option<u32>,
    pub previous_training_load_score: Option<u32>,
    pub recovery_ratio: Option<f64>,
    pub previous_recovery_ratio: Option<f64>,
    pub workouts: i64,
    pub previous_workouts: i64,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TrendPoint {
    pub date: String,
    pub value: f64,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LoadDay {
    pub date: String,
    pub trimp: Option<f64>,
    pub display_load: Option<u32>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RecoveryDay {
    pub date: String,
    pub recovery_score: Option<i64>,
    pub fully_recovered: Option<bool>,
}

#[derive(Debug, Clone, Default)]
struct WindowStats {
    workouts: i64,
    distance_m: f64,
    moving_seconds: f64,
    current_power: Option<f64>,
    trimp_total: Option<f64>,
    recovery_ratio: Option<f64>,
}

#[derive(Debug, Clone)]
struct AnalyticalWorkout {
    workout_id: String,
    day: String,
    kind: String,
    start_time: String,
    duration_seconds: Option<i64>,
    avg_hr: Option<f64>,
}

impl Database {
    /// 当前库里分析结果的结构版本。
    pub fn analytics_revision(&self) -> Result<Option<String>> {
        self.get_app_meta(ANALYTICS_META_KEY)
    }

    /// 结构版本是否与代码一致。
    pub fn analytics_ready(&self) -> Result<bool> {
        Ok(self.analytics_revision()?.as_deref() == Some(ANALYTICS_REVISION))
    }

    /// 重算最近 `window_days` 天的分析结果。第一次调用会回填两年。
    ///
    /// 返回本次实际分析的训练条数。函数不处理事务边界：调用方应在同步完成后、
    /// 持有写锁时调用；内部按训练逐条 upsert，重复调用是幂等的。
    pub fn recompute_analytics(&self, window_days: i64) -> Result<usize> {
        let first_run = !self.analytics_ready()?;
        let days = if first_run {
            BACKFILL_ANALYTICS_DAYS
        } else {
            window_days.clamp(1, 3650)
        };
        let today = Local::now().date_naive();
        let start = today - Duration::days(days - 1);

        let thresholds = self.analytics_thresholds()?;
        let workouts = self.analytics_workouts(start, today)?;
        let mut trimp_by_day: BTreeMap<String, Vec<Option<f64>>> = BTreeMap::new();

        for workout in &workouts {
            let samples = self.analytics_samples(&workout.workout_id, &workout.start_time)?;
            let power = if RUN_TYPES.contains(&workout.kind.as_str()) {
                thresholds.map(|thresholds| instant_power(&samples, thresholds))
            } else {
                None
            };
            let trimp_value = thresholds.and_then(|thresholds| {
                trimp(
                    workout.duration_seconds?,
                    workout.avg_hr,
                    &samples,
                    thresholds,
                )
            });
            trimp_by_day
                .entry(workout.day.clone())
                .or_default()
                .push(trimp_value);

            let (instant, gap_pace, efficiency, stable_seconds, confidence) = match power {
                Some(power) => (
                    power.power,
                    power.gap_pace_sec_km,
                    power.aerobic_efficiency,
                    power.stable_seconds,
                    power.confidence.as_str(),
                ),
                None => (None, None, None, 0, "low"),
            };
            self.conn.execute(
                "INSERT INTO workout_analytics
                    (workout_id, instant_power, gap_pace_sec_km, aerobic_efficiency, trimp,
                     stable_seconds, confidence, analysis_rev, computed_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
                 ON CONFLICT(workout_id) DO UPDATE SET
                    instant_power = excluded.instant_power,
                    gap_pace_sec_km = excluded.gap_pace_sec_km,
                    aerobic_efficiency = excluded.aerobic_efficiency,
                    trimp = excluded.trimp,
                    stable_seconds = excluded.stable_seconds,
                    confidence = excluded.confidence,
                    analysis_rev = excluded.analysis_rev,
                    computed_at = excluded.computed_at",
                params![
                    workout.workout_id,
                    instant,
                    gap_pace,
                    efficiency,
                    trimp_value,
                    stable_seconds,
                    confidence,
                    ANALYTICS_REVISION,
                    Utc::now().to_rfc3339(),
                ],
            )?;
        }

        self.recompute_daily_performance(start, today, &trimp_by_day)?;
        self.set_app_meta(ANALYTICS_META_KEY, ANALYTICS_REVISION)?;
        Ok(workouts.len())
    }

    /// 最近一个窗口的五个指标。
    pub fn metric_summary(&self, window_days: i64) -> Result<MetricSummary> {
        let days = window_days.clamp(1, 3650);
        let today = Local::now().date_naive();
        let start = today - Duration::days(days - 1);
        let previous_start = start - Duration::days(days);
        let previous_end = start - Duration::days(1);

        let current = self.window_stats(start, today)?;
        let previous = self.window_stats(previous_start, previous_end)?;
        Ok(MetricSummary {
            window_days: days,
            current_power: current.current_power,
            previous_power: previous.current_power,
            distance_meters: round1(current.distance_m),
            previous_distance_meters: round1(previous.distance_m),
            avg_pace_sec_per_km: pace(current.moving_seconds, current.distance_m),
            previous_avg_pace_sec_per_km: pace(previous.moving_seconds, previous.distance_m),
            training_load: current.trimp_total.map(round1),
            previous_training_load: previous.trimp_total.map(round1),
            training_load_score: current.trimp_total.map(|value| weekly_score(value, days)),
            previous_training_load_score: previous
                .trimp_total
                .map(|value| weekly_score(value, days)),
            recovery_ratio: current.recovery_ratio,
            previous_recovery_ratio: previous.recovery_ratio,
            workouts: current.workouts,
            previous_workouts: previous.workouts,
        })
    }

    /// 单指标逐日趋势。
    ///
    /// `metric` 接受 `power` / `distance` / `pace` / `load` / `recovery`。
    pub fn metric_trend(&self, metric: &str, window_days: i64) -> Result<Vec<TrendPoint>> {
        let days = window_days.clamp(1, 3650);
        let today = Local::now().date_naive();
        let start = today - Duration::days(days - 1);
        let start_text = start.to_string();
        let end_text = today.to_string();

        let mut points = Vec::new();
        match metric {
            "power" => {
                let mut statement = self.conn.prepare(
                    "SELECT date, current_power FROM daily_performance
                     WHERE date BETWEEN ?1 AND ?2 AND current_power IS NOT NULL
                     ORDER BY date",
                )?;
                let rows = statement.query_map(params![start_text, end_text], |row| {
                    Ok(TrendPoint {
                        date: row.get(0)?,
                        value: row.get(1)?,
                    })
                })?;
                points.extend(rows.collect::<std::result::Result<Vec<_>, _>>()?);
            }
            "load" => {
                let mut statement = self.conn.prepare(
                    "SELECT date, trimp_total FROM daily_performance
                     WHERE date BETWEEN ?1 AND ?2 AND trimp_total IS NOT NULL
                     ORDER BY date",
                )?;
                let rows = statement.query_map(params![start_text, end_text], |row| {
                    Ok(TrendPoint {
                        date: row.get(0)?,
                        value: row.get(1)?,
                    })
                })?;
                points.extend(rows.collect::<std::result::Result<Vec<_>, _>>()?);
            }
            "recovery" => {
                let mut statement = self.conn.prepare(
                    "SELECT date, recovery_score FROM daily_performance
                     WHERE date BETWEEN ?1 AND ?2 AND recovery_score IS NOT NULL
                     ORDER BY date",
                )?;
                let rows = statement.query_map(params![start_text, end_text], |row| {
                    Ok(TrendPoint {
                        date: row.get(0)?,
                        value: row.get(1)?,
                    })
                })?;
                points.extend(rows.collect::<std::result::Result<Vec<_>, _>>()?);
            }
            "distance" => {
                let mut statement = self.conn.prepare(&format!(
                    "SELECT date(start_time, 'localtime') AS day, SUM(distance_meters)
                     FROM workouts_visible
                     WHERE COALESCE(workout_type_override, workout_type) IN ({RUN_TYPES_SQL})
                       AND date(start_time, 'localtime') BETWEEN ?1 AND ?2
                     GROUP BY day ORDER BY day"
                ))?;
                let rows = statement.query_map(params![start_text, end_text], |row| {
                    let date: String = row.get(0)?;
                    let value: Option<f64> = row.get(1)?;
                    Ok(value.map(|value| TrendPoint {
                        date,
                        value: round1(value),
                    }))
                })?;
                let values = rows.collect::<std::result::Result<Vec<_>, _>>()?;
                points.extend(values.into_iter().flatten());
            }
            "pace" => {
                let mut statement = self.conn.prepare(&format!(
                    "SELECT date(start_time, 'localtime') AS day,
                            SUM(COALESCE(NULLIF(moving_seconds, 0),
                                CAST(ROUND((julianday(end_time) - julianday(start_time)) * 86400) AS INTEGER))),
                            SUM(distance_meters)
                     FROM workouts_visible
                     WHERE COALESCE(workout_type_override, workout_type) IN ({RUN_TYPES_SQL})
                       AND date(start_time, 'localtime') BETWEEN ?1 AND ?2
                     GROUP BY day ORDER BY day"
                ))?;
                let rows = statement.query_map(params![start_text, end_text], |row| {
                    let date: String = row.get(0)?;
                    let seconds: Option<f64> = row.get(1)?;
                    let distance: Option<f64> = row.get(2)?;
                    Ok(match (seconds, distance) {
                        (Some(seconds), Some(distance)) if distance > 0.0 => Some(TrendPoint {
                            date,
                            value: round1(seconds * 1000.0 / distance),
                        }),
                        _ => None,
                    })
                })?;
                let values = rows.collect::<std::result::Result<Vec<_>, _>>()?;
                points.extend(values.into_iter().flatten());
            }
            other => {
                return Err(ZeppBridgeError::ConfigError(format!(
                    "未知的分析指标: {other}"
                )));
            }
        }
        points.sort_by(|left, right| left.date.cmp(&right.date));
        Ok(points)
    }

    /// 每日训练负荷，供堆叠柱状图使用。
    pub fn load_distribution(&self, window_days: i64) -> Result<Vec<LoadDay>> {
        let days = window_days.clamp(1, 3650);
        let today = Local::now().date_naive();
        let start = today - Duration::days(days - 1);
        let mut statement = self.conn.prepare(
            "SELECT date, trimp_total FROM daily_performance
             WHERE date BETWEEN ?1 AND ?2 ORDER BY date",
        )?;
        let rows = statement.query_map(params![start.to_string(), today.to_string()], |row| {
            let trimp: Option<f64> = row.get(1)?;
            Ok(LoadDay {
                date: row.get(0)?,
                trimp,
                display_load: trimp.map(display_load),
            })
        })?;
        Ok(rows.collect::<std::result::Result<Vec<_>, _>>()?)
    }

    /// 每日恢复分。
    pub fn recovery_days(&self, window_days: i64) -> Result<Vec<RecoveryDay>> {
        let days = window_days.clamp(1, 3650);
        let today = Local::now().date_naive();
        let start = today - Duration::days(days - 1);
        let mut statement = self.conn.prepare(
            "SELECT date, recovery_score, fully_recovered FROM daily_performance
             WHERE date BETWEEN ?1 AND ?2 ORDER BY date",
        )?;
        let rows = statement.query_map(params![start.to_string(), today.to_string()], |row| {
            let recovered: Option<i64> = row.get(2)?;
            Ok(RecoveryDay {
                date: row.get(0)?,
                recovery_score: row.get(1)?,
                fully_recovered: recovered.map(|value| value == 1),
            })
        })?;
        Ok(rows.collect::<std::result::Result<Vec<_>, _>>()?)
    }

    fn analytics_thresholds(&self) -> Result<Option<AthleteThresholds>> {
        let profile = self.athlete_profile()?;
        let max_hr = profile
            .observed_max_hr
            .map(f64::from)
            .or_else(|| profile.device_max_hr.as_ref().map(|value| value.value));
        let resting_hr = profile
            .resting_hr_30d_average
            .or_else(|| profile.resting_hr.as_ref().map(|value| value.value));
        Ok(match (max_hr, resting_hr) {
            (Some(max_hr), Some(resting_hr)) if max_hr > resting_hr => {
                Some(AthleteThresholds { max_hr, resting_hr })
            }
            _ => None,
        })
    }

    fn analytics_workouts(
        &self,
        start: NaiveDate,
        end: NaiveDate,
    ) -> Result<Vec<AnalyticalWorkout>> {
        let mut statement = self.conn.prepare(
            "SELECT workout_id, date(start_time, 'localtime'),
                    COALESCE(workout_type_override, workout_type),
                    start_time,
                    COALESCE(NULLIF(moving_seconds, 0),
                        CAST(ROUND((julianday(end_time) - julianday(start_time)) * 86400) AS INTEGER)),
                    avg_hr
             FROM workouts_visible
             WHERE date(start_time, 'localtime') BETWEEN ?1 AND ?2
             ORDER BY start_time",
        )?;
        let rows = statement.query_map(params![start.to_string(), end.to_string()], |row| {
            Ok(AnalyticalWorkout {
                workout_id: row.get(0)?,
                day: row.get(1)?,
                kind: row.get(2)?,
                start_time: row.get(3)?,
                duration_seconds: row.get(4)?,
                avg_hr: row.get(5)?,
            })
        })?;
        Ok(rows.collect::<std::result::Result<Vec<_>, _>>()?)
    }

    fn analytics_samples(&self, workout_id: &str, start_time: &str) -> Result<Vec<TrainingSample>> {
        let mut statement = self.conn.prepare(
            "SELECT CAST(strftime('%s', timestamp) AS INTEGER) - CAST(strftime('%s', ?2) AS INTEGER),
                    COALESCE(speed, CASE WHEN pace > 0 THEN 1.0 / pace END),
                    heart_rate,
                    altitude
             FROM workout_samples WHERE workout_id = ?1 ORDER BY timestamp",
        )?;
        let rows = statement.query_map(params![workout_id, start_time], |row| {
            let offset: Option<i64> = row.get(0)?;
            let speed: Option<f64> = row.get(1)?;
            let heart_rate: Option<f64> = row.get(2)?;
            let altitude: Option<f64> = row.get(3)?;
            Ok(offset.map(|offset| TrainingSample {
                offset_seconds: offset,
                speed_mps: speed.filter(|value| value.is_finite() && *value > 0.0),
                heart_rate: heart_rate.filter(|value| value.is_finite() && *value > 0.0),
                altitude_m: altitude.filter(|value| value.is_finite()),
            }))
        })?;
        let values = rows.collect::<std::result::Result<Vec<_>, _>>()?;
        Ok(values
            .into_iter()
            .flatten()
            .filter(|sample| sample.offset_seconds >= 0)
            .collect())
    }

    fn recompute_daily_performance(
        &self,
        start: NaiveDate,
        end: NaiveDate,
        trimp_by_day: &BTreeMap<String, Vec<Option<f64>>>,
    ) -> Result<()> {
        let metrics = self.daily_metrics_map(start, end)?;
        let sleeps = self.sleep_minutes_map(start, end)?;
        let power_history =
            self.instant_power_history(start - Duration::days(analytics_power_window()), end)?;
        let prior = self.prior_daily_performance(start)?;
        let mut daily_trimp: BTreeMap<String, Option<f64>> = BTreeMap::new();
        for offset in 0..=28 {
            let date = start - Duration::days(28 - offset);
            let key = date.to_string();
            let value = trimp_by_day
                .get(&key)
                .map(|values| {
                    let mut sum = 0.0;
                    let mut any = false;
                    for value in values.iter().flatten() {
                        sum += value;
                        any = true;
                    }
                    any.then_some(sum)
                })
                .unwrap_or_else(|| prior.trimp.get(&key).copied().flatten());
            daily_trimp.insert(key, value);
        }

        self.conn.execute(
            "DELETE FROM daily_performance WHERE date >= ?1",
            [start.to_string()],
        )?;

        let mut state = prior.state;
        if let Some(last_date) = prior.last_date {
            let gap = (start - last_date).num_days() - 1;
            for _ in 0..gap.max(0) {
                state = state.advance(0.0);
            }
        }

        let mut day = start;
        while day <= end {
            let key = day.to_string();
            let trimp_total = trimp_by_day
                .get(&key)
                .map(|values| {
                    let mut sum = 0.0;
                    let mut any = false;
                    for value in values.iter().flatten() {
                        sum += value;
                        any = true;
                    }
                    any.then_some(sum)
                })
                .unwrap_or(Some(0.0));
            state = state.advance(trimp_total.unwrap_or(0.0));
            daily_trimp.insert(key.clone(), trimp_total);

            let previous_day = (day - Duration::days(1)).to_string();
            let previous_trimp = daily_trimp.get(&previous_day).copied().flatten();
            let chronic = chronic_average(&daily_trimp, day);
            let day_metrics = metrics.get(&key).cloned().unwrap_or_default();
            let recovery_score = recovery(RecoveryInput {
                sleep_minutes: sleeps.get(&key).map(|minutes| *minutes as f64),
                sleep_hrv: day_metrics.get("sleep_hrv").copied(),
                hrv_baseline: day_metrics.get("hrv_baseline").copied(),
                resting_hr: day_metrics.get("resting_hr").copied(),
                rhr_baseline: day_metrics.get("rhr_baseline").copied(),
                previous_day_trimp: previous_trimp,
                chronic_daily_trimp: chronic,
            });
            let current = current_power_for_day(&power_history, day);
            self.conn.execute(
                "INSERT OR REPLACE INTO daily_performance
                    (date, current_power, trimp_total, fitness, fatigue, form, recovery_score,
                     fully_recovered, analysis_rev, computed_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
                params![
                    key,
                    current,
                    trimp_total,
                    state.fitness,
                    state.fatigue,
                    state.form(),
                    recovery_score.score.map(i64::from),
                    recovery_score
                        .fully_recovered
                        .map(|value| if value { 1i64 } else { 0i64 }),
                    ANALYTICS_REVISION,
                    Utc::now().to_rfc3339(),
                ],
            )?;
            day += Duration::days(1);
        }
        Ok(())
    }

    fn daily_metrics_map(
        &self,
        start: NaiveDate,
        end: NaiveDate,
    ) -> Result<HashMap<String, HashMap<String, f64>>> {
        let days = (end - start).num_days() + 1;
        let names = vec![
            "sleep_hrv".to_string(),
            "hrv_baseline".to_string(),
            "resting_hr".to_string(),
            "rhr_baseline".to_string(),
        ];
        let mut map: HashMap<String, HashMap<String, f64>> = HashMap::new();
        for series in self.metric_series(&names, days)? {
            for point in series.points {
                map.entry(point.date)
                    .or_default()
                    .insert(series.metric.clone(), point.value);
            }
        }
        Ok(map)
    }

    fn sleep_minutes_map(&self, start: NaiveDate, end: NaiveDate) -> Result<HashMap<String, i64>> {
        let mut statement = self.conn.prepare(
            "SELECT date(end_time, 'localtime') AS day, duration_minutes
             FROM sleep_sessions
             WHERE date(end_time, 'localtime') BETWEEN ?1 AND ?2
             ORDER BY day, duration_minutes DESC",
        )?;
        let rows = statement.query_map(params![start.to_string(), end.to_string()], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, i64>(1)?))
        })?;
        let mut map = HashMap::new();
        for row in rows {
            let (day, minutes) = row?;
            map.entry(day).or_insert(minutes);
        }
        Ok(map)
    }

    fn instant_power_history(
        &self,
        start: NaiveDate,
        end: NaiveDate,
    ) -> Result<Vec<(NaiveDate, f64)>> {
        let mut statement = self.conn.prepare(
            "SELECT date(w.start_time, 'localtime'), a.instant_power
             FROM workout_analytics a
             JOIN workouts w ON w.workout_id = a.workout_id
             WHERE a.instant_power IS NOT NULL
               AND date(w.start_time, 'localtime') BETWEEN ?1 AND ?2
             ORDER BY w.start_time",
        )?;
        let rows = statement.query_map(params![start.to_string(), end.to_string()], |row| {
            Ok((row.get::<_, String>(0)?, row.get::<_, f64>(1)?))
        })?;
        let mut history = Vec::new();
        for row in rows {
            let (day, power) = row?;
            if let Ok(date) = NaiveDate::parse_from_str(&day, "%Y-%m-%d") {
                history.push((date, power));
            }
        }
        Ok(history)
    }

    fn prior_daily_performance(&self, start: NaiveDate) -> Result<PriorPerformance> {
        let mut prior = PriorPerformance::default();
        {
            let mut statement = self.conn.prepare(
                "SELECT date, fitness, fatigue FROM daily_performance
                 WHERE date < ?1 ORDER BY date DESC LIMIT 1",
            )?;
            let row = statement
                .query_row([start.to_string()], |row| {
                    Ok((
                        row.get::<_, String>(0)?,
                        row.get::<_, Option<f64>>(1)?,
                        row.get::<_, Option<f64>>(2)?,
                    ))
                })
                .optional()?;
            if let Some((date, fitness, fatigue)) = row {
                prior.last_date = NaiveDate::parse_from_str(&date, "%Y-%m-%d").ok();
                prior.state = crate::analytics::BanisterState {
                    fitness: fitness.unwrap_or(0.0),
                    fatigue: fatigue.unwrap_or(0.0),
                };
            }
        }
        {
            let mut statement = self.conn.prepare(
                "SELECT date, trimp_total FROM daily_performance
                 WHERE date < ?1 AND date >= ?2 AND trimp_total IS NOT NULL",
            )?;
            let rows = statement.query_map(
                params![start.to_string(), (start - Duration::days(28)).to_string()],
                |row| Ok((row.get::<_, String>(0)?, row.get::<_, f64>(1)?)),
            )?;
            for row in rows {
                let (date, trimp) = row?;
                prior.trimp.insert(date, Some(trimp));
            }
        }
        Ok(prior)
    }

    fn window_stats(&self, start: NaiveDate, end: NaiveDate) -> Result<WindowStats> {
        let start_text = start.to_string();
        let end_text = end.to_string();
        let (workouts, distance, seconds) = self.conn.query_row(
            &format!(
                "SELECT COUNT(*), COALESCE(SUM(distance_meters), 0),
                        COALESCE(SUM(COALESCE(NULLIF(moving_seconds, 0),
                            CAST(ROUND((julianday(end_time) - julianday(start_time)) * 86400) AS INTEGER))), 0)
                 FROM workouts_visible
                 WHERE COALESCE(workout_type_override, workout_type) IN ({RUN_TYPES_SQL})
                   AND date(start_time, 'localtime') BETWEEN ?1 AND ?2"
            ),
            params![start_text, end_text],
            |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
        )?;

        let current_power = self
            .conn
            .query_row(
                "SELECT current_power FROM daily_performance
                 WHERE date BETWEEN ?1 AND ?2 AND current_power IS NOT NULL
                 ORDER BY date DESC LIMIT 1",
                params![start_text, end_text],
                |row| row.get(0),
            )
            .optional()?;

        let trimp_total: Option<f64> = self.conn.query_row(
            "SELECT SUM(trimp_total) FROM daily_performance
             WHERE date BETWEEN ?1 AND ?2 AND trimp_total IS NOT NULL",
            params![start_text, end_text],
            |row| row.get(0),
        )?;

        let (recovered, days_with_data): (i64, i64) = self.conn.query_row(
            "SELECT COALESCE(SUM(CASE WHEN fully_recovered = 1 THEN 1 ELSE 0 END), 0), COUNT(*)
             FROM daily_performance
             WHERE date BETWEEN ?1 AND ?2 AND fully_recovered IS NOT NULL",
            params![start_text, end_text],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )?;

        Ok(WindowStats {
            workouts,
            distance_m: distance,
            moving_seconds: seconds,
            current_power,
            trimp_total,
            recovery_ratio: (days_with_data > 0)
                .then(|| round1(recovered as f64 / days_with_data as f64 * 100.0)),
        })
    }
}

#[derive(Debug, Default)]
struct PriorPerformance {
    last_date: Option<NaiveDate>,
    state: crate::analytics::BanisterState,
    trimp: BTreeMap<String, Option<f64>>,
}

fn analytics_power_window() -> i64 {
    crate::analytics::CURRENT_POWER_WINDOW_DAYS as i64
}

fn current_power_for_day(history: &[(NaiveDate, f64)], day: NaiveDate) -> Option<f64> {
    let points: Vec<DatedPower> = history
        .iter()
        .filter(|(date, _)| *date <= day)
        .map(|(date, power)| DatedPower {
            days_ago: (day - *date).num_days() as f64,
            power: *power,
        })
        .collect();
    current_power(&points)
}

fn chronic_average(daily: &BTreeMap<String, Option<f64>>, day: NaiveDate) -> Option<f64> {
    let mut values = Vec::new();
    for offset in 1..=28 {
        let key = (day - Duration::days(offset)).to_string();
        if let Some(Some(value)) = daily.get(&key) {
            values.push(*value);
        }
    }
    (!values.is_empty()).then(|| values.iter().sum::<f64>() / values.len() as f64)
}

fn pace(moving_seconds: f64, distance_m: f64) -> Option<f64> {
    (distance_m > 0.0).then(|| round1(moving_seconds * 1000.0 / distance_m))
}

fn weekly_score(trimp_total: f64, window_days: i64) -> u32 {
    let weeks = (window_days as f64 / 7.0).max(1.0);
    (trimp_total / weeks * crate::analytics::TRIMP_DISPLAY_FACTOR)
        .round()
        .clamp(0.0, 1000.0) as u32
}

fn round1(value: f64) -> f64 {
    (value * 10.0).round() / 10.0
}
