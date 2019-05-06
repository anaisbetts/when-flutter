import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:when_rx/src/model.dart';

class TestViewModelProps extends ViewModel {
  String _someString = 'original';
}

class TestViewModel extends TestViewModelProps with TestViewModelNotifyMixin {}

// THIS IS WHAT WE WANT TO BOILERPLATE AWAY
mixin TestViewModelNotifyMixin on TestViewModelProps {
  String get someString => notifyAccessed('someString', _someString);
  set someString(String v) =>
      notifyAndSet('someString', _someString, () => _someString = v);
}
// END BOILERPLATE

class TestWidget extends ViewModelWidget<TestViewModel> {
  TestWidget() : super(() => TestViewModel());

  @override
  Widget build(BuildContext context, TestViewModel model) {
    return MaterialApp(
        home: Flex(
      direction: Axis.vertical,
      children: <Widget>[
        Text('Hello ${model.someString}'),
        RaisedButton(
          key: const Key('changeSomeString'),
          onPressed: () => model.someString = 'changed',
        )
      ],
    ));
  }
}

void main() {
  testWidgets('rerender on set props', (WidgetTester tester) async {
    var fixture = TestWidget();
    await tester.pumpWidget(fixture);

    print(tester.allWidgets);
    expect(find.text('Hello original'), findsOneWidget);

    await tester.tap(find.byType(RaisedButton));
    await tester.pumpAndSettle();

    expect(find.text('Hello changed'), findsOneWidget);
  });
}
