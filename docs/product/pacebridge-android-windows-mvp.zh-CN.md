# 智跑 AI（PaceBridge）Android + Windows MVP 产品与技术方案

> 状态：草案 v0.1 · 2026-11-23  
> 范围：Android 10+、Windows 10+；**本期不做 iOS**  
> 数据来源：ZeppBridge Rust 内核已同步的 Zepp / Amazfit 数据  
> 命名：产品名暂用「智跑 AI」，仓库工作名 PaceBridge；内核 crate、凭据服务名、官方 OAuth 回调域名继续使用 `ZeppBridge`，避免影响官方接口。

---

## 0. 一页结论

| 决策项 | 结论 |
|---|---|
| 平台 | Android 10+（API 29）、Windows 10+ x64；iOS 留到后续版本 |
| UI 技术 | Flutter 3.x + Dart 3，Material 3；设计语言参考 FlClash，不复制其代码与素材 |
| 状态管理 | Riverpod 3 |
| 图表 / 地图 | `fl_chart` / `flutter_map`（只读轨迹） |
| 内核接入 | `flutter_rust_bridge` v2，同进程 FFI，直接调用 `zeppbridge-core` |
| 数据源 | 只用内核已经同步的数据；**删除多品牌设备直连与品牌适配** |
| AI | P0 只生成「AI 任务包」，用户复制或分享给任意 AI；不内置对话 |
| 本地存储 | 内核 SQLite（WAL）；UI 只读派生表，不读原始报文 |
| 分析 | 跑力、训练负荷、恢复状态、体能/疲劳/状况指数全部在内核离线计算并物化 |
| 报告 | P1；P0 只做概览、对比、赛事计划、设置 |
| 隐私 | 数据只在本机；不上传原始健康数据；无后台采集、无第三方统计 SDK |

---

## 1. 范围与边界

### 1.1 产品定位

**把 Zepp / Amazfit 上已经产生的训练和身体数据，变成一份打开就能看懂、能问 AI 的个人训练面板。**

核心价值：

- 数据价值：30 / 90 / 180 天多周期对比，直观看懂进步；
- 分析价值：跑力、训练负荷、恢复状态用公开的运动科学模型计算，不直接搬运手表结论；
- 赛事价值：手动维护赛事目标，训练数据与赛事进度关联；
- 智能价值：把结构化数据打包交给 AI，由用户选择模型；
- 隐私价值：纯本地、前台同步、不上传原始健康数据。

### 1.2 目标用户

| 用户 | 特征 | 本期对应能力 |
|---|---|---|
| 新手跑者 | 跑步 < 3 个月，关注安全和隐私 | 概览三个核心指标、赛事极简表单、AI 任务包 |
| 进阶跑者 | 3–12 个月，有中高端手表 | 多周期对比、恢复状态、赛事进度 |
| 严肃跑者 | > 12 个月，追求 PB | 全量指标趋势、赛事复盘、数据导出 |

### 1.3 与上传版 PRD 的差异（重要）

上传版 PRD 的 3.6 节描述的是「多品牌设备同步」；本期明确改为**只消费 ZeppBridge 内核已经同步的 Zepp / Amazfit 数据**。

| PRD 条目 | 本期处理 | 原因 |
|---|---|---|
| 3.6.2 F0501 绑定佳明/高驰/松拓/华为/苹果/小米 | **删除** | 不做多品牌设备直连；数据由内核从 Zepp 官方接口同步 |
| 3.6.2 F0502 设备增量同步、断点续传 | **保留能力，但由内核负责**；App 只提供「连接 / 立即同步 / 查看状态」 | 同步、续传、账本已经在内核实现 |
| 3.6.2 F0503 多品牌单位与异常数据校准 | **删除**；内核归一化已经统一为米、秒、米/秒 | 不再有第二套品牌口径 |
| 3.6.2 F0504 手动录入训练 | P1 | 本期先把已有数据看明白 |
| 3.6.3 设备授权过期 | 保留；改为「Zepp 授权过期，重新授权」 | 只有一条授权链路 |
| 3.3.2 F0205 AI 智能解读（200ms 内生成） | P0 改为「本地规则摘要 + 生成 AI 任务包」；内置 AI 解读 P1 | P0 已确定不内置模型 |
| 3.4 报告子标签 | P1 | PRD 本身把 R05 定为 P1；P0 只有概览、对比、赛事、设置 |
| 3.4.2 F0302 PDF / Excel 导出 | P1；P0 支持 JSON / CSV | 内核已有 JSON / CSV 导出 |
| 4.4 云端存储、端到端加密、服务端备份 | **删除** | 纯本地产品，没有云端账号体系 |
| 4.2 iOS 14+ | **本期不做** | 先做 Android + Windows |
| 6.2 固定橙色 / 蓝色 / 深色色板 | 改为 Material 3 动态配色，品牌橙作为 seed | 参考 FlClash 的设计语言 |
| 6.2.2 Din Pro | 不引入商业字体；用系统字体 + 等宽数字 | 授权成本与跨平台一致性 |

### 1.4 本期不做清单

