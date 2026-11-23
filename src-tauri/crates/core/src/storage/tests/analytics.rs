use super::*;

use chrono::{Duration as ChronoDuration, Local, TimeZone};

fn local_start(days_ago: i64) -> DateTime<Utc> {
    let date = Local::now().date_naive() - ChronoDuration::days(days_ago);
    Local
        .from_local_datetime(&date.and_hms_opt(8, 0, 0).expect("valid time"))
        .single()
        .expect("unambiguous local time")
        .with_timezone(&Utc)
}

fn insert_run(db: &Database, workout_id: &str, days_ago: i64, with_hr: bool) {
    let start = local_start(days_ago);
    let end = start + ChronoDuration::seconds(600);
    db.insert_workout(&Workout {
        workout_id: workout_id.into(),
        workout_type: "run".into(),
        normalized_type: "run".into(),
        type_source: "string_field".into(),
        effective_type: "run".into(),
        start_time: start,
        end_time: end,
        distance_meters: Some(1800.0),
        avg_hr: with_hr.then_some(150),
        max_hr: with_hr.then_some(190),
        moving_seconds: Some(600),
        source_scope: SourceScope::Device,
        sample_count: 121,
        ..Default::default()
    })
    .unwrap();

    for offset in (0..=600).step_by(5) {
        db.conn
            .execute(
                "INSERT INTO workout_samples(workout_id, timestamp, heart_rate, speed, altitude)
                 VALUES(?1, ?2, ?3, ?4, ?5)",
                params![
                    workout_id,
                    (start + ChronoDuration::seconds(offset)).to_rfc3339(),
                    with_hr.then_some(150.0),
                    3.0,
                    0.0
                ],
            )
            .unwrap();
    }
}

fn seed_daily_context(db: &Database) {
    let today = Local::now().date_naive();
    for days_ago in 0..30 {
        let date = (today - ChronoDuration::days(days_ago)).to_string();
        for (metric, unit, value) in [
            ("sleep_hrv", "ms", 60.0),
            ("hrv_baseline", "ms", 60.0),
            ("resting_hr", "bpm", 55.0),
            ("rhr_baseline", "bpm", 55.0),
        ] {
            db.conn
                .execute(
                    "INSERT INTO daily_metrics(date, metric, value, unit, source_scope)
                     VALUES(?1, ?2, ?3, ?4, 'device')",
                    params![date, metric, value, unit],
                )
                .unwrap();
        }
        let end = local_start(days_ago) + ChronoDuration::hours(-1);
        db.conn
            .execute(
                "INSERT INTO sleep_sessions
                    (sleep_id, start_time, end_time, score, duration_minutes, deep_minutes,
                     light_minutes, rem_minutes, awake_minutes, source_scope)
                 VALUES(?1, ?2, ?3, 80, 420, 90, 240, 70, 20, 'device')",
                params![
                    format!("sleep-{days_ago}"),
                    (end - ChronoDuration::minutes(420)).to_rfc3339(),
                    end.to_rfc3339()
                ],
            )
            .unwrap();
    }
}

#[test]
fn recompute_materializes_workout_and_daily_analytics() {
    let db = Database::in_memory().unwrap();
    seed_daily_context(&db);
    for (index, days_ago) in [1, 7, 14, 21].into_iter().enumerate() {
        insert_run(&db, &format!("run-{index}"), days_ago, true);
    }

    let analysed = db.recompute_analytics(30).unwrap();
    assert_eq!(analysed, 4);
    assert!(db.analytics_ready().unwrap());

    let workout_rows: i64 = db
        .conn
        .query_row("SELECT COUNT(*) FROM workout_analytics", [], |row| {
            row.get(0)
        })
        .unwrap();
    assert_eq!(workout_rows, 4);

    let summary = db.metric_summary(30).unwrap();
    assert_eq!(summary.workouts, 4);
    assert!((summary.distance_meters - 7200.0).abs() < 0.1);
    assert!(
        summary.current_power.is_some(),
        "four stable runs over 21 days"
    );
    assert!(summary.training_load.is_some());
    assert_eq!(summary.recovery_ratio, Some(100.0));
    assert!((summary.avg_pace_sec_per_km.unwrap() - 333.3).abs() < 1.0);

    let power = db.metric_trend("power", 30).unwrap();
    assert!(!power.is_empty());
    let distance = db.metric_trend("distance", 30).unwrap();
    assert_eq!(distance.len(), 4);
    let pace = db.metric_trend("pace", 30).unwrap();
    assert_eq!(pace.len(), 4);
    assert!((pace[0].value - 333.3).abs() < 1.0);

    assert_eq!(db.load_distribution(30).unwrap().len(), 30);
    assert_eq!(db.recovery_days(30).unwrap().len(), 30);
}

#[test]
fn missing_heart_rate_leaves_power_and_load_empty() {
    let db = Database::in_memory().unwrap();
    seed_daily_context(&db);
    insert_run(&db, "no-hr", 1, false);

    db.recompute_analytics(30).unwrap();
    let summary = db.metric_summary(30).unwrap();
    assert!(summary.current_power.is_none());
    assert!(summary.recovery_ratio.is_some());

    let power: Option<f64> = db
        .conn
        .query_row(
            "SELECT instant_power FROM workout_analytics WHERE workout_id = 'no-hr'",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert!(power.is_none());

    let day = (Local::now().date_naive() - ChronoDuration::days(1)).to_string();
    let trimp: Option<f64> = db
        .conn
        .query_row(
            "SELECT trimp_total FROM daily_performance WHERE date = ?1",
            [day],
            |row| row.get(0),
        )
        .unwrap();
    assert!(
        trimp.is_none(),
        "a workout without HR has no load for that day"
    );
}
