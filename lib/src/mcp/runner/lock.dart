import 'dart:async';

/// {@template lock}
/// A first-in, first-out asynchronous mutex.
///
/// [run] executes its body only after every previously enqueued body has
/// completed, so at most one body runs at a time. Unlike a one-deep lock
/// (which only awaits a single pending run), this serializes correctly for any
/// number of concurrent callers — each call chains onto the tail of the queue.
/// {@endtemplate}
class Lock {
  /// Tail of the queue: the future that completes when the most recently
  /// enqueued run finishes.
  Future<void> _tail = Future<void>.value();

  /// Runs [body] once all previously enqueued runs have completed, and returns
  /// its result. A failing [body] does not break the queue — subsequent runs
  /// still proceed in order.
  Future<T> run<T>(Future<T> Function() body) {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.then((_) => body()).whenComplete(completer.complete);
  }
}