- iOS、macOS、Linux；
- 多品牌手表直连与品牌适配；
- GPS 跑步记录、手机传感器采集；
- 社交、排行榜、跑团、教练入驻；
- 训练计划发布到手表；
- GPX / FIT / Strava / Apple 健康导入；
- 多账号、云同步、端到端加密、服务端备份；
- 后台常驻同步、推送通知；
- 内置 AI 对话、内置模型 API Key 管理。

---

## 2. 技术方案

### 2.1 总体架构

```text
┌────────────────────────────────────────────────────┐
│ Flutter App（Dart）                                 │
│  Material 3 · Riverpod · go_router · fl_chart       │
│  flutter_map · flutter_secure_storage               │
│  页面只消费 DTO，不拼 SQL、不算指标                  │
└───────────────────────┬────────────────────────────┘
                        │ flutter_rust_bridge v2（同进程 FFI）
┌───────────────────────▼────────────────────────────┐
│ zeppbridge-core（Rust）                             │
│  official OAuth / sync / normalizer / SQLite        │
│  analytics（跑力 / TRIMP / Banister）               │
│  query facade（today / workouts / trends / races）  │
│  CLI 与 MCP 保持独立，不受 App 影响                  │
└────────────────────────────────────────────────────┘
```

没有 Tauri，没有本地 HTTP 服务，没有前端构建链。Rust 内核以库的形式编进 App。

### 2.2 选型表

| 层 | 选择 | 说明 |
|---|---|---|
| UI | Flutter 3.x + Dart 3 | Android / Windows 一套代码 |
| 设计体系 | Material 3 + `dynamic_color` | Android 动态取色；Windows 用品牌 seed |
| 状态 | `flutter_riverpod` 3 | 与 FlClash 同代；跨页缓存同步状态与筛选条件 |
| 路由 | `go_router` | 手机页面栈与桌面主从共用一套路由 |
| 图表 | `fl_chart` | 折线、柱状、堆叠柱、环形；P0 不做复杂 3D |
| 地图 | `flutter_map` | 只画已存轨迹，不申请定位权限 |
| 字体 | 系统字体 + `JetBrains Mono`（OFL） | 数值使用 tabular figures，避免跳动 |
| FFI | `flutter_rust_bridge` v2 | 自动生成 Dart 绑定，支持 async 与 Stream |
| 本地配置 | `shared_preferences` | 只存主题、语言、上次窗口等 UI 偏好 |
| 安全存储 | `flutter_secure_storage` | Android Keystore；Windows 优先用内核凭据管理器 |
| 日志 | 本地文件 + 用户可导出 / 清除 | 不接第三方统计 SDK |

### 2.3 仓库目录

```text
/app                              # 新增：Flutter 工程（Android + Windows）
  lib/
    main.dart
    app/                          # 应用壳、主题、路由、本地化
    features/overview/            # 概览
    features/compare/             # 数据对比
    features/races/               # 赛事计划
    features/settings/            # 设置与隐私
    features/workouts/            # 训练列表与详情
    data/                         # FRB 生成的绑定与 DTO 适配
  android/  windows/  test/
/src-tauri                        # 保留目录名，避免现在改 CI 与文档
  crates/core                     # 现有内核
  crates/cli  crates/mcp          # 现有入口
  crates/app-ffi                  # 新增：FRB 桥接层（cdylib + staticlib）
```

`src-tauri` 这个名字已经和 Tauri 无关，但为了减少一次性改动，本期保留；等产品稳定后再统一改成 `rust/`。

### 2.4 Rust 内核接入

#### 2.4.1 FFI 桥接层

新增 `crates/app-ffi`：

- 依赖 `zeppbridge-core` 与 `flutter_rust_bridge`；
- 输出 `cdylib`（Android）和 `staticlib`（Windows）；
- 内部持有一个多线程 `tokio::runtime::Runtime`，同步任务全部在这里跑；
- 持有 `Database` 与 `SyncManager`，用 `Mutex` / 单写者 actor 串行化写操作；
- 暴露给 Dart 的 API 见附录 A。

不在 UI 线程做 SQL、网络或解析。

#### 2.4.2 数据目录

内核已经支持显式路径：`Database::open_migrated(path)`、`SyncManager::with_data_dir(dir)`。App 启动时：

| 平台 | 数据目录 |
|---|---|
| Android | `getApplicationSupportDirectory()/data`（应用沙盒） |
| Windows | `%LOCALAPPDATA%\ZeppBridge\data`（不漫游，避免大库进 Roaming） |
| 开发 | `ZEPPBRIDGE_DATA_DIR` 覆盖 |

首次启动若目录里没有 `zepp.db`，进入引导页：连接 Zepp → 选择同步 30 / 90 / 180 天。

#### 2.4.3 凭据

| 平台 | 方案 |
|---|---|
| Windows | 复用内核现有的 Credential Manager 后端（`com.zeppbridge.app`） |
| Android | Dart 侧用 `flutter_secure_storage` 保存令牌；Rust 侧使用内存凭据后端，启动时由 Dart 注入，刷新后把新令牌回传 Dart 持久化 |

