import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:when_rx/src/action.dart';

import 'support.dart';

void main() {
  test('should call the factory function', () async {
    var die = true;
    final fixture = Action.sync(() => die = false);
    expect(die, true);

    await makeRxDartWork();

    fixture.execute();
    expect(die, false);
  });

  test('should signal a result', () async {
    var die = true;
    final fixture = Action.sync(() => die = false, initialValue: false);

    final result = createCollection(fixture.result);
    await makeRxDartWork();

    expect(result.length, 1);

    fixture.execute();
    await makeRxDartWork();

    expect(result.length, 2);
    expect(die, false);
  });

  test('should pipe errors to thrownErrors', () async {
    final fixture = Action<bool>(() => Observable.error(Exception('die')));
    final result = createCollection<dynamic>(fixture.thrownErrors);

    await makeRxDartWork();

    dynamic err;
    expect(result.length, 0);
    expect(err, null);

    await makeRxDartWork();

    fixture.execute().listen((_) {}, onError: (dynamic e) => err = e);

    await makeRxDartWork();

    expect(err != null, true);
    expect(result.length, 1);
  });

  test('should report isExecuting correctly', () async {
    final input = PublishSubject<bool>();
    final fixture = Action(() => input, initialValue: true);
    final result1 = createCollection(fixture.result);

    await makeRxDartWork();

    expect(fixture.isExecuting, false);
    expect(result1.length, 1);

    // Undo result being a BehaviorSubject
    result1.removeLast();

    final result2 = createCollection(fixture.execute());
    await makeRxDartWork();

    expect(result1, result2);
    expect(result1.length, 0);
    expect(fixture.isExecuting, true);

    input.add(false);
    await makeRxDartWork();

    expect(result1, result2);
    expect(result1.length, 1);
    expect(fixture.isExecuting, true);

    input.add(true);
    await makeRxDartWork();

    expect(result1, result2);
    expect(result1.length, 2);
    expect(fixture.isExecuting, true);

    await input.close();
    await makeRxDartWork();

    expect(result1, result2);
    expect(result1.length, 2);
    expect(fixture.isExecuting, false);
  });

  test('should dedupe calls to execute', () async {
    var callCount = 0;

    final input = PublishSubject<bool>();
    final fixture = Action<bool>(() {
      callCount++;
      return input;
    }, initialValue: true);

    final result = createCollection(fixture.result);
    await makeRxDartWork();

    expect(fixture.isExecuting, false);
    expect(result.length, 1);
    expect(callCount, 0);

    fixture.execute();
    await makeRxDartWork();

    expect(callCount, 1);

    fixture.execute();
    await makeRxDartWork();

    expect(callCount, 1);

    await input.close();
    await makeRxDartWork();

    expect(callCount, 1);

    fixture.execute();
    await makeRxDartWork();

    expect(callCount, 2);
  });
}
