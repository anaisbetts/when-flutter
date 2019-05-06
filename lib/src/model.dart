import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:quiver/core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:when_rx/src/bindable_state.dart';

@immutable
class ChangeNotification {
  final String property;
  final dynamic value;
  final dynamic previousValue;

  const ChangeNotification(this.property, this.value, this.previousValue);

  @override
  String toString() => '$property = $value';

  @override
  bool operator ==(dynamic other) =>
      other is ChangeNotification &&
      other.property == property &&
      other.value == value;

  @override
  int get hashCode => hash2(property.hashCode, value.hashCode);
}

typedef Setter = dynamic Function();

abstract class ViewModel {
  final PublishSubject<ChangeNotification> _changed =
      PublishSubject(sync: true);
  final PublishSubject<String> _accessed = PublishSubject(sync: true);

  Observable<ChangeNotification> get changed => _changed;
  Observable<String> get accessed => _accessed;

  void notifyAndSet(String property, dynamic oldValue, Setter newSetter) {
    // ignore: omit_local_variable_types
    final dynamic newValue = newSetter();

    if (oldValue == newValue) {
      return;
    }

    _changed.add(ChangeNotification(property, newValue, oldValue));
  }

  T notifyAccessed<T>(String property, T value) {
    _accessed.add(property);
    return value;
  }

  void dispose() {
    _changed.close();
    _accessed.close();
  }

  Observable<ChangeNotification> when(List<String> props) {
    if (props.length == 1) {
      final item = props[0];
      return changed.where((c) => c.property == item);
    }

    final itemSet = Set<String>.from(props);
    return changed.where(itemSet.contains);
  }
}

typedef S ItemCreator<S>();
typedef ModelSubscriber<T> = StreamSubscription<dynamic> Function(T);

abstract class ViewModelWidget<T extends ViewModel> extends StatefulWidget {
  final ItemCreator<T> factory;
  ViewModelWidget(this.factory) : super();

  final List<ModelSubscriber<T>> binder = [];

  @override
  _ViewModelWidgetState<T> createState() =>
      _ViewModelWidgetState(factory, binder);

  void watch(dynamic value) {}

  @protected
  Widget build(BuildContext context, T model);

  void setupBinds(List<ModelSubscriber<T>> bindFunc) => binder.addAll(bindFunc);
}

class _ViewModelWidgetState<T extends ViewModel>
    extends BindableState<ViewModelWidget<T>> {
  @protected
  T model;
  StreamSubscription _vmChanged;

  _ViewModelWidgetState(
      ItemCreator<T> factory, List<ModelSubscriber<T>> binder) {
    model = factory();

    if (binder != null) {
      setupBinds(binder.map((b) => () => b(model)).toList());
    }
  }

  @override
  void dispose() {
    super.dispose();
    model.dispose();
    _vmChanged?.cancel();
  }

  @override
  Widget build(context) {
    if (_vmChanged != null) {
      return widget.build(context, model);
    }

    // ignore: prefer_collection_literals
    var propsThatAffectBuild = Set<String>();
    var sub = model.accessed.listen((k) => propsThatAffectBuild.add(k));

    Widget ret;
    try {
      ret = widget.build(context, model);
    } finally {
      sub.cancel();
    }

    _vmChanged = model.changed
        .where((c) => propsThatAffectBuild.contains(c.property))
        .listen((_) => setState(() {}));

    return ret;
  }
}
