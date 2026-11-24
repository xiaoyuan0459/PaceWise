/// 同步调用 Rust 内核时的兜底。
///
/// 内核尚未初始化（启动失败、widget test）或查询出错时返回 null，让页面显示
/// 「暂无数据」而不是把异常抛到 build 里。
T? bridgeCall<T>(T Function() call) {
  try {
    return call();
  } catch (_) {
    return null;
  }
}
