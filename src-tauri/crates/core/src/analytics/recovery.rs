use super::*;
use serde::Serialize;

/// 一天恢复判定需要的输入。缺失就是 `None`，不补 0。
#[derive(Debug, Clone, Copy, Default, PartialEq)]
pub struct RecoveryInput {
    pub sleep_minutes: Option<f64>,
    pub sleep_hrv: Option<f64>,
    pub hrv_baseline: Option<f64>,
    pub resting_hr: Option<f64>,
    pub rhr_baseline: Option<f64>,
    pub previous_day_trimp: Option<f64>,
    pub chronic_daily_trimp: Option<f64>,
}

/// 一个周期内的恢复占比。
#[derive(Debug, Clone, Copy, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RecoverySummary {
    pub fully_recovered_days: i64,
    pub days_with_data: i64,
    /// 0–100；没有一天有数据时为 `None`。
    pub ratio: Option<f64>,
}

/// 计算一天的恢复分。
///
/// 睡眠是硬前提：没有睡眠数据就不给分。HRV 或静息心率缺失时按可用分项归一化，
/// 并在结果里标 `partial`，让界面能显示「部分数据」。
pub fn recovery(input: RecoveryInput) -> RecoveryScore {
    let sleep_minutes = input
        .sleep_minutes
        .filter(|value| value.is_finite() && *value >= 0.0);
    let Some(sleep_minutes) = sleep_minutes else {
        return RecoveryScore {
            score: None,
            fully_recovered: None,
            partial: true,
            sleep_score: 0.0,
            hrv_score: None,
            rhr_score: None,
            load_adjustment: None,
        };
    };

    let sleep_score = (sleep_minutes / 420.0 * 40.0).clamp(0.0, 40.0);
    let hrv_score = match (input.sleep_hrv, input.hrv_baseline) {
        (Some(hrv), Some(baseline))
            if hrv.is_finite() && baseline.is_finite() && baseline > 0.0 =>
        {
            Some((hrv / baseline * 30.0).clamp(0.0, 30.0))
        }
        _ => None,
    };
    let rhr_score = match (input.resting_hr, input.rhr_baseline) {
        (Some(resting), Some(baseline))
            if resting.is_finite() && baseline.is_finite() && baseline > 0.0 =>
        {
            Some(((1.0 - (resting - baseline) / 10.0) * 20.0).clamp(0.0, 20.0))
        }
        _ => None,
    };
    let load_adjustment = match (input.previous_day_trimp, input.chronic_daily_trimp) {
        (Some(previous), Some(chronic))
            if previous.is_finite() && chronic.is_finite() && chronic > 0.0 =>
        {
            Some(if previous > chronic * 1.5 {
                -10.0
            } else {
                10.0
            })
        }
        _ => None,
    };

    let available_max = 40.0
        + hrv_score.map_or(0.0, |_| 30.0)
        + rhr_score.map_or(0.0, |_| 20.0)
        + load_adjustment.map_or(0.0, |_| 10.0);
    if available_max <= 0.0 {
        return RecoveryScore {
            score: None,
            fully_recovered: None,
            partial: true,
            sleep_score,
            hrv_score,
            rhr_score,
            load_adjustment,
        };
    }
    let raw = sleep_score
        + hrv_score.unwrap_or(0.0)
        + rhr_score.unwrap_or(0.0)
        + load_adjustment.unwrap_or(0.0);
    let score = if sleep_minutes < 60.0 {
        0
    } else {
        (raw / available_max * 100.0).round().clamp(0.0, 100.0) as u8
    };

    RecoveryScore {
        score: Some(score),
        fully_recovered: Some(score >= FULLY_RECOVERED_THRESHOLD),
        partial: hrv_score.is_none() || rhr_score.is_none(),
        sleep_score,
        hrv_score,
        rhr_score,
        load_adjustment,
    }
}

/// 周期恢复占比。`days` 里 `None` 表示那天没有可用数据，从分母里剔除。
pub fn recovery_summary(days: &[Option<bool>]) -> RecoverySummary {
    let days_with_data = days.iter().filter(|day| day.is_some()).count() as i64;
    let fully_recovered_days = days.iter().filter(|day| matches!(day, Some(true))).count() as i64;
    RecoverySummary {
        fully_recovered_days,
        days_with_data,
        ratio: (days_with_data > 0)
            .then(|| (fully_recovered_days as f64 / days_with_data as f64 * 100.0).round()),
    }
}
