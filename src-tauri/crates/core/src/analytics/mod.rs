//! 训练分析：跑力、训练负荷、恢复状态、体能/疲劳/状况。
//!
//! 这里只放**纯函数**：输入采样与阈值，输出数值。不读数据库、不发网络请求、不依赖
//! 时间。存储层负责取数、物化和回放；调用方负责把结果写进 `workout_analytics` /
//! `daily_performance`。
//!
//! 参数都可以从配置传入，默认值集中在本文件。算法是公开模型的组合（分段稳定性、
//! 坡度补偿、Daniels 跑力对照、Banister TRIMP 与脉冲响应），不冒充任何闭源商业
//! 算法的精确复刻。

mod load;
mod power;
mod recovery;

#[cfg(test)]
mod tests;

pub use load::*;
pub use power::*;
pub use recovery::*;

use serde::Serialize;

/// 当前跑力的滚动窗口。
pub const CURRENT_POWER_WINDOW_DAYS: f64 = 42.0;
/// 当前跑力的指数衰减半衰期：越近的即时跑力权重越高。
pub const CURRENT_POWER_HALF_LIFE_DAYS: f64 = 14.0;
/// 少于这么多次有效即时跑力，不给当前跑力。
pub const CURRENT_POWER_MIN_SESSIONS: usize = 3;
/// 有效即时跑力覆盖不到这么多天，不给当前跑力。
pub const CURRENT_POWER_MIN_SPAN_DAYS: f64 = 14.0;

/// 稳定段的最短时长（秒）。
pub const STABLE_WINDOW_SECONDS: i64 = 180;
/// 一次训练最多取几个稳定段参与加权。
pub const MAX_STABLE_SEGMENTS: usize = 3;
/// 配速变异系数上限。
pub const PACE_CV_LIMIT: f64 = 0.05;
/// 心率变异系数上限。
pub const HR_CV_LIMIT: f64 = 0.03;
/// 稳定段的平均坡度绝对值上限（百分比）。超过这个值不再当作平跑样本。
pub const MAX_ABS_GRADE_PCT: f64 = 12.0;

/// 上坡每 1% 每公里补偿的秒数。
pub const UPHILL_ADJUST_SEC_PER_KM_PER_PCT: f64 = 12.0;
/// 下坡每 1% 每公里补偿的秒数。
pub const DOWNHILL_ADJUST_SEC_PER_KM_PER_PCT: f64 = 8.0;

/// 低于这个速度的采样不参与跑力（走路、停表）。
pub const MIN_SPEED_MPS: f64 = 1.0;
/// 高于这个速度的采样不参与跑力（GPS 抖动、车辆）。
pub const MAX_SPEED_MPS: f64 = 8.0;

/// TRIMP 映射到界面 0–1000 的系数。
pub const TRIMP_DISPLAY_FACTOR: f64 = 4.0;
/// 恢复分达到多少算「充分恢复」。
pub const FULLY_RECOVERED_THRESHOLD: u8 = 60;
/// Banister 体能衰减时间常数（天）。
pub const FITNESS_TAU_DAYS: f64 = 45.0;
/// Banister 疲劳衰减时间常数（天）。
pub const FATIGUE_TAU_DAYS: f64 = 15.0;

/// 运动员的两个心率锚点。缺失时无法算跑力和 TRIMP。
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct AthleteThresholds {
    pub max_hr: f64,
    pub resting_hr: f64,
}

impl AthleteThresholds {
    /// 心率储备比例，clamp 到 0–1。心率锚点无效时返回 `None`。
    pub fn effort(&self, heart_rate: f64) -> Option<f64> {
        if !self.max_hr.is_finite()
            || !self.resting_hr.is_finite()
            || self.max_hr <= self.resting_hr
            || !heart_rate.is_finite()
        {
            return None;
        }
        Some(((heart_rate - self.resting_hr) / (self.max_hr - self.resting_hr)).clamp(0.0, 1.0))
    }
}

/// 一条用于分析的采样。时间用相对训练开始的秒数，避免时区与解析依赖。
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct TrainingSample {
    pub offset_seconds: i64,
    /// 米/秒。没有速度时给 `None`，不要用 0 代替。
    pub speed_mps: Option<f64>,
    pub heart_rate: Option<f64>,
    pub altitude_m: Option<f64>,
}

impl TrainingSample {
    pub fn new(offset_seconds: i64) -> Self {
        Self {
            offset_seconds,
            speed_mps: None,
            heart_rate: None,
            altitude_m: None,
        }
    }

    pub fn with_speed(mut self, speed_mps: f64) -> Self {
        self.speed_mps = Some(speed_mps);
        self
    }

    pub fn with_heart_rate(mut self, heart_rate: f64) -> Self {
        self.heart_rate = Some(heart_rate);
        self
    }

    pub fn with_altitude(mut self, altitude_m: f64) -> Self {
        self.altitude_m = Some(altitude_m);
        self
    }
}

/// 即时跑力的可信度。
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Confidence {
    High,
    Medium,
    Low,
}

impl Confidence {
    fn from_stable_seconds(seconds: i64) -> Self {
        if seconds >= 600 {
            Self::High
        } else if seconds >= STABLE_WINDOW_SECONDS {
            Self::Medium
        } else {
            Self::Low
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::High => "high",
            Self::Medium => "medium",
            Self::Low => "low",
        }
    }
}

/// 一次训练的即时跑力结果。算不出时 `power` 为 `None`，但稳定段信息仍然返回，
/// 让界面能解释「为什么没有」。
#[derive(Debug, Clone, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct InstantPower {
    pub power: Option<f64>,
    pub gap_pace_sec_km: Option<f64>,
    /// 满心率储备下的等效速度（米/秒）。
    pub aerobic_efficiency: Option<f64>,
    pub stable_seconds: i64,
    pub confidence: Confidence,
}

impl InstantPower {
    fn empty() -> Self {
        Self {
            power: None,
            gap_pace_sec_km: None,
            aerobic_efficiency: None,
            stable_seconds: 0,
            confidence: Confidence::Low,
        }
    }
}

/// 当前跑力的一次历史输入。`days_ago` 以当天为 0，向前递增。
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DatedPower {
    pub days_ago: f64,
    pub power: f64,
}

/// 一天的恢复结果。
#[derive(Debug, Clone, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RecoveryScore {
    pub score: Option<u8>,
    pub fully_recovered: Option<bool>,
    /// 缺 HRV 或静息心率时为 true；分数已经按可用分项归一化。
    pub partial: bool,
    pub sleep_score: f64,
    pub hrv_score: Option<f64>,
    pub rhr_score: Option<f64>,
    pub load_adjustment: Option<f64>,
}

/// Banister 脉冲响应状态。
#[derive(Debug, Clone, Copy, Default, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BanisterState {
    pub fitness: f64,
    pub fatigue: f64,
}

impl BanisterState {
    pub fn form(self) -> f64 {
        self.fitness - self.fatigue
    }

    pub fn advance(self, trimp: f64) -> Self {
        Self {
            fitness: self.fitness * (-1.0 / FITNESS_TAU_DAYS).exp() + trimp,
            fatigue: self.fatigue * (-1.0 / FATIGUE_TAU_DAYS).exp() + trimp,
        }
    }
}

/// 连续日负荷推进后的一个点。
#[derive(Debug, Clone, Copy, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FitnessPoint {
    pub fitness: f64,
    pub fatigue: f64,
    pub form: f64,
}
