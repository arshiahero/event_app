import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity reports transports, not guaranteed internet access.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, this.useMocks = true})
    : _connectivity = connectivity;
  final Connectivity? _connectivity;
  final bool useMocks;
  final _changes = StreamController<List<ConnectivityResult>>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult> _current = const [ConnectivityResult.none];
  bool _disposed = false;
  bool _started = false;
  int _eventRevision = 0;
  Future<void>? _starting;
  Future<void>? _disposing;
  List<ConnectivityResult> get current => _current;
  bool get hasTransport =>
      _current.any((result) => result != ConnectivityResult.none);
  Stream<List<ConnectivityResult>> get changes => _changes.stream;

  /// Explicit start: construction performs no platform work.
  Future<void> start() {
    if (_disposed)
      return Future.error(StateError('ConnectivityService is disposed.'));
    if (_starting != null) return _starting!;
    if (_started) return Future<void>.value();
    final done = Completer<void>();
    _starting = done.future;
    unawaited(_start(done));
    return done.future;
  }

  Future<void> _start(Completer<void> done) async {
    try {
      if (useMocks) {
        setMockStatuses(const [ConnectivityResult.wifi]);
      } else {
        final connectivity = _connectivity;
        if (connectivity == null)
          throw StateError('Real connectivity requires Connectivity.');
        final revision = _eventRevision;
        _subscription = connectivity.onConnectivityChanged.listen(
          (values) {
            _eventRevision++;
            _emit(values);
          },
          onError: (Object error, StackTrace stack) {
            _eventRevision++;
            if (!_disposed && !_changes.isClosed)
              _changes.addError(error, stack);
          },
        );
        final initial = await connectivity.checkConnectivity();
        // A stream event (including an error) is newer than this initial query.
        if (!_disposed && revision == _eventRevision) _emit(initial);
      }
      if (!_disposed) _started = true;
      done.complete();
    } catch (error, stack) {
      final subscription = _subscription;
      _subscription = null;
      try {
        await subscription?.cancel();
      } catch (_) {
        /* Preserve the startup error, not a secondary shutdown error. */
      }
      done.completeError(error, stack);
    } finally {
      _starting = null;
    }
  }

  void setMockStatuses(List<ConnectivityResult> values) {
    if (!useMocks) throw StateError('Mock statuses are disabled.');
    if (_disposed) throw StateError('ConnectivityService is disposed.');
    _eventRevision++;
    _emit(values);
  }

  void _emit(List<ConnectivityResult> values) {
    if (_disposed || _changes.isClosed) return;
    _current = List.unmodifiable(values);
    _changes.add(_current);
  }

  Future<void> dispose() {
    if (_disposing != null) return _disposing!;
    _disposed = true;
    _started = false;
    final done = Completer<void>();
    _disposing = done.future;
    unawaited(_dispose(done));
    return done.future;
  }

  Future<void> _dispose(Completer<void> done) async {
    final subscription = _subscription;
    _subscription = null;
    try {
      try {
        await subscription?.cancel();
      } finally {
        await _changes.close();
      }
      done.complete();
    } catch (error, stack) {
      done.completeError(error, stack);
    }
  }
}
