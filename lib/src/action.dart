import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

typedef CreateSelector<T> = T Function();
typedef CreateObservableSelector<T> = Observable<T> Function();
typedef CreateFutureSelector<T> = Future<T> Function();

class Action<T> {
  CreateObservableSelector<T> _executeFactory;
  final Subject<dynamic> _thrownErrorsSubject = PublishSubject<dynamic>();
  BehaviorSubject<T> _resultSubject = BehaviorSubject();
  StreamSubscription<T> _inflightRequest;
  Observable<T> _currentExecution;

  Action(CreateObservableSelector<T> selector, {T initialValue}) {
    _executeFactory = selector;

    if (initialValue != null) {
      _resultSubject = BehaviorSubject.seeded(initialValue);
    }
  }

  Action.sync(CreateSelector<T> selector, {T initialValue}) {
    _executeFactory = () => Observable.defer(() => Observable.just(selector()));

    if (initialValue != null) {
      _resultSubject = BehaviorSubject.seeded(initialValue);
    }
  }

  Action.future(CreateFutureSelector<T> selector, {T initialValue}) {
    _executeFactory =
        () => Observable.defer(() => Observable.fromFuture(selector()));

    if (initialValue != null) {
      _resultSubject = BehaviorSubject.seeded(initialValue);
    }
  }

  Function bind() {
    return execute;
  }

  Observable<T> execute() {
    if (_currentExecution != null) return _currentExecution;
    final result = ReplaySubject<T>();

    // NB: This is written in such a dumb way because apparently
    // publish() in Dart just doesn't.....work?
    try {
      _executeFactory().doOnCancel(() {
        _currentExecution = null;
      }).listen((x) {
        _resultSubject.add(x);
        result.add(x);
      }, onDone: () {
        result.close();
        _currentExecution = null;
      }, onError: (dynamic e) {
        result.addError(e);
        _thrownErrorsSubject.addError(e);
        _currentExecution = null;
      }, cancelOnError: true);
    } catch (e) {
      result.addError(e);
      _thrownErrorsSubject.addError(e);
      _currentExecution = null;
    }

    _currentExecution = result;
    return result;
  }

  bool get isExecuting {
    return _currentExecution != null;
  }

  Observable<T> get result {
    return _resultSubject;
  }

  Observable<dynamic> get thrownErrors {
    return _thrownErrorsSubject;
  }
}
