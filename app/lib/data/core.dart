import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pacebridge/src/rust/api/app.dart';

/// App 启动时由 main() 用真实 [AppInfo] 覆盖；默认值让 widget test 可以
/// 单独渲染页面，不需要初始化 Rust 运行时。
final appInfoProvider = Provider<AppInfo>(
  (ref) => const AppInfo(dataDir: '', schemaVersion: 0, analyticsReady: false),
);
