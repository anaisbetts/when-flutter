import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

Observable<T> fromValueListenable<T>(ValueListenable<T> listener) {
  // ignore: close_sinks
  Subject<T> subj = BehaviorSubject.seeded(listener.value);

  final next = () {
    subj.add(listener.value);
  };

  subj.onCancel = () => listener.removeListener(next);
  listener.addListener(next);

  return subj;
}

Observable<void> fromListenable(Listenable listener) {
  // ignore: close_sinks
  Subject<void> subj = PublishSubject();

  final next = () {
    subj.add(null);
  };

  subj.onCancel = () => listener.removeListener(next);
  listener.addListener(next);

  return subj;
}

Observable<AnimationStatus> fromAnimationStatus(Animation<dynamic> listener) {
  // ignore: close_sinks
  Subject<AnimationStatus> subj = BehaviorSubject.seeded(listener.status);

  final next = (AnimationStatus st) {
    subj.add(st);
  };

  subj.onCancel = () => listener.removeStatusListener(next);
  listener.addStatusListener(next);

  return subj;
}

class _ObservableValueListenable<T> implements ValueListenable<T> {
  ValueObservable<T> source;
  final Map<VoidCallback, StreamSubscription<T>> subs = {};

  _ObservableValueListenable(Observable<T> src, {bool subscribeNow = false}) {
    source = src.publishValue().refCount();

    if (subscribeNow) {
      // Leak a listener so that value will be usable even when you
      // don't have any listeners
      addListener(() {});
    }
  }

  @override
  void addListener(listener) {
    subs[listener] = source.listen((_) => listener());
  }

  @override
  void removeListener(listener) {
    subs[listener].cancel();
    subs.remove(listener);
  }

  @override
  T get value => source.value;
}

ValueListenable<T> toValueListenable<T>(Observable<T> input,
    {bool subscribeNow = false}) {
  return _ObservableValueListenable(input, subscribeNow: subscribeNow);
}
