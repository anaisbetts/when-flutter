import 'package:rxdart/rxdart.dart';

Future<void> makeRxDartWork() {
  return Future<void>.delayed(Duration(milliseconds: 20));
}

List<T> createCollection<T>(Observable<T> source) {
  final ret = <T>[];
  source.listen(ret.add);

  return ret;
}