约束：

- 令牌不写日志、不进 `auth.json`、不出现在错误信息里；
- Android 的 Keystore 条目不可用时，引导用户重新授权，不静默降级成明文文件；
- Windows 保持现有 `CREDENTIAL_MAX_UTF16_UNITS` 校验。

#### 2.4.4 OAuth

完全复用内核的「中转站 + claim」流程：

1. Rust 生成 `AuthorizationRequest`（`state` + `claim_secret`），返回 `start_url`；
2. Flutter 用 `url_launcher` 打开系统浏览器；
3. Flutter 每 1–2 秒调用一次 `claim(state, claim_secret)`；
4. `Ready` → 保存令牌；`Pending` → 继续；`Expired` / `Denied` → 提示重新授权；
5. App 切后台时暂停轮询，回前台继续；超过中转站有效期则重新开始。

不依赖本机端口，不依赖自定义 scheme，移动端和桌面端同一条链路。

#### 2.4.5 网络与 TLS

- 当前 workspace 的 `reqwest` 使用默认 `native-tls`；Android 上会走 OpenSSL，交叉编译成本高。
- 改为 `default-features = false, features = ["json", "cookies", "gzip", "rustls-tls"]`，桌面与移动统一 rustls。
- 代理、证书校验沿用内核现有行为，不在 App 层另建 HTTP 客户端。

#### 2.4.6 错误契约

FRB 边界统一返回：

```text
AppError {
  code: string,          // 稳定错误码，例如 auth.expired / sync.network / db.busy
  message: string,       // 已本地化或可映射的短句
  retryable: bool,
  detail: string | null  // 仅日志，不直接展示
}
```

Dart 侧按 `code` 决定「重试 / 重新授权 / 去设置」，不解析中文错误串。

### 2.5 平台差异

| 能力 | Android | Windows |
|---|---|---|
| 系统要求 | Android 10（API 29）及以上 | Windows 10 1809 及以上，x64 |
| 安装包 | APK（内测）/ AAB（上架） | Inno Setup 安装包；商店再考虑 MSIX |
| 窗口 | 全屏，处理刘海与手势条 | 最小 1024×720，可缩放；P0 用系统标题栏 |
| 动态取色 | 开启（Android 12+） | 关闭，使用品牌 seed |
| 返回手势 | 支持系统返回 | 键盘 Esc / Alt+← 返回 |
| 文件导出 | 系统分享面板 + 文件选择器 | 保存对话框 |
| 后台 | 无后台同步；离开页面即暂停轮询 | 关闭窗口即退出；P1 再考虑托盘 |
| 凭据 | `flutter_secure_storage` | Credential Manager |

### 2.6 构建与 CI

| 作业 | 内容 |
|---|---|
| Rust 门禁 | 现有 `fmt`、`clippy`、`test` 不变；新增 `crates/app-ffi` 后仍跑 workspace |
| Flutter 门禁 | `flutter analyze`、`flutter test`、`dart format --set-exit-if-changed` |
| FRB 一致性 | 重新生成绑定后 `git diff --exit-code`，防止手改生成代码 |
| Android 构建 | Ubuntu runner + Android SDK/NDK + `cargo-ndk`，产出 APK |
| Windows 构建 | Windows runner + MSVC，产出可执行目录与安装包 |
| 版本一致性 | `package.json`、Rust crate、Flutter `pubspec.yaml` 三处版本一致 |

---

## 3. 数据与分析

### 3.1 数据流

```text
Zepp 官方接口
   └─ 内核同步 → raw_records（压缩原始报文）
        └─ 归一化 → workouts / sleep_sessions / metric_samples / daily_metrics
             └─ 分析（新增）→ workout_analytics / daily_performance
                  └─ App 查询面 → Flutter 页面
```

App **不读** `raw_records`，也**不读**逐秒采样；训练详情只读内核降采样后的序列。

### 3.2 五个核心指标

| 指标 | 定义 | 输入 | 输出 |
|---|---|---|---|
| 跑力值 | 当前稳定实力，0–100，1 位小数 | 稳定段的配速、心率、坡度；运动员最大/静息心率 | 即时跑力（逐次）+ 当前跑力（42 天） |
| 累计跑量 | 周期内跑步距离总和，km | `workouts.distance_meters` | 1 位小数 |
| 平均配速 | 周期内总移动时间 ÷ 总距离 | `moving_seconds`、`distance_meters` | `分:秒/km` |
| 训练负荷 | 周期内 TRIMP 总和，映射到 0–1000 | 心率采样、运动时长、最大/静息心率 | 整数 + 轻松/适中/困难分布 |
| 恢复状态 | 周期内「充分恢复」天数占比 | 睡眠时长、睡眠 HRV、静息心率、前一日负荷 | 0–100% |

只统计跑步类型：`run`、`trail_running`、`treadmill`。走、骑、力量不进入跑量、配速、跑力。

### 3.3 算法

> 说明：RQrun 的跑力与训练指数是闭源商业算法。这里采用公开的运动科学模型，参数可配置、结果可解释，不声称与 RQ 数值一致。

