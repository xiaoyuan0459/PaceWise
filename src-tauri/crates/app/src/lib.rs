//! App 门面：Flutter（经 flutter_rust_bridge）只依赖这一层。
//!
//! 这里刻意保持窄：打开数据目录、官方授权、分析结果查询。业务 SQL、归一化、
//! 迁移都留在 `zeppbridge-core`，App 不复制任何一条规则。
//!
//! 现在还是纯 Rust API；接入 Flutter 后由 FRB 为这些类型生成 Dart 绑定，
//! 方法名和 DTO 字段保持不变。

use std::path::PathBuf;
use std::sync::Mutex;

use chrono::Utc;
use serde::Serialize;

use zeppbridge_core::models::error::ZeppBridgeError;
use zeppbridge_core::official::{
    current_generation, invalidate_pending_logins, AuthorizationRequest, ClaimOutcome,
    OfficialClient, OfficialStore,
};
use zeppbridge_core::storage::analytics::{LoadDay, MetricSummary, RecoveryDay, TrendPoint};
use zeppbridge_core::storage::{Database, CURRENT_SCHEMA_VERSION};

/// FFI 边界上的稳定错误。Dart 按 `code` 决定重试、重新授权还是去设置。
#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppError {
    pub code: String,
    pub message: String,
    pub retryable: bool,
}

impl From<ZeppBridgeError> for AppError {
    fn from(error: ZeppBridgeError) -> Self {
        Self {
            code: error.code().to_string(),
            message: error.user_message(),
            retryable: false,
        }
    }
}

impl From<std::io::Error> for AppError {
    fn from(error: std::io::Error) -> Self {
        Self {
            code: "err.io".into(),
            message: error.to_string(),
            retryable: false,
        }
    }
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AppInfo {
    pub data_dir: String,
    pub schema_version: i64,
    pub analytics_ready: bool,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthStart {
    pub url: String,
    pub state: String,
    pub claim_secret: String,
    pub expires_in_seconds: u64,
}

#[derive(Debug, Clone, Serialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum AuthPoll {
    Pending,
    Ready {
        user_id: String,
        nickname: Option<String>,
    },
    Denied,
    Expired,
    Failed,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthStatus {
    pub authorized: bool,
    pub user_id: Option<String>,
    pub nickname: Option<String>,
    pub expires_at: Option<i64>,
    pub needs_reauth: bool,
}

/// App 的唯一入口。生命周期内持有一个数据库连接和一个 tokio runtime。
pub struct AppCore {
    data_dir: PathBuf,
    db: Mutex<Database>,
    runtime: tokio::runtime::Runtime,
}

impl AppCore {
    pub fn open(data_dir: impl Into<PathBuf>) -> Result<Self, AppError> {
        let data_dir = data_dir.into();
        std::fs::create_dir_all(&data_dir)?;
        let db = Database::open_migrated(&data_dir.join("zepp.db"))?;
        let runtime = tokio::runtime::Builder::new_multi_thread()
            .enable_all()
            .build()?;
        Ok(Self {
            data_dir,
            db: Mutex::new(db),
            runtime,
        })
    }

    pub fn info(&self) -> Result<AppInfo, AppError> {
        let db = self.lock();
        Ok(AppInfo {
            data_dir: self.data_dir.to_string_lossy().to_string(),
            schema_version: CURRENT_SCHEMA_VERSION,
            analytics_ready: db.analytics_ready()?,
        })
    }

    /// 生成一次官方授权的浏览器地址。`claim_secret` 只留在本机，Dart 负责轮询。
    pub fn auth_start(&self) -> Result<AuthStart, AppError> {
        let request = AuthorizationRequest::new()?;
        Ok(AuthStart {
            url: request.start_url(),
            state: request.state.clone(),
            claim_secret: request.claim_secret().to_string(),
            expires_in_seconds: zeppbridge_core::official::AUTHORIZATION_WINDOW_SECONDS,
        })
    }

    pub fn auth_poll(&self, state: &str, claim_secret: &str) -> Result<AuthPoll, AppError> {
        let client = OfficialClient::new()?;
        match self
            .runtime
            .block_on(client.claim(state, claim_secret, Utc::now().timestamp()))?
        {
            ClaimOutcome::Pending => Ok(AuthPoll::Pending),
            ClaimOutcome::Denied => Ok(AuthPoll::Denied),
            ClaimOutcome::Expired => Ok(AuthPoll::Expired),
            ClaimOutcome::Failed => Ok(AuthPoll::Failed),
            ClaimOutcome::Ready(tokens) => {
                let nickname = self
                    .runtime
                    .block_on(client.profile(&tokens.access_token))
                    .ok()
                    .and_then(|profile| profile.nickname);
                let store = OfficialStore::new(&self.data_dir);
                let saved = store.save_login(
                    &tokens,
                    nickname.as_deref(),
                    Utc::now().timestamp(),
                    current_generation(),
                )?;
                if saved {
                    Ok(AuthPoll::Ready {
                        user_id: tokens.user_id,
                        nickname,
                    })
                } else {
                    Ok(AuthPoll::Expired)
                }
            }
        }
    }

    pub fn auth_status(&self) -> Result<AuthStatus, AppError> {
        let store = OfficialStore::new(&self.data_dir);
        let tokens = store.load()?;
        let meta = store.meta()?;
        let needs_reauth = meta.as_ref().is_some_and(|meta| meta.needs_reauth);
        let expires_at = tokens.as_ref().and_then(|tokens| tokens.expires_at);
        Ok(AuthStatus {
            authorized: tokens.is_some() && !needs_reauth,
            user_id: meta
                .as_ref()
                .map(|meta| meta.user_id.clone())
                .or_else(|| tokens.as_ref().map(|tokens| tokens.user_id.clone())),
            nickname: meta.and_then(|meta| meta.nickname),
            expires_at,
            needs_reauth,
        })
    }

    pub fn auth_disconnect(&self) -> Result<(), AppError> {
        let store = OfficialStore::new(&self.data_dir);
        store.disconnect()?;
        invalidate_pending_logins();
        Ok(())
    }

    /// 同步完成或算法版本变化后调用。第一次会回填两年。
    pub fn recompute_analytics(&self, window_days: i64) -> Result<usize, AppError> {
        Ok(self.lock().recompute_analytics(window_days)?)
    }

    pub fn metric_summary(&self, window_days: i64) -> Result<MetricSummary, AppError> {
        Ok(self.lock().metric_summary(window_days)?)
    }

    pub fn metric_trend(
        &self,
        metric: &str,
        window_days: i64,
    ) -> Result<Vec<TrendPoint>, AppError> {
        Ok(self.lock().metric_trend(metric, window_days)?)
    }

    pub fn load_distribution(&self, window_days: i64) -> Result<Vec<LoadDay>, AppError> {
        Ok(self.lock().load_distribution(window_days)?)
    }

    pub fn recovery_days(&self, window_days: i64) -> Result<Vec<RecoveryDay>, AppError> {
        Ok(self.lock().recovery_days(window_days)?)
    }

    fn lock(&self) -> std::sync::MutexGuard<'_, Database> {
        self.db
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
    }
}
