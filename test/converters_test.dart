import 'package:flutter_test/flutter_test.dart';

import 'package:rxdart/rxdart.dart';

import 'package:when_rx/src/converters.dart';
import 'support.dart';

void main() {
  test('toValueListenable should let you get the current value', () async {
    var fixture = toValueListenable(Observable.just(42), subscribeNow: true);
    await makeRxDartWork();

    expect(fixture.value, 42);
  });

  test('toValueListenable should be lazy', () async {
    var subCount = 0;
    var unsubCount = 0;

    var fixture = toValueListenable(BehaviorSubject.seeded(42).doOnListen(() {
      subCount++;
    }).doOnCancel(() {
      unsubCount++;
    }));

    expect(subCount, 0);
    expect(unsubCount, 0);

    var listener = () {};
    var listener2 = () {};
    fixture.addListener(listener);

    await makeRxDartWork();
    expect(subCount, 1);
    expect(unsubCount, 0);
    expect(fixture.value, 42);

    fixture.addListener(listener2);

    // NB: subCount is still 1 here because we publish()
    // the Observable
    await makeRxDartWork();
    expect(subCount, 1);
    expect(unsubCount, 0);

    fixture.removeListener(listener);

    await makeRxDartWork();
    expect(subCount, 1);
    expect(unsubCount, 0);

    fixture.removeListener(listener2);

    await makeRxDartWork();
    expect(subCount, 1);
    expect(unsubCount, 1);
  });

  test('toValueListenable should let me listen', () async {
    var input = PublishSubject<int>();
    var fixture = toValueListenable(input);

    var signaled = false;
    var listener = () => signaled = true;
    fixture.addListener(listener);

    await makeRxDartWork();
    expect(signaled, false);

    input.add(42);

    await makeRxDartWork();
    expect(signaled, true);

    signaled = false;
    fixture.removeListener(listener);

    input.add(42);

    await makeRxDartWork();
    expect(signaled, false);
  });
}