#### 3.3.1 即时跑力

1. **稳定段筛选**（逐次训练）：
   - 连续 ≥ 180 秒；
   - 配速变异系数 ≤ 5%，心率变异系数 ≤ 3%；
   - 坡度变化 ≤ 2%；
   - 最多取总时长最长的 3 段。
2. **坡度补偿配速**：

   ```text
   pace_gap = pace - k_up × grade_pos + k_down × grade_neg
   k_up = 12 s/km 每 1% 上坡
   k_down = 8 s/km 每 1% 下坡
   ```

3. **有氧效率**：

   ```text
   effort = (avg_hr - rest_hr) / (max_hr - rest_hr)   // 0..1
   v_at_max = (distance / moving_seconds) / effort     // 满心率储备下的速度
   ```

4. **映射到 0–100**：用 Daniels VDOT 对照表，把 `v_at_max` 解释为阈值速度，插值得到跑力；
   结果 clamp 到 0–100。
5. **置信度**：稳定段总时长 ≥ 10 分钟为高，3–10 分钟为中，< 3 分钟为低；低置信度只展示不参与当前跑力。

#### 3.3.2 当前跑力

```text
current_power = Σ(w_i × instant_power_i) / Σ(w_i)
w_i = exp(-age_days_i / 14)        // 半衰期约 14 天
```

- 窗口固定 42 天；
- 有效即时跑力少于 3 次或覆盖少于 14 天时返回 `null`，页面显示「数据不足」；
- 每次同步后增量更新；算法参数变化时全量重算。

#### 3.3.3 训练负荷（TRIMP）

Banister 模型：

```text
ΔHR = (avg_hr - rest_hr) / (max_hr - rest_hr)   // clamp 0..1
TRIMP = duration_min × ΔHR × 0.64 × exp(1.92 × ΔHR)
```

- 有心率采样时按采样积分，没有时用平均心率与移动时长；
- 日负荷 = 当日所有训练 TRIMP 之和；
- 展示值 `load_score = round(TRIMP × 4)`，映射到 0–1000；
- 强度分布用 `workout_hr_zones` 的秒数，按「轻松 / 适中 / 困难」归档；
- 手表自带的 `workouts.training_load` 只作为详情页参考，不参与本算法。

#### 3.3.4 恢复状态

每日恢复分 0–100：

```text
sleep_score  = clamp(sleep_minutes / 420 × 40, 0, 40)
hrv_score    = clamp(sleep_hrv / hrv_baseline × 30, 0, 30)
rhr_score    = clamp((1 - (resting_hr - rhr_baseline) / 10) × 20, 0, 20)
load_score   = 前一日负荷 > 1.5 × 28 日均值 ? -10 : +10
recovery     = clamp(sleep + hrv + rhr + load, 0, 100)
```

- `recovery ≥ 60` 记为「充分恢复」；
- 缺睡眠或 HRV 的日子不补 0，标为「数据不足」，并从占比分母中剔除；
- 周期恢复占比 = 充分恢复天数 ÷ 有数据天数；同时返回覆盖天数，UI 需要显示分母。

#### 3.3.5 体能 / 疲劳 / 状况

```text
fitness_t = fitness_{t-1} × exp(-1/45) + trimp_t
fatigue_t = fatigue_{t-1} × exp(-1/15) + trimp_t
form_t    = fitness_t - fatigue_t
```

- 只用于趋势与报告，不进入概览主卡片；
- 连续 3 天 `form < -10` 标为「过度训练风险」，文案不给出医疗判断。

#### 3.3.6 累计跑量与平均配速

```text
total_distance = Σ distance_meters                 // 仅跑步类型
avg_pace       = Σ moving_seconds / total_distance  // 距离加权
```

- `moving_seconds` 缺失时退回 `end_time - start_time`；
- 配速 < 2:00/km 或 > 20:00/km 的记录标为异常，默认不计入平均配速，但在列表里保留并标注。

### 3.4 派生表（迁移 v55）

当前 `CURRENT_SCHEMA_VERSION = 54`，只追加一个版本：

```sql
CREATE TABLE IF NOT EXISTS workout_analytics (
    workout_id       TEXT PRIMARY KEY,
    instant_power    REAL,
    gap_pace_sec_km  REAL,
    aerobic_eff      REAL,
    trimp            REAL,
    stable_seconds   INTEGER NOT NULL DEFAULT 0,
    confidence       TEXT NOT NULL DEFAULT 'low',   -- high / medium / low
    analysis_rev     TEXT NOT NULL,
    computed_at      TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS daily_performance (
    date             TEXT PRIMARY KEY,              -- YYYY-MM-DD（本地日）
    current_power    REAL,
    trimp_total      REAL,
    fitness          REAL,
    fatigue          REAL,
    form             REAL,
    recovery_score   INTEGER,
    fully_recovered  INTEGER,                       -- 0 / 1 / NULL（数据不足）
    analysis_rev     TEXT NOT NULL
);
```

