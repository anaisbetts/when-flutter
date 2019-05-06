import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_rx/src/converters.dart';
import 'package:when_rx/src/model.dart';

class TestViewModelProps extends ViewModel {
  String _someString = 'original';
  String _theTextBox = '';
}

class TestViewModel extends TestViewModelProps with TestViewModelNotifyMixin {}

// THIS IS WHAT WE WANT TO BOILERPLATE AWAY
mixin TestViewModelNotifyMixin on TestViewModelProps {
  String get someString => notifyAccessed('someString', _someString);
  set someString(String v) =>
      notifyAndSet('someString', _someString, () => _someString = v);
  String get theTextBox => notifyAccessed('theTextBox', _theTextBox);
  set theTextBox(String v) =>
      notifyAndSet('theTextBox', _theTextBox, () => _theTextBox = v);
}
// END BOILERPLATE

class TestWidget extends ViewModelWidget<TestViewModel> {
  final TextEditingController controller = TextEditingController();

  TestWidget() : super(() => TestViewModel()) {
    controller.text = '';
    setupBinds([
      (m) =>
          fromValueListenable(controller).listen((x) => m.theTextBox = x.text),
    ]);
  }

  @override
  Widget build(BuildContext context, TestViewModel model) {
    return MaterialApp(
        home: Scaffold(
      body: Flex(
        direction: Axis.vertical,
        children: <Widget>[
          Text('Hello ${model.someString} + ${model.theTextBox}'),
          TextField(
            controller: controller,
          ),
          RaisedButton(
            key: const Key('changeSomeString'),
            onPressed: () => model.someString = 'changed',
          )
        ],
      ),
    ));
  }
}

void main() {
  testWidgets('rerender on set props', (WidgetTester tester) async {
    var fixture = TestWidget();
    await tester.pumpWidget(fixture);

    expect(find.text('Hello original + '), findsOneWidget);

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    expect(find.text('Hello changed + '), findsOneWidget);
  });

  testWidgets('rerender on text changes', (WidgetTester tester) async {
    var fixture = TestWidget();
    await tester.pumpWidget(fixture);

    await tester.enterText(find.byType(TextField), 'textbox');
    await tester.pumpAndSettle();

    expect(find.text('Hello original + textbox'), findsOneWidget);

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    expect(find.text('Hello changed + textbox'), findsOneWidget);
  });
}
