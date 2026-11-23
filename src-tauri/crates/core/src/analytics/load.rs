use super::*;

/// Banister TRIMP：训练时长 × 心率储备 × 指数强度权重。
///
/// 有心率采样时按采样积分；采样覆盖不足时退回「平均心率 × 时长」。两条路都拿不到
/// 有效心率时返回 `None`，不补 0。
pub fn trimp(
    duration_seconds: i64,
    avg_hr: Option<f64>,
    samples: &[TrainingSample],
    thresholds: AthleteThresholds,
) -> Option<f64> {
    if duration_seconds <= 0 {
        return None;
    }
    let duration_f = duration_seconds as f64;

    let mut ordered = samples.to_vec();
    ordered.sort_by_key(|sample| sample.offset_seconds);

    let mut integrated = 0.0;
    let mut covered_seconds = 0i64;
    for pair in ordered.windows(2) {
        let (left, right) = (&pair[0], &pair[1]);
        let dt = right.offset_seconds - left.offset_seconds;
        if dt <= 0 {
            continue;
        }
        let (Some(left_hr), Some(right_hr)) = (left.heart_rate, right.heart_rate) else {
            continue;
        };
        let Some(effort) = thresholds.effort((left_hr + right_hr) / 2.0) else {
            continue;
        };
        integrated += dt as f64 / 60.0 * effort * 0.64 * (1.92 * effort).exp();
        covered_seconds += dt;
    }

    if covered_seconds as f64 >= duration_f * 0.5 && integrated > 0.0 {
        return Some(round2(integrated));
    }

    let effort = thresholds.effort(avg_hr?)?;
    let value = duration_f / 60.0 * effort * 0.64 * (1.92 * effort).exp();
    (value > 0.0).then(|| round2(value))
}

/// 界面展示的训练负荷：0–1000 的整数。
pub fn display_load(trimp: f64) -> u32 {
    (trimp.max(0.0) * TRIMP_DISPLAY_FACTOR).round() as u32
}

/// 按天推进 Banister 的体能 / 疲劳 / 状况。
///
/// `daily_trimp` 必须是连续自然日，缺失的日子用 0 表示——不能跳日，否则衰减
/// 次数就不对了。
pub fn fitness_series(daily_trimp: &[f64]) -> Vec<FitnessPoint> {
    let mut state = BanisterState::default();
    daily_trimp
        .iter()
        .map(|trimp| {
            state = state.advance((*trimp).max(0.0));
            FitnessPoint {
                fitness: state.fitness,
                fatigue: state.fatigue,
                form: state.form(),
            }
        })
        .collect()
}

fn round2(value: f64) -> f64 {
    (value * 100.0).round() / 100.0
}
