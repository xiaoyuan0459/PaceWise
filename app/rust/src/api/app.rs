//! Flutter 与 Rust 内核之间的窄接口。
//!
//! 只转发到 `zeppbridge_app::AppCore`，不在这里写业务逻辑。返回类型都是本文件
//! 定义的扁平 DTO，避免把内核依赖的类型直接暴露给 FRB 代码生成器。

use std::sync::OnceLock;

use anyhow::{anyhow, Result};
use zeppbridge_app::{
    AppCore, AuthPoll, AuthStart, AuthStatus, LoadDay, MetricSummary, RecoveryDay, TrendPoint,
};

static CORE: OnceLock<AppCore> = OnceLock::new();

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)]
pub fn open(data_dir: String) -> Result<AppInfo> {
    if let Some(core) = CORE.get() {
        return Ok(core.info().map_err(to_anyhow)?.into());
    }
    let core = AppCore::open(data_dir).map_err(to_anyhow)?;
    let info = core.info().map_err(to_anyhow)?.into();
    CORE.set(core)
        .map_err(|_| anyhow!("app already initialized"))?;
    Ok(info)
}

#[flutter_rust_bridge::frb(sync)]
pub fn info() -> Result<AppInfo> {
    Ok(core()?.info().map_err(to_anyhow)?.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn auth_start() -> Result<AuthStartDto> {
    Ok(core()?.auth_start().map_err(to_anyhow)?.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn auth_poll(state: String, claim_secret: String) -> Result<AuthPollDto> {
    let result = core()?.auth_poll(&state, &claim_secret);
    Ok(match result.map_err(to_anyhow)? {
        AuthPoll::Pending => AuthPollDto::status("pending"),
        AuthPoll::Ready { user_id, nickname } => AuthPollDto {
            status: "ready".into(),
            user_id: Some(user_id),
            nickname,
        },
        AuthPoll::Denied => AuthPollDto::status("denied"),
        AuthPoll::Expired => AuthPollDto::status("expired"),
        AuthPoll::Failed => AuthPollDto::status("failed"),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn auth_status() -> Result<AuthStatusDto> {
    Ok(core()?.auth_status().map_err(to_anyhow)?.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn auth_disconnect() -> Result<()> {
    core()?.auth_disconnect().map_err(to_anyhow)
}

/// 同步完成后或算法版本变化后调用。第一次会回填两年。
#[flutter_rust_bridge::frb(sync)]
pub fn recompute_analytics(window_days: i64) -> Result<i64> {
    Ok(core()?
        .recompute_analytics(window_days)
        .map_err(to_anyhow)? as i64)
}

#[flutter_rust_bridge::frb(sync)]
pub fn metric_summary(window_days: i64) -> Result<MetricSummaryDto> {
    Ok(core()?
        .metric_summary(window_days)
        .map_err(to_anyhow)?
        .into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn metric_trend(metric: String, window_days: i64) -> Result<Vec<TrendPointDto>> {
    Ok(core()?
        .metric_trend(&metric, window_days)
        .map_err(to_anyhow)?
        .into_iter()
        .map(TrendPointDto::from)
        .collect())
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_distribution(window_days: i64) -> Result<Vec<LoadDayDto>> {
    Ok(core()?
        .load_distribution(window_days)
        .map_err(to_anyhow)?
        .into_iter()
        .map(LoadDayDto::from)
        .collect())
}

#[flutter_rust_bridge::frb(sync)]
pub fn recovery_days(window_days: i64) -> Result<Vec<RecoveryDayDto>> {
    Ok(core()?
        .recovery_days(window_days)
        .map_err(to_anyhow)?
        .into_iter()
        .map(RecoveryDayDto::from)
        .collect())
}

fn core() -> Result<&'static AppCore> {
    CORE.get()
        .ok_or_else(|| anyhow!("app not initialized; call open(dataDir) first"))
}

fn to_anyhow(error: zeppbridge_app::AppError) -> anyhow::Error {
    anyhow!("{}: {}", error.code, error.message)
}

#[derive(Debug, Clone)]
pub struct AppInfo {
    pub data_dir: String,
    pub schema_version: i64,
    pub analytics_ready: bool,
}

impl From<zeppbridge_app::AppInfo> for AppInfo {
    fn from(value: zeppbridge_app::AppInfo) -> Self {
        Self {
            data_dir: value.data_dir,
            schema_version: value.schema_version,
            analytics_ready: value.analytics_ready,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthStartDto {
    pub url: String,
    pub state: String,
    pub claim_secret: String,
    pub expires_in_seconds: u64,
}

impl From<AuthStart> for AuthStartDto {
    fn from(value: AuthStart) -> Self {
        Self {
            url: value.url,
            state: value.state,
            claim_secret: value.claim_secret,
            expires_in_seconds: value.expires_in_seconds,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthPollDto {
    pub status: String,
    pub user_id: Option<String>,
    pub nickname: Option<String>,
}

impl AuthPollDto {
    fn status(status: &str) -> Self {
        Self {
            status: status.into(),
            user_id: None,
            nickname: None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct AuthStatusDto {
    pub authorized: bool,
    pub user_id: Option<String>,
    pub nickname: Option<String>,
    pub expires_at: Option<i64>,
    pub needs_reauth: bool,
}

impl From<AuthStatus> for AuthStatusDto {
    fn from(value: AuthStatus) -> Self {
        Self {
            authorized: value.authorized,
            user_id: value.user_id,
            nickname: value.nickname,
            expires_at: value.expires_at,
            needs_reauth: value.needs_reauth,
        }
    }
}

#[derive(Debug, Clone)]
pub struct MetricSummaryDto {
    pub window_days: i64,
    pub current_power: Option<f64>,
    pub previous_power: Option<f64>,
    pub distance_meters: f64,
    pub previous_distance_meters: f64,
    pub avg_pace_sec_per_km: Option<f64>,
    pub previous_avg_pace_sec_per_km: Option<f64>,
    pub training_load: Option<f64>,
    pub previous_training_load: Option<f64>,
    pub training_load_score: Option<u32>,
    pub previous_training_load_score: Option<u32>,
    pub recovery_ratio: Option<f64>,
    pub previous_recovery_ratio: Option<f64>,
    pub workouts: i64,
    pub previous_workouts: i64,
}

impl From<MetricSummary> for MetricSummaryDto {
    fn from(value: MetricSummary) -> Self {
        Self {
            window_days: value.window_days,
            current_power: value.current_power,
            previous_power: value.previous_power,
            distance_meters: value.distance_meters,
            previous_distance_meters: value.previous_distance_meters,
            avg_pace_sec_per_km: value.avg_pace_sec_per_km,
            previous_avg_pace_sec_per_km: value.previous_avg_pace_sec_per_km,
            training_load: value.training_load,
            previous_training_load: value.previous_training_load,
            training_load_score: value.training_load_score,
            previous_training_load_score: value.previous_training_load_score,
            recovery_ratio: value.recovery_ratio,
            previous_recovery_ratio: value.previous_recovery_ratio,
            workouts: value.workouts,
            previous_workouts: value.previous_workouts,
        }
    }
}

#[derive(Debug, Clone)]
pub struct TrendPointDto {
    pub date: String,
    pub value: f64,
}

impl From<TrendPoint> for TrendPointDto {
    fn from(value: TrendPoint) -> Self {
        Self {
            date: value.date,
            value: value.value,
        }
    }
}

#[derive(Debug, Clone)]
pub struct LoadDayDto {
    pub date: String,
    pub trimp: Option<f64>,
    pub display_load: Option<u32>,
}

impl From<LoadDay> for LoadDayDto {
    fn from(value: LoadDay) -> Self {
        Self {
            date: value.date,
            trimp: value.trimp,
            display_load: value.display_load,
        }
    }
}

#[derive(Debug, Clone)]
pub struct RecoveryDayDto {
    pub date: String,
    pub recovery_score: Option<i64>,
    pub fully_recovered: Option<bool>,
}

impl From<RecoveryDay> for RecoveryDayDto {
    fn from(value: RecoveryDay) -> Self {
        Self {
            date: value.date,
            recovery_score: value.recovery_score,
            fully_recovered: value.fully_recovered,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temp_dir() -> std::path::PathBuf {
        let path =
            std::env::temp_dir().join(format!("pacebridge-bridge-test-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&path);
        std::fs::create_dir_all(&path).unwrap();
        path
    }

    #[test]
    fn opens_an_empty_library_and_materializes_analytics() {
        let dir = temp_dir();
        let opened = open(dir.to_string_lossy().to_string()).unwrap();
        assert_eq!(opened.schema_version, 55);
        assert!(!opened.analytics_ready);

        let summary = metric_summary(30).unwrap();
        assert_eq!(summary.workouts, 0);
        assert_eq!(summary.distance_meters, 0.0);

        assert_eq!(recompute_analytics(30).unwrap(), 0);
        assert!(info().unwrap().analytics_ready);
        assert_eq!(load_distribution(30).unwrap().len(), 30);
        assert_eq!(recovery_days(30).unwrap().len(), 30);

        let _ = std::fs::remove_dir_all(&dir);
    }
}
