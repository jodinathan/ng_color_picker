import 'dart:async';
import 'dart:html';
import 'package:ngdart/angular.dart';
import 'package:meta/meta.dart';
import 'generic.dart';

abstract class DisposableComponent extends Disposable implements OnDestroy {
  @mustCallSuper
  @override
  void ngOnDestroy() => dispose();

  StreamSubscription<T> documentListen<T extends Event>(
      String eventName, Function(T) fn) {
    final ctrl = controller<T>();

    document.addEventListener(eventName, (event) {
      ctrl.add(event as T);
    });

    return each(ctrl.stream, fn);
  }
}