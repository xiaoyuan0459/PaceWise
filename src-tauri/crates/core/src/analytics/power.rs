use super::*;

/// Daniels 跑力（VDOT）与阈值速度的近似对照：`(米/秒, 跑力)`。
///
/// 只用来把「满心率储备下的等效速度」映射到 0–100；中间线性插值，两端线性外推。
/// 这不是 Daniels 原表的逐点复刻，而是一条可解释、可校准的基准曲线。
const POWER_CURVE: [(f64, f64); 6] = [
    (2.67, 30.0),
    (3.33, 40.0),
    (3.92, 50.0),
    (4.48, 60.0),
    (5.02, 70.0),
    (5.56, 80.0),
];

#[derive(Debug, Clone, Copy)]
struct Segment {
    start: usize,
    end: usize,
}

#[derive(Debug, Clone, Copy)]
struct SegmentStats {
    duration_seconds: i64,
    mean_speed_mps: f64,
    mean_hr: f64,
    grade_pct: f64,
}

/// 计算一次训练的即时跑力。
///
/// `samples` 不要求有序，内部会按 `offset_seconds` 排序。没有任何稳定段时返回
/// `power = None`，但 `stable_seconds` 仍然反映实际找到的稳定时长。
pub fn instant_power(samples: &[TrainingSample], thresholds: AthleteThresholds) -> InstantPower {
    if samples.len() < 4 {
        return InstantPower::empty();
    }
    let mut ordered = samples.to_vec();
    ordered.sort_by_key(|sample| sample.offset_seconds);

    let mut stats: Vec<(Segment, SegmentStats)> = stable_segments(&ordered)
        .into_iter()
        .filter_map(|segment| segment_stats(&ordered, segment).map(|stats| (segment, stats)))
        .collect();
    // 长者优先：一次训练最多取三段，最长的那段最能代表这次的能力。
    stats.sort_by(|left, right| right.1.duration_seconds.cmp(&left.1.duration_seconds));

    let stable_seconds: i64 = stats.iter().map(|(_, stats)| stats.duration_seconds).sum();
    let confidence = Confidence::from_stable_seconds(stable_seconds);
    if stats.is_empty() {
        return InstantPower {
            stable_seconds,
            confidence,
            ..InstantPower::empty()
        };
    }

    let mut weight_sum = 0.0;
    let mut gap_pace_sum = 0.0;
    let mut efficiency_sum = 0.0;
    for (_, stats) in stats.iter().take(MAX_STABLE_SEGMENTS) {
        let Some(effort) = thresholds.effort(stats.mean_hr) else {
            continue;
        };
        if effort < 0.1 || stats.mean_speed_mps <= 0.0 {
            continue;
        }
        let pace = 1000.0 / stats.mean_speed_mps;
        let grade_up = stats.grade_pct.max(0.0);
        let grade_down = (-stats.grade_pct).max(0.0);
        let gap_pace = (pace - UPHILL_ADJUST_SEC_PER_KM_PER_PCT * grade_up
            + DOWNHILL_ADJUST_SEC_PER_KM_PER_PCT * grade_down)
            .clamp(120.0, 1200.0);
        let efficiency = 1000.0 / gap_pace / effort;
        if !efficiency.is_finite() || efficiency <= 0.0 {
            continue;
        }
        let weight = stats.duration_seconds as f64;
        weight_sum += weight;
        gap_pace_sum += gap_pace * weight;
        efficiency_sum += efficiency * weight;
    }

    if weight_sum <= 0.0 {
        return InstantPower {
            stable_seconds,
            confidence,
            ..InstantPower::empty()
        };
    }

    let gap_pace = gap_pace_sum / weight_sum;
    let efficiency = efficiency_sum / weight_sum;
    InstantPower {
        power: Some(power_from_speed(efficiency)),
        gap_pace_sec_km: Some(round1(gap_pace)),
        aerobic_efficiency: Some(round1(efficiency)),
        stable_seconds,
        confidence,
    }
}

