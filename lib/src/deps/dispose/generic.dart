import 'dart:async';

import 'package:change_notifier/change_notifier.dart';
import '../tuple.dart';
import 'interval.dart';

class _Timer implements Timer {
  final Timer delegate;
  final Disposable _handler;
  final Symbol? id;

  @override
  bool get isActive => delegate.isActive;

  @override
  int get tick => delegate.tick;

  void _rem() {
    if (id == null) {
      _handler._timers.remove(this);
    } else {
      _handler._uniqueTimers.remove(id);
    }
  }

  @override
  void cancel() {
    delegate.cancel();

    _rem();
  }

  _Timer(this._handler, this.delegate, this.id);
}

class ControlledStreamController<T> implements StreamController<T> {
  ControlledStreamController({FutureOr<void> Function()? onCancel})
      : _ctrl = StreamController<T>(onCancel: onCancel);

  ControlledStreamController.broadcast({FutureOr<void> Function()? onCancel})
      : _ctrl = StreamController<T>.broadcast(onCancel: onCancel);

  final StreamController<T> _ctrl;
  final List<StreamSubscription<T>> _subscriptions = [];

  @override
  FutureOr<void> Function()? get onCancel => _ctrl.onCancel;

  @override
  void Function()? get onListen => _ctrl.onListen;

  @override
  void Function()? get onPause => _ctrl.onPause;

  @override
  void Function()? get onResume => _ctrl.onResume;

  @override
  void add(T event) {
    _ctrl.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _ctrl.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<T> source, {bool? cancelOnError}) {
    assert(cancelOnError != true, 'Not implemented');

    final subs = source.listen((ev) => _ctrl.add(ev));

    _subscriptions.add(subs);

    return subs.asFuture();
  }

  @override
  Future close() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }

    return _ctrl.close();
  }

  @override
  Future get done => _ctrl.done;

  @override
  bool get hasListener => _ctrl.hasListener;

  @override
  bool get isClosed => _ctrl.isClosed;

  @override
  bool get isPaused => _ctrl.isPaused;

  @override
  StreamSink<T> get sink => _ctrl.sink;

  @override
  Stream<T> get stream => _ctrl.stream;

  @override
  set onCancel(FutureOr<void> Function()? onCancel) =>
      _ctrl.onCancel = onCancel;

  @override
  set onListen(void Function()? onListen) => _ctrl.onListen = onListen;

  @override
  set onPause(void Function()? onPause) => _ctrl.onPause = onPause;

  @override
  set onResume(void Function()? onResume) => _ctrl.onResume = onResume;
}

class ControlledStreamSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _delegate;
  final void Function() _cancel;

  @override
  Future<void> cancel() {
    _cancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T)? handleData) => _delegate.onData(handleData);

  @override
  void onError(Function? handleError) => _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture(futureValue);

  ControlledStreamSubscription(this._delegate, this._cancel);
}