不新增赛事表：内核已有 [`races`](../../src-tauri/crates/core/src/storage/logbook/races.rs)（名称、日期、项目、距离、目标成绩、优先级、结果、关联运动、备注），直接复用。目标配速由 `goal_seconds ÷ distance_m` 计算，不需要新字段。

不修改 `raw_records`、`workouts`、`sleep_sessions`、`metric_samples` 的现有结构。

### 3.5 计算时机与回放

| 场景 | 行为 |
|---|---|
| 同步完成 | 只重算本次新增/变更运动对应的 `workout_analytics`；从最早变更日往后重算 `daily_performance` |
| App 启动 | 不计算；只读派生表 |
| 算法参数变化 | `analysis_revision` 变化 → 后台全量回放，64 条一事务 |
| 用户改赛事 | 不影响分析表；报告/赛事进度按需查询 |
| 数据库升级 | v55 建表后，首次启动在后台回填；回填完成前页面显示「正在准备分析」 |

`analysis_revision` 放在现有 `app_meta` 表，格式类似 `pacebridge-analytics-2026-11-v1`。

### 3.6 查询接口

所有接口返回扁平 DTO，字段 `camelCase`，由 FRB 生成 Dart 类：

```text
today_summary()                       -> TodaySummary
metric_summary(window_days)           -> WindowSummary
metric_trend(metric, window_days)     -> [TrendPoint]
load_distribution(window_days)        -> [LoadDay]
recovery_days(window_days)            -> [RecoveryDay]
workout_page(limit, offset, filter)   -> WorkoutPage
workout_detail(workout_id)            -> WorkoutDetail
workout_series(workout_id, sections)  -> WorkoutSeries
athlete_profile()                     -> AthleteProfile
race_list() / save_race() / delete_race()
ai_task_pack(scope)                   -> TaskPack
export_data(format, scope)            -> ExportFile
```

约束：

- 一次窗口切换只调用一个 `metric_summary`，返回五个指标 + 上一周期差值，避免 N+1；
- `metric_trend` 返回日粒度；180 天最多 180 个点；
- `workout_series` 在 Rust 侧降采样：心率/配速 ≤ 600 点，轨迹做 Douglas–Peucker 简化 ≤ 1000 点；
- 原始报文与逐秒采样永不出现在 DTO 里。

### 3.7 性能预算

| 场景 | 目标 | 保障 |
|---|---|---|
| 冷启动到可交互 | ≤ 1.5 s（中端 Android，180 天库） | 只读派生表；首屏查询 ≤ 5 条；图表延后一帧初始化 |
| 周期切换 30/90/180 | ≤ 300 ms | `metric_summary` 单次查询 + 内存缓存 |
| 图表点击/悬停 | ≤ 100 ms | 数据已加载；不做逐点 SQL |
| 打开训练详情 | ≤ 300 ms | 序列降采样；轨迹简化 |
| 分析回填 180 天 | ≤ 2 s | 批量事务；必要时显示进度 |
| 数据库体积 | 90 天约 50–150 MB | 沿用原始报文压缩；不新增全量副本 |

### 3.8 数据质量

- 缺失就是 `null`，不补 0，不插值；
- 每个指标返回覆盖天数与置信度；
- 数据不足时页面显示「数据不完整」，不显示 0；
- 赛事进度只统计赛事前 N 天的训练，N 由赛事距离决定（默认：半马 56 天、全马 84 天，可配置）；
- 所有分析结果标注「估算」，不给出医疗结论。

---

## 4. 功能需求

### 4.1 信息架构

P0 底部三个标签 + 设置：

```text
概览（默认）
对比
赛事
设置
```

原 PRD 的「报告」子标签放到 P1；P0 的报告入口先放在「对比」页底部的「生成阶段总结」。

### 4.2 概览

| 编号 | 功能 | 规则 |
|---|---|---|
| OV-01 | 三个核心卡片 | 当前跑力、近 30 天跑量、平均配速；每张卡显示与上一周期的差值 |
| OV-02 | 跑力趋势 | 近 30 天折线；点击「查看对比」跳到对比页并选中跑力 |
| OV-03 | 最近训练 | 最近 3 条，含日期、距离、配速、类型；点击进详情 |
| OV-04 | 同步状态 | 顶部显示上次同步时间；同步中显示进度；失败给可读原因与重试 |
| OV-05 | 空态 | 无数据时显示「还没有训练数据」+「连接 Zepp」按钮 |

### 4.3 数据对比

| 编号 | 功能 | 规则 |
|---|---|---|
| CP-01 | 周期切换 | 30 / 90 / 180 天，默认 90；切换后 300 ms 内刷新 |
| CP-02 | 五个指标卡 | 跑力、跑量、平均配速、训练负荷、恢复状态；显示本期值、上期值、差值 |
| CP-03 | 图表 | 跑力/配速折线；跑量柱状；负荷堆叠柱；恢复环形 |
| CP-04 | 对比方式 | 本期实线 + 上一周期虚线（按天序号对齐）；不做三窗口重叠 |
| CP-05 | 数据摘要 | 本地规则生成 2–3 句结论，不使用「AI」字样 |
| CP-06 | AI 任务包 | 按钮生成 Markdown/JSON 包，调用系统分享；P0 不内置对话 |
| CP-07 | 指标说明 | 每个指标标题右侧问号，弹出定义、公式、数据来源 |
| CP-08 | 图表交互 | P0 点击显示「日期 + 数值 + 当日训练」；双指缩放 P1 |