/// 42 天指数加权的当前跑力。样本不足或覆盖太短时返回 `None`。
pub fn current_power(history: &[DatedPower]) -> Option<f64> {
    let valid: Vec<DatedPower> = history
        .iter()
        .copied()
        .filter(|point| {
            point.days_ago.is_finite()
                && (0.0..=CURRENT_POWER_WINDOW_DAYS).contains(&point.days_ago)
                && point.power.is_finite()
                && point.power > 0.0
        })
        .collect();
    if valid.len() < CURRENT_POWER_MIN_SESSIONS {
        return None;
    }
    let oldest = valid
        .iter()
        .map(|point| point.days_ago)
        .fold(f64::NEG_INFINITY, f64::max);
    let newest = valid
        .iter()
        .map(|point| point.days_ago)
        .fold(f64::INFINITY, f64::min);
    if oldest - newest < CURRENT_POWER_MIN_SPAN_DAYS {
        return None;
    }

    let mut weight_sum = 0.0;
    let mut power_sum = 0.0;
    for point in valid {
        let weight = (-point.days_ago / CURRENT_POWER_HALF_LIFE_DAYS).exp();
        weight_sum += weight;
        power_sum += point.power * weight;
    }
    (weight_sum > 0.0).then(|| round1(power_sum / weight_sum))
}

fn stable_segments(samples: &[TrainingSample]) -> Vec<Segment> {
    let mut accepted = Vec::new();
    if samples.len() < 4 {
        return accepted;
    }
    let mut start = 0;
    while start + 3 < samples.len() {
        let window_start = samples[start].offset_seconds;
        let mut end = start;
        while end + 1 < samples.len()
            && samples[end + 1].offset_seconds - window_start <= STABLE_WINDOW_SECONDS
        {
            end += 1;
        }
        let duration = samples[end].offset_seconds - window_start;
        if duration >= STABLE_WINDOW_SECONDS && is_stable(&samples[start..=end]) {
            accepted.push(Segment { start, end });
        }
        start += 1;
    }
    merge_overlapping(accepted)
}

fn merge_overlapping(segments: Vec<Segment>) -> Vec<Segment> {
    let mut merged: Vec<Segment> = Vec::new();
    for segment in segments {
        match merged.last_mut() {
            Some(last) if segment.start <= last.end + 1 => {
                last.end = last.end.max(segment.end);
            }
            _ => merged.push(segment),
        }
    }
    merged
}

fn is_stable(samples: &[TrainingSample]) -> bool {
    let Some(duration) = duration_seconds(samples) else {
        return false;
    };
    if duration < STABLE_WINDOW_SECONDS {
        return false;
    }

    let paces: Vec<f64> = samples
        .iter()
        .filter_map(|sample| sample.speed_mps)
        .filter(|speed| (MIN_SPEED_MPS..=MAX_SPEED_MPS).contains(speed))
        .map(|speed| 1000.0 / speed)
        .collect();
    let Some(pace_cv) = coefficient_of_variation(&paces) else {
        return false;
    };
    if pace_cv > PACE_CV_LIMIT {
        return false;
    }

    let heart_rates: Vec<f64> = samples
        .iter()
        .filter_map(|sample| sample.heart_rate)
        .filter(|heart_rate| heart_rate.is_finite() && *heart_rate > 0.0)
        .collect();
    let Some(hr_cv) = coefficient_of_variation(&heart_rates) else {
        return false;
    };
    if hr_cv > HR_CV_LIMIT {
        return false;
    }

    let Some(distance) = integrated_distance(samples) else {
        return false;
    };
    if distance < 50.0 {
        return false;
    }
    let mean_speed = distance / duration as f64;
    if !(MIN_SPEED_MPS..=MAX_SPEED_MPS).contains(&mean_speed) {
        return false;
    }

    let grade = grade_pct(samples, distance);
    grade.abs() <= MAX_ABS_GRADE_PCT
}

fn segment_stats(samples: &[TrainingSample], segment: Segment) -> Option<SegmentStats> {
    let slice = &samples[segment.start..=segment.end];
    let duration = duration_seconds(slice)?;
    if duration <= 0 {
        return None;
    }
    let distance = integrated_distance(slice)?;
    if distance < 50.0 {
        return None;
    }
    let mean_speed = distance / duration as f64;
    if !(MIN_SPEED_MPS..=MAX_SPEED_MPS).contains(&mean_speed) {
        return None;
    }
    let mean_hr = mean_heart_rate(slice)?;
    Some(SegmentStats {
        duration_seconds: duration,
        mean_speed_mps: mean_speed,
        mean_hr,
        grade_pct: grade_pct(slice, distance),
    })
}

