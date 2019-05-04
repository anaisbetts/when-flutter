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