### 4.4 赛事计划（P0）

复用内核 `races`：

| 编号 | 功能 | 规则 |
|---|---|---|
| RC-01 | 新增 | 名称、日期、距离、目标配速、优先级；日期不可早于今天；配速 `分:秒` 格式 |
| RC-02 | 编辑 | 预填表单；校验同新增 |
| RC-03 | 删除 | 二次确认；不可恢复提示 |
| RC-04 | 列表 | 按日期正序；已过日期标「已结束」；空态给新增入口 |
| RC-05 | 进度 | 未结束赛事：显示赛前训练周数、跑量完成度、目标配速接近度 |
| RC-06 | 复盘 | 已结束赛事：目标 vs 实际配速、实际成绩、赛前负荷达标率；结果可填官方成绩 |
| RC-07 | 关联 | 赛事进入对比页摘要与 AI 任务包 |

不使用新表，字段映射：

| 界面 | `races` 字段 |
|---|---|
| 赛事名称 | `name` |
| 赛事日期 | `race_date` |
| 赛事距离 | `distance_m` |
| 目标配速 | `goal_seconds / (distance_m / 1000)` |
| 优先级 | `priority` |
| 实际成绩 | `result_seconds` |
| 关联训练 | `workout_id` |
| 备注 | `notes` |

### 4.5 设置与隐私

| 编号 | 功能 | 规则 |
|---|---|---|
| ST-01 | 账号 | 显示 Zepp 昵称、授权状态、上次同步；断开授权 |
| ST-02 | 同步 | 立即同步；选择首次同步范围（30/90/180 天）；显示同步账本摘要 |
| ST-03 | 外观 | 跟随系统 / 浅色 / 深色；Android 动态取色开关 |
| ST-04 | 语言 | 简体中文 / English |
| ST-05 | 数据 | 导出 JSON/CSV；显示数据库大小；清除本地数据（二次确认） |
| ST-06 | 隐私 | 说明「数据只在本机、不上传原始健康数据、无后台采集」；提供隐私政策 |
| ST-07 | 诊断 | 导出日志；日志只含事件与错误码，不含令牌与健康数值 |
| ST-08 | 关于 | 版本、开源许可、第三方字体许可 |

### 4.6 状态矩阵

| 页面 | 空 | 加载 | 错误 | 数据不足 |
|---|---|---|---|---|
| 概览 | 连接引导 | 骨架屏 | 同步失败条 + 重试 | 指标卡显示「--」+ 说明 |
| 对比 | 无数据引导 | 指标骨架 + 图表占位 | 区块错误，不影响其他区块 | 虚线 + 「数据不完整」 |
| 赛事 | 新增引导 | 列表骨架 | 保存失败 Toast + 保留表单 | 不适用 |
| 训练详情 | 无此训练 | 图表骨架 | 返回 + 重试 | 无轨迹时隐藏地图 |

---

## 5. 交互与视觉

### 5.1 设计语言

参考 FlClash 的 **Material You + Apple 式交互**：

- 大圆角、低阴影、tonal surface；
- 手机底部导航，桌面侧栏 + 主从布局；
- 可吸附高度的 bottom sheet；
- 克制的动效，状态变化有明确反馈；
- 深色模式是一等公民。

**不复制 FlClash 的源码与素材**（GPL-3.0）。只参考布局、层级、交互节奏。

### 5.2 颜色

```text
seed:        #F97316  品牌橙
success:     #22C55E
warning:     #F59E0B
danger:      #EF4444
```

- 其余颜色由 `ColorScheme.fromSeed` 生成；
- Android 12+ 可跟随壁纸动态取色，设置里可关闭；
- Windows 固定品牌 seed；
- 图表颜色从 `ColorScheme` 派生，不写死第二套色板。

### 5.3 字体与数字

- 正文：系统字体（Android 思源黑体 / Windows 微软雅黑）；
- 数值：`JetBrains Mono` 或系统等宽数字，开启 tabular figures；
- 字号：核心数值 32，卡片数值 24，正文 14–16，说明 12；
- 支持系统字体缩放 0.8–1.3，超出时禁止再放大并保持布局。

### 5.4 组件

| 组件 | 规格 |
|---|---|
| 卡片 | 圆角 20，内边距 16，tonal surface，无阴影 |
| 按钮 | 圆角 12，高度 44，最小点击区 44×44 |
| 输入框 | 圆角 12，高度 48，深色背景 + 1px 边框 |
| 底部表单 | 顶部圆角 28，可拖拽，两个吸附高度 |
| 图表 | 线宽 3，柱宽 24–32，网格线透明度 30% |
| 加载 | 骨架屏优先，环形加载只用于按钮内 |

### 5.5 动效