fn duration_seconds(samples: &[TrainingSample]) -> Option<i64> {
    let first = samples.first()?.offset_seconds;
    let last = samples.last()?.offset_seconds;
    (last > first).then_some(last - first)
}

fn integrated_distance(samples: &[TrainingSample]) -> Option<f64> {
    let mut distance = 0.0;
    let mut covered = 0i64;
    for pair in samples.windows(2) {
        let (left, right) = (&pair[0], &pair[1]);
        let dt = right.offset_seconds - left.offset_seconds;
        if dt <= 0 {
            continue;
        }
        if let (Some(left_speed), Some(right_speed)) = (left.speed_mps, right.speed_mps) {
            if (MIN_SPEED_MPS..=MAX_SPEED_MPS).contains(&left_speed)
                && (MIN_SPEED_MPS..=MAX_SPEED_MPS).contains(&right_speed)
            {
                distance += (left_speed + right_speed) / 2.0 * dt as f64;
                covered += dt;
            }
        }
    }
    let duration = duration_seconds(samples)?;
    (covered as f64 >= duration as f64 * 0.8).then_some(distance)
}

fn mean_heart_rate(samples: &[TrainingSample]) -> Option<f64> {
    let mut weighted = 0.0;
    let mut covered = 0i64;
    for pair in samples.windows(2) {
        let (left, right) = (&pair[0], &pair[1]);
        let dt = right.offset_seconds - left.offset_seconds;
        if dt <= 0 {
            continue;
        }
        if let (Some(left_hr), Some(right_hr)) = (left.heart_rate, right.heart_rate) {
            if left_hr.is_finite() && right_hr.is_finite() && left_hr > 0.0 && right_hr > 0.0 {
                weighted += (left_hr + right_hr) / 2.0 * dt as f64;
                covered += dt;
            }
        }
    }
    let duration = duration_seconds(samples)?;
    if covered as f64 >= duration as f64 * 0.8 {
        Some(weighted / covered as f64)
    } else {
        let values: Vec<f64> = samples
            .iter()
            .filter_map(|sample| sample.heart_rate)
            .filter(|heart_rate| heart_rate.is_finite() && *heart_rate > 0.0)
            .collect();
        (!values.is_empty()).then(|| values.iter().sum::<f64>() / values.len() as f64)
    }
}

fn grade_pct(samples: &[TrainingSample], distance_m: f64) -> f64 {
    if distance_m <= 0.0 {
        return 0.0;
    }
    let first = samples.iter().find_map(|sample| sample.altitude_m);
    let last = samples.iter().rev().find_map(|sample| sample.altitude_m);
    match (first, last) {
        (Some(first), Some(last)) if first.is_finite() && last.is_finite() => {
            (last - first) / distance_m * 100.0
        }
        _ => 0.0,
    }
}

fn coefficient_of_variation(values: &[f64]) -> Option<f64> {
    if values.len() < 2 {
        return None;
    }
    let mean = values.iter().sum::<f64>() / values.len() as f64;
    if !mean.is_finite() || mean.abs() < f64::EPSILON {
        return None;
    }
    let variance = values
        .iter()
        .map(|value| (value - mean).powi(2))
        .sum::<f64>()
        / (values.len() - 1) as f64;
    Some(variance.sqrt() / mean)
}

fn power_from_speed(speed_mps: f64) -> f64 {
    let speed = speed_mps.clamp(0.0, 10.0);
    let first = POWER_CURVE[0];
    let last = POWER_CURVE[POWER_CURVE.len() - 1];
    if speed <= first.0 {
        let slope = (POWER_CURVE[1].1 - first.1) / (POWER_CURVE[1].0 - first.0);
        return round1((first.1 + (speed - first.0) * slope).clamp(0.0, 100.0));
    }
    if speed >= last.0 {
        let previous = POWER_CURVE[POWER_CURVE.len() - 2];
        let slope = (last.1 - previous.1) / (last.0 - previous.0);
        return round1((last.1 + (speed - last.0) * slope).clamp(0.0, 100.0));
    }
    for pair in POWER_CURVE.windows(2) {
        let (left, right) = (pair[0], pair[1]);
        if (left.0..=right.0).contains(&speed) {
            let ratio = (speed - left.0) / (right.0 - left.0);
            return round1(left.1 + ratio * (right.1 - left.1));
        }
    }
    round1(last.1)
}

fn round1(value: f64) -> f64 {
    (value * 10.0).round() / 10.0
}
