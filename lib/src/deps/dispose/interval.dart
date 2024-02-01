import 'dart:async';

class IntervalTimer implements Timer {
  final FutureOr<void> Function(IntervalTimer)? fn;
  final Duration duration;
  late bool _open;
  @override
  bool get isActive => _open;
  int _tick = 0;
  @override
  int get tick => _tick;

  void _exec() async {
    if (_open) {
      await fn!(this);
      _tick++;

      Timer(duration, _exec);
    }
  }

  void start() {
    _open = true;

    return _exec();
  }

  @override
  void cancel() {
    _open = false;
  }

  IntervalTimer(this.fn, this.duration, {bool execNow = true}) {
    if (fn != null) {
      if (execNow) {
        start();
      } else {
        Timer(duration, start);
      }
    }
  }
}

class StreamedIntervalTimer<T> extends IntervalTimer {
  T? _obj;

  @override
  // ignore: overridden_fields
  FutureOr<void> Function(IntervalTimer)? fn;

  void add(T item) {
    _obj = item;
  }

  void clear() {
    _obj = null;
  }

  StreamedIntervalTimer(FutureOr<void> Function(T?) func,
      Duration duration, {bool execNow = true}):
      super(null, duration, execNow: false) {
    fn = (tm) {
      func(_obj);
      _obj = null;
    };

    if (execNow) {
      start();
    } else {
      Timer(duration, start);
    }
  }
}