- 子标签切换 300 ms 淡入；
- 周期切换用 `AnimatedSwitcher`，图表数值同步过渡；
- 卡片按压缩放 1.02 → 1.00，150 ms；
- Android 使用 `HapticFeedback.selectionClick()`，设置里可关；
- 尊重系统「减少动态效果」。

### 5.6 自适应

| 宽度 | 布局 |
|---|---|
| < 600 | 底部导航；页面全屏；表单用 bottom sheet |
| 600–1024 | 侧栏 + 单列内容；表单用对话框 |
| > 1024 | 侧栏 + 列表/详情双栏；图表放大留白 |

### 5.7 文案

- 短句、动词开头、不用术语堆叠；
- 错误信息说明「发生了什么 + 怎么办」，不只给错误码；
- 指标解释放在问号浮窗，不塞进卡片；
- 不出现「AI 认为」「医学建议」这类越界表述。

### 5.8 无障碍

- 对比度达到 WCAG AA；
- 图表提供文字摘要与屏幕阅读器标签；
- 所有图标按钮有语义标签；
- 不仅靠颜色表达进步/退步，同时用箭头与文字。

---

## 6. 非功能需求

### 6.1 性能

见 3.7。补充：

- 同步过程中 UI 不阻塞，可取消；
- 列表使用惰性构建，1000 条训练不一次性建组件；
- 图表数据切换不重新解析 JSON，直接使用内存 DTO。

### 6.2 兼容性

- Android 10–16，arm64-v8a；P0 不承诺 32 位；
- Windows 10 1809+、Windows 11，x64；
- 屏幕：手机 360–480 dp 宽；Windows 1024×720 起；
- 网络：Wi-Fi / 4G / 5G；离线可看全部已同步数据。

### 6.3 隐私与安全

- 数据只在本机；不上传原始健康数据；
- 无后台采集、无定位权限、无通讯录权限；
- 令牌存系统安全存储，不写日志；
- 数据库依赖系统级加密（Android FBE、Windows BitLocker/EFS）；
- **待定**：是否需要 SQLCipher 做库级 AES-256。见第 8 节。

### 6.4 国际化

- P0：简体中文、English；
- 所有文案走 ARB，不在 Widget 里写死；
- 日期、配速、距离格式按 locale 处理；
- 导出文件名使用英文前缀，避免跨平台编码问题。

### 6.5 日志

- 只记事件、错误码、耗时，不记令牌、Cookie、健康数值、精确坐标；
- 日志滚动保留 7 天，用户可手动清除；
- 崩溃日志本地保存，用户主动导出才离开设备。

---

## 7. 里程碑与验收

> 不设时间点，按依赖顺序推进；每个里程碑必须可独立验收。

### M0 技术验证

- Flutter 空白工程在 Android 真机与 Windows 跑通；
- `crates/app-ffi` 通过 FRB 调通三个函数：`db_open`、`auth_start`、`sync_now`；
- Windows 用现有 Credential Manager，Android 用 `flutter_secure_storage`；
- 90 天同步在两端各跑一次，记录耗时、内存、包体。

**验收**：两端都能连接、同步、重启后仍保持登录；日志无令牌。

### M1 应用骨架

- 主题、路由、i18n、底部导航/侧栏；
- 连接引导、同步进度、设置页；
- 空态、加载、错误三态组件库。

**验收**：新用户 3 步内完成「连接 → 同步 → 概览出数」。

### M2 概览与训练

- 三个核心卡片、30 天跑力趋势、最近 3 条训练；
- 训练列表分页、详情页、心率/配速图、轨迹地图。

**验收**：冷启动 ≤1.5 s；详情打开 ≤300 ms；1000 条列表滚动不卡。

### M3 分析内核与对比

- `analytics` 模块与 v55 迁移；
- 增量重算、回放、`analysis_revision`；
- 五个指标、四类图表、上一周期对比、本地摘要。

**验收**：180 天回填 ≤2 s；周期切换 ≤300 ms；数据不足时全部显示「--」而不是 0。

### M4 赛事、导出与 AI 任务包

- 赛事 CRUD、进度、复盘；
- JSON/CSV 导出；
- AI 任务包生成与系统分享。

**验收**：赛事字段完整映射 `races`；任务包不含原始逐秒数据；导出文件可被 Excel 打开。

### M5 打包与内测

- Android 签名 APK/AAB；Windows Inno Setup 安装包；
- 隐私政策、开源许可、版本信息；
- 真机/真桌面回归，性能与内存复核。

**验收**：两端全新安装可用；升级不丢库；卸载/清除行为符合隐私说明。

---

## 8. 风险与开放问题

