import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pacebridge/data/bridge.dart';
import 'package:pacebridge/src/rust/api/app.dart' as rust;

/// 官方授权状态；没有连接或内核未就绪时是 null。
final authStatusProvider = FutureProvider<rust.AuthStatusDto?>((ref) async {
  return bridgeCall(() => rust.authStatus());
});