mixin class Disposable {
  Set<StreamSubscription> _subs = {};
  Map<Symbol, StreamSubscription> _uniqueSubs = {};
  Map<Symbol, Tuple2<ChangeNotifier, VoidCallback>> _uniqueListeners = {};
  Set<StreamController> _ctrls = {};
  Set<_Timer> _timers = {};
  Map<Symbol, _Timer> _uniqueTimers = {};
  Set<Disposable> _disposables = {};
  Disposable? _parent;
  bool _canceling = false;

  void _sanity() {
    assert(!_canceling);
  }

  Disposable reusable() {
    final ret = Disposable();

    disposable(ret);

    return ret;
  }

  Future<bool> cancelBind(Symbol key) async {
    final ret = _uniqueSubs[key];

    if (ret != null) {
      await ret.cancel();
      return true;
    }

    return false;
  }

  bool cancelTimer(Symbol key) {
    final ret = _uniqueTimers[key];

    if (ret != null) {
      ret.cancel();
      return true;
    }

    return false;
  }

  /// Listens and iterates through [stream] by calling [fn].
  /// The listener is disposed in the [dispose] function.
  ///
  /// If you add a [uniqueId], it means that whenever you call [each],
  /// we will make sure that clear any listener with the same [uniqueId].
  StreamSubscription<T> each<T>(Stream<T> stream, void Function(T item) fn,
      {@Deprecated('Use [uniqueEach] instead') Symbol? uniqueId}) {
    late StreamSubscription<T> ret;

    _sanity();

    if (uniqueId == null) {
      ret = ControlledStreamSubscription(
          stream.listen(fn), () => _subs.remove(ret));
      _subs.add(ret);
    } else {
      ret = ControlledStreamSubscription(
          stream.listen(fn), () => _uniqueSubs.remove(uniqueId));

      _uniqueSubs[uniqueId]?.cancel();

      _uniqueSubs[uniqueId] = ret;
    }

    return ret;
  }

  Future<T> takeFirst<T>(Stream<T> stream) {
    final cmp = Completer<T>();
    late StreamSubscription subs;

    subs = each(stream, (item) {
      subs.cancel();
      cmp.complete(item);
    });

    return cmp.future;
  }

  Future<void> cancelUnique(Symbol id) async {
    final sub = _uniqueSubs[id];

    if (sub != null) {
      _uniqueSubs.remove(id);
      return sub.cancel();
    }
  }

  Future<void> cancelUniques(Set<Symbol> ids) async {
    ids.forEach(cancelUnique);
  }

  /// Listens and iterates through [stream] by calling [fn].
  /// The listener is disposed in the [dispose] function.
  ///
  /// If you add a [uniqueId], it means that whenever you call [each],
  /// we will make sure that clear any listener with the same [uniqueId].
  StreamSubscription<T> uniqueEach<T>(
      Symbol id, Stream<T> stream, void Function(T item) fn) {
    late StreamSubscription<T> ret;

    _sanity();

    ret = ControlledStreamSubscription(
        stream.listen(fn), () => _uniqueSubs.remove(id));

    _uniqueSubs[id]?.cancel();

    _uniqueSubs[id] = ret;

    return ret;
  }

  /// Listens and iterates through [obj.addListener] by calling [fn].
  /// The listener is disposed in the [dispose] function.
  ///
  /// Whenever you call [uniqueListen]
  /// we will make sure that clear any listener with the same [id].
  void uniqueListen(Symbol id, ChangeNotifier obj, void Function() fn) {
    _sanity();

    obj.addListener(fn);

    final cur = _uniqueListeners[id];

    if (cur != null) {
      cur.item1.removeListener(cur.item2);
    }

    _uniqueListeners[id] = Tuple2(obj, fn);
  }

  /// Creates a [StreamController] that is closed within [dispose].
  ///
  /// Set [broadcast] to true if you need a
  /// broadcasting controller as in [StreamController.broadcast].
  StreamController<T> controller<T>(
      {bool broadcast = false, FutureOr<void> Function()? onCancel /*?*/
      }) {
    StreamController<T> ret;

    _sanity();

    if (broadcast) {
      ret = ControlledStreamController<T>.broadcast(onCancel: onCancel);
    } else {
      ret = ControlledStreamController<T>(onCancel: onCancel);
    }

    ret.done.then((ev) => _ctrls.remove(ret));

    _ctrls.add(ret);

    return ret;
  }

  /// Creates a [StreamController.broadcast] that is closed within [dispose].
  StreamController<T> broadcaster<T>({FutureOr<void> Function()? onCancel /*?*/
      }) {
    _sanity();

    final ret = ControlledStreamController<T>.broadcast(onCancel: onCancel);

    ret.done.then((ev) => _ctrls.remove(ret));

    _ctrls.add(ret);

    return ret;
  }

  /// Binds another [Disposable] object to be disposed when this
  /// is disposed.
  void disposable(Disposable disposable) {
    _sanity();

    disposable._parent = this;
    _disposables.add(disposable);
  }

  /// Creates a periodic [Timer.periodic] that gets cancelled within [dispose].
  ///
  /// Set [uniqueId] to some [Symbol] to make this timer unique.
  /// This means that we will cancel the previous timer with same symbol
  /// before assigning a new one.
  Timer periodic(Duration duration, Function(Timer) fn, {Symbol? uniqueId}) {
    final tm = Timer.periodic(duration, (t) => fn(t));

    return _timer(tm, uniqueId: uniqueId);
  }

  Timer interval(Duration duration, Function(Timer) fn,
      {Symbol? uniqueId, bool execNow = true}) {
    final tm = IntervalTimer(fn, duration, execNow: execNow);

    return _timer(tm, uniqueId: uniqueId);
  }

  StreamedIntervalTimer streamedInterval<T, E>(
      Stream<T> valueStream, Duration duration, Function(T?) fn,
      {Symbol? uniqueId}) {
    final tm = StreamedIntervalTimer(fn, duration, execNow: true);

    each<T>(valueStream, (ev) {
      tm.add(ev);
    });

    _timer(tm, uniqueId: uniqueId);

    return tm;
  }

  _Timer _timer(Timer tm, {Symbol? uniqueId}) {
    _sanity();

    final ret = _Timer(this, tm, uniqueId);

    if (uniqueId != null) {
      _uniqueTimers[uniqueId]?.cancel();
      _uniqueTimers[uniqueId] = ret;
    } else {
      _timers.add(ret);
    }

    return ret;
  }

  /// Cancel all active listeners, timers, close the controllers
  /// and disposes other disposables bound with [bind].
  ///
  /// You should not use this class after it's disposal.
  /// If you only want to cancel/clear stuff, use [cancelBindings].
  Future<void> dispose() async {
    _canceling = true;

    final ret = <Future>[];

    if (_parent != null) {
      _parent!._disposables.remove(this);
    }

    final disposables = _disposables;
    _disposables = {};

    for (var disposable in disposables) {
      ret.add(disposable.dispose());
    }

    assert(_disposables.isEmpty);

    ret.add(cancelBindings());

    await Future.wait(ret);
    _canceling = false;
  }

  /// Cancel all active listeners, timers and close the controllers.
  /// This *does not* dispose other disposables bound with [bind].
  ///
  /// [dispose] calls this function internally.
  Future<void> cancelBindings() {
    final ret = <Future>[];
    final subs = _subs;
    final uniques = _uniqueSubs;
    final ctrls = _ctrls;
    final timers = _timers;
    final utimers = _uniqueTimers;
    final listeners = _uniqueListeners;

    _subs = {};
    _uniqueSubs = {};
    _ctrls = {};
    _timers = {};
    _uniqueTimers = {};
    _uniqueListeners = {};

    for (final s in subs) {
      ret.add(s.cancel());
    }

    for (final s in uniques.values) {
      ret.add(s.cancel());
    }

    for (final tup in listeners.values) {
      tup.item1.removeListener(tup.item2);
    }

    for (final c in ctrls) {
      ret.add(c.close());
    }

    for (final t in timers) {
      t.cancel();
    }

    for (final t in utimers.values) {
      t.cancel();
    }

    return Future.wait(ret);
  }

  /// Creates a [Timer] that gets cancelled within [dispose] if not executed.
  ///
  /// Set [uniqueId] to some [Symbol] to make this timer unique.
  /// This means that we will cancel the previous timer with same symbol
  /// before assigning a new one.
  Timer timer(Duration duration, Function() fn) {
    late _Timer ret;
    final tm = Timer(duration, () {
      ret._rem();
      fn();
    });
    ret = _timer(tm);

    return ret;
  }

  /// Creates a [Timer] that gets cancelled within [dispose] if not executed.
  ///
  /// Set [uniqueId] to some [Symbol] to make this timer unique.
  /// This means that we will cancel the previous timer with same symbol
  /// before assigning a new one.
  Timer uniqueTimer(Symbol uniqueId, Duration duration, Function() fn) {
    late _Timer ret;
    final tm = Timer(duration, () {
      ret._rem();
      fn();
    });
    ret = _timer(tm, uniqueId: uniqueId);

    return ret;
  }
}