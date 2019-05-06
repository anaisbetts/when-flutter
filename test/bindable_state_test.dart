import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_rx/src/bindable_state.dart';
import 'package:when_rx/src/converters.dart';

class SubjectWidget extends StatefulWidget {
  final ValueNotifier<int> listenable = ValueNotifier(0);

  @override
  _SubjectWidgetState createState() => _SubjectWidgetState();
}

var cancelCount = 0;
var bindCount = 0;

class _SubjectWidgetState extends BindableState<SubjectWidget> {
  int currentValue = 0;

  _SubjectWidgetState() {
    setupBinds([
      () => fromValueListenable(widget.listenable)
          .doOnCancel(() => cancelCount++)
          .doOnListen(() => bindCount++)
          .listen((x) => setState(() => currentValue = x))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Text(currentValue.toString());
  }
}

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    cancelCount = 0;
    bindCount = 0;

    final widget = SubjectWidget();
    final scaffold = MaterialApp(
      home: widget,
    );

    expect(cancelCount, 0);
    expect(bindCount, 0);

    await tester.pumpWidget(scaffold);

    expect(cancelCount, 0);
    expect(bindCount, 1);
    expect(find.text('0'), findsOneWidget);

    widget.listenable.value = 5;
    await tester.pumpAndSettle();

    expect(cancelCount, 0);
    expect(bindCount, 1);

    expect(find.text('5'), findsOneWidget);

    // Simulate the widget being unmounted
    await tester.pumpWidget(Container());

    expect(cancelCount, 1);
    expect(bindCount, 1);

    // Simulate the widget being remounted
    await tester.pumpWidget(scaffold);

    expect(cancelCount, 1);
    expect(bindCount, 2);
  });
}
