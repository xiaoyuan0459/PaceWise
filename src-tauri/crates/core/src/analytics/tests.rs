use super::*;

fn thresholds() -> AthleteThresholds {
    AthleteThresholds {
        max_hr: 190.0,
        resting_hr: 60.0,
    }
}

/// 生成每 5 秒一个采样的一段跑。
fn run(
    duration_seconds: i64,
    speed_mps: f64,
    heart_rate: f64,
    grade_pct: f64,
) -> Vec<TrainingSample> {
    let mut samples = Vec::new();
    let mut distance = 0.0;
    for offset in (0..=duration_seconds).step_by(5) {
        let altitude = distance * grade_pct / 100.0;
        samples.push(
            TrainingSample::new(offset)
                .with_speed(speed_mps)
                .with_heart_rate(heart_rate)
                .with_altitude(altitude),
        );
        distance += speed_mps * 5.0;
    }
    samples
}

fn assert_close(actual: f64, expected: f64, tolerance: f64) {
    assert!(
        (actual - expected).abs() <= tolerance,
        "expected {expected} ± {tolerance}, got {actual}"
    );
}

#[test]
fn flat_run_gets_high_confidence_power() {
    let result = instant_power(&run(600, 3.0, 150.0, 0.0), thresholds());
    let power = result.power.expect("flat steady run should produce power");
    assert!((40.0..=80.0).contains(&power), "unexpected power {power}");
    assert_eq!(result.confidence, Confidence::High);
    assert!(result.stable_seconds >= 540);
    assert_close(result.gap_pace_sec_km.unwrap(), 333.3, 2.0);
}

#[test]
fn unstable_run_has_no_power() {
    let mut samples = Vec::new();
    for offset in (0..=600).step_by(5) {
        let fast = (offset / 5) % 2 == 0;
        samples.push(
            TrainingSample::new(offset)
                .with_speed(if fast { 4.5 } else { 2.0 })
                .with_heart_rate(if fast { 175.0 } else { 130.0 }),
        );
    }
    let result = instant_power(&samples, thresholds());
    assert!(result.power.is_none());
    assert_eq!(result.stable_seconds, 0);
    assert_eq!(result.confidence, Confidence::Low);
}

#[test]
fn uphill_adjustment_raises_power() {
    let flat = instant_power(&run(600, 3.0, 150.0, 0.0), thresholds());
    let uphill = instant_power(&run(600, 3.0, 150.0, 4.0), thresholds());
    let flat_power = flat.power.expect("flat power");
    let uphill_power = uphill.power.expect("uphill power");
    assert!(
        uphill_power > flat_power,
        "uphill {uphill_power} should beat flat {flat_power}"
    );
    assert!(uphill.gap_pace_sec_km.unwrap() < flat.gap_pace_sec_km.unwrap());
}

#[test]
fn current_power_weights_recent_more() {
    let history = [
        DatedPower {
            days_ago: 30.0,
            power: 40.0,
        },
        DatedPower {
            days_ago: 7.0,
            power: 55.0,
        },
        DatedPower {
            days_ago: 1.0,
            power: 60.0,
        },
    ];
    let power = current_power(&history).expect("three sessions over 29 days");
    assert!(power > 55.0, "recent sessions should dominate: {power}");
    assert!(power < 60.0);
}

#[test]
fn current_power_needs_three_sessions_and_two_weeks() {
    assert!(current_power(&[
        DatedPower {
            days_ago: 1.0,
            power: 50.0,
        },
        DatedPower {
            days_ago: 3.0,
            power: 52.0,
        },
    ])
    .is_none());

    let same_week = [
        DatedPower {
            days_ago: 0.0,
            power: 50.0,
        },
        DatedPower {
            days_ago: 2.0,
            power: 51.0,
        },
        DatedPower {
            days_ago: 5.0,
            power: 52.0,
        },
    ];
    assert!(current_power(&same_week).is_none());
}

#[test]
fn trimp_integrates_samples() {
    let samples = run(3600, 3.0, 150.0, 0.0);
    let value = trimp(3600, Some(150.0), &samples, thresholds()).expect("trimp");
    assert!((90.0..=115.0).contains(&value), "unexpected trimp {value}");
    assert!((360..=460).contains(&display_load(value)));
}

#[test]
fn trimp_falls_back_to_average_heart_rate() {
    let value = trimp(3600, Some(150.0), &[], thresholds()).expect("fallback trimp");
    assert!((90.0..=115.0).contains(&value));
}

#[test]
fn trimp_rejects_invalid_thresholds() {
    let invalid = AthleteThresholds {
        max_hr: 150.0,
        resting_hr: 150.0,
    };
    assert!(trimp(600, Some(140.0), &[], invalid).is_none());
}

#[test]
fn recovery_full_score_is_one_hundred() {
    let score = recovery(RecoveryInput {
        sleep_minutes: Some(420.0),
        sleep_hrv: Some(60.0),
        hrv_baseline: Some(60.0),
        resting_hr: Some(50.0),
        rhr_baseline: Some(50.0),
        previous_day_trimp: Some(80.0),
        chronic_daily_trimp: Some(100.0),
    });
    assert_eq!(score.score, Some(100));
    assert_eq!(score.fully_recovered, Some(true));
    assert!(!score.partial);
}

#[test]
fn recovery_penalizes_high_previous_load() {
    let score = recovery(RecoveryInput {
        sleep_minutes: Some(420.0),
        sleep_hrv: Some(60.0),
        hrv_baseline: Some(60.0),
        resting_hr: Some(50.0),
        rhr_baseline: Some(50.0),
        previous_day_trimp: Some(200.0),
        chronic_daily_trimp: Some(100.0),
    });
    assert_eq!(score.score, Some(80));
    assert_eq!(score.load_adjustment, Some(-10.0));
}

#[test]
fn recovery_without_hrv_renormalizes_and_marks_partial() {
    let score = recovery(RecoveryInput {
        sleep_minutes: Some(420.0),
        sleep_hrv: None,
        hrv_baseline: None,
        resting_hr: Some(50.0),
        rhr_baseline: Some(50.0),
        previous_day_trimp: Some(80.0),
        chronic_daily_trimp: Some(100.0),
    });
    assert_eq!(score.score, Some(100));
    assert!(score.partial);
    assert!(score.hrv_score.is_none());
}

#[test]
fn recovery_requires_sleep() {
    let score = recovery(RecoveryInput {
        sleep_minutes: None,
        sleep_hrv: Some(60.0),
        hrv_baseline: Some(60.0),
        ..RecoveryInput::default()
    });
    assert_eq!(score.score, None);
    assert_eq!(score.fully_recovered, None);
}

#[test]
fn recovery_summary_ignores_missing_days() {
    let summary = recovery_summary(&[Some(true), Some(false), None, Some(true)]);
    assert_eq!(summary.fully_recovered_days, 2);
    assert_eq!(summary.days_with_data, 3);
    assert_eq!(summary.ratio, Some(67.0));
}

#[test]
fn fitness_fatigue_decay_and_form() {
    let series = fitness_series(&[100.0; 10]);
    let last = series.last().expect("ten days");
    assert!(last.fitness > 0.0);
    assert!(last.fatigue > 0.0);
    assert!(last.fitness > last.fatigue);
    assert_close(last.form, last.fitness - last.fatigue, 1e-9);

    let rested = BanisterState {
        fitness: last.fitness,
        fatigue: last.fatigue,
    }
    .advance(0.0);
    assert!(rested.fitness < last.fitness);
    assert!(rested.fatigue < last.fatigue);
    assert!(rested.form() > last.form);
}
