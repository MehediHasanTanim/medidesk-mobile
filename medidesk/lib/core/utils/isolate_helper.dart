import 'dart:isolate';

/// Runs a pure computation in a separate [Isolate] so the UI thread
/// remains responsive during heavy JSON parsing (e.g. bulk sync payloads).
///
/// [fn] must be a top-level or static function — closures with captured
/// state cannot be sent across isolate boundaries.
Future<R> runInIsolate<T, R>(R Function(T) fn, T input) async {
  return Isolate.run(() => fn(input));
}
