/// A request-scoped signal independent of Flutter and HTTP libraries.
class RequestControl {
  bool _isCancelled = false;
  final Set<void Function()> _listeners = {};

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// Returns a function that removes this operation's listener.
  void Function() onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void throwIfCancelled() {
    if (_isCancelled) throw const RequestCancelled();
  }
}

/// Superseded/disposed work is not a visible catalog failure.
class RequestCancelled implements Exception {
  const RequestCancelled();
}