| 风险 | 影响 | 对策 |
|---|---|---|
| FRB + NDK/MSVC 构建链 | M0 卡住，后续全部延期 | M0 第一件事；先跑最小函数，再接内核 |
| Android 凭据 | 令牌泄漏或无法保存 | `flutter_secure_storage` + 内存后端；禁用明文降级 |
| 180 天数据量 | 首屏慢、内存高 | 只读派生表；详情降采样；列表分页 |
| 跑力标定 | 数值与用户预期不符 | 标注「估算」；显示置信度；参数可配置；用真实数据校准 |
| 恢复判定 | 缺 HRV 的用户占比高 | 缺数据不补 0；显示覆盖天数；允许以睡眠 + 静息心率降级 |
| Windows 安装包签名 | SmartScreen 拦截 | 内测先不签名；上架前购买证书 |
| FlClash GPL | 复制代码导致整个 App 必须 GPL | 只参考设计；代码与素材全部自写 |
| 旧桌面端数据迁移 | 用户不想重新同步 | P1 提供「导入现有 zepp.db」；P0 先重新同步 |

### 开放问题

1. **本地库加密**：PRD 要求 AES-256。当前内核是普通 SQLite，依赖系统级加密。是否本期上 SQLCipher？建议 P0 先用系统加密，P1 评估 SQLCipher（迁移、备份、性能都要重测）。
2. **报告导出格式**：PDF/Excel 是 P1；P0 只做 JSON/CSV 是否满足？
3. **Windows 是否要托盘/后台同步**：P0 关闭窗口即退出；若用户需要「每天自动同步」，需要托盘 + 计划任务，放 P1。
4. **高级通道是否在 App 暴露**：内核保留 `api-mifit` 高级通道；App P0 只接官方 OAuth。高级通道的 WebView 登录放 P1。
5. **旧数据目录**：Windows 是否自动探测旧版安装目录并导入，还是让用户手动选择 `zepp.db`？

---

## 附录 A：FFI API 草案

```text
// 生命周期
app_init(data_dir: String) -> AppInfo
app_shutdown()

// 授权
auth_start() -> AuthStart { url, state, claimSecret }
auth_poll(state, claimSecret) -> AuthPoll { pending | ready | expired | denied | failed }
auth_status() -> AuthStatus
auth_disconnect()

// 同步
sync_now(days: i32, progress: StreamSink<SyncProgress>) -> SyncReport
sync_status() -> SyncStatus

// 查询
today_summary() -> TodaySummary
metric_summary(windowDays: i32) -> WindowSummary
metric_trend(metric: String, windowDays: i32) -> Vec<TrendPoint>
load_distribution(windowDays: i32) -> Vec<LoadDay>
recovery_days(windowDays: i32) -> Vec<RecoveryDay>
workout_page(limit: i32, offset: i32, filter: WorkoutFilter) -> WorkoutPage
workout_detail(workoutId: String) -> WorkoutDetail
workout_series(workoutId: String, sections: Vec<String>) -> WorkoutSeries
athlete_profile() -> AthleteProfile

// 赛事
race_list() -> Vec<Race>
save_race(input: RaceInput) -> i64
delete_race(id: i64)

// 导出与 AI
export_data(format: String, scope: ExportScope) -> String
ai_task_pack(scope: ExportScope) -> String
```

## 附录 B：算法参数默认值

| 参数 | 默认值 | 可配置 |
|---|---|---|
| 当前跑力窗口 | 42 天 | 是 |
| 当前跑力半衰期 | 14 天 | 是 |
| 稳定段最短时长 | 180 秒 | 是 |
| 配速 CV 上限 | 5% | 是 |
| 心率 CV 上限 | 3% | 是 |
| 上坡补偿 | 12 s/km 每 1% | 是 |
| 下坡补偿 | 8 s/km 每 1% | 是 |
| TRIMP 展示系数 | ×4 | 是 |
| 体能衰减 τ | 45 天 | 是 |
| 疲劳衰减 τ | 15 天 | 是 |
| 充分恢复阈值 | 60 分 | 是 |
| 睡眠目标 | 420 分钟 | 是 |
| 半马备战窗 | 56 天 | 是 |
| 全马备战窗 | 84 天 | 是 |

## 附录 C：内核改动清单

| 改动 | 位置 | 说明 |
|---|---|---|
| 新增 `analytics` 模块 | `crates/core/src/analytics/` | 纯函数 + 单测，不依赖 UI |
| 迁移 v55 | `crates/core/src/storage/migrations.rs` | `workout_analytics`、`daily_performance`，只追加 |
| 分析编排 | `crates/core/src/storage/` 或 `analytics/` | 同步后增量重算、全量回放 |
| `analysis_revision` | `app_meta` | 参数变化触发回放 |
| 查询门面 | `crates/core/src/storage/` | today / summary / trend / load / recovery |
| 降采样与轨迹简化 | `crates/core/src/` | 详情序列 ≤600 点，轨迹 ≤1000 点 |
| FRB 桥接层 | `crates/app-ffi/` | 新增 crate，`cdylib` + `staticlib` |
| TLS | `src-tauri/Cargo.toml` | `reqwest` 切 `rustls-tls` |
| 数据目录 | 无需改内核 | 使用 `Database::open_migrated` / `SyncManager::with_data_dir` |
| 凭据 | 无需改 Windows；Android 由 Dart 持有 | 内核内存后端或 App 层注入 |
| CLI / MCP | 不改 | 继续使用现有契约 |
