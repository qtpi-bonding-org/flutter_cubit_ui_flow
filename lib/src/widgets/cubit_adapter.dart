import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/all_contracts.dart';

/// Stateful presentation boundary between a Cubit and dumb widgets.
///
/// Selector functions must be static or top-level tear-offs. Their identity is
/// used as the memoization key, so each selector gets one notifier and one
/// subscription for the lifetime of this adapter.
abstract class CubitAdapter<C extends Cubit<S>, S> extends StatefulWidget {
  const CubitAdapter({super.key});

  @override
  State<CubitAdapter<C, S>> createState() => _CubitAdapterState<C, S>();

  Widget buildAdapter(
    BuildContext context,
    CubitAdapterState<C, S> adapter,
  );

  /// Releases UI-owned resources held by the adapter widget.
  @mustCallSuper
  void disposeAdapter() {}
}

abstract class CubitAdapterState<C extends Cubit<S>, S>
    extends State<CubitAdapter<C, S>> {
  ValueListenable<T> cubitField<T>(T Function(S) selector);
  ValueListenable<UiFlowStatus> cubitStatus();
  ValueListenable<Object?> cubitError();
  void listenTo<T>(
      Object key, ValueListenable<T> listenable, VoidCallback listener);
}

class _CubitAdapterState<C extends Cubit<S>, S>
    extends CubitAdapterState<C, S> {
  final _cache = <Object, ValueNotifier<Object?>>{};
  final _subscriptions = <StreamSubscription<S>>[];
  final _valueListeners = <Object, (Listenable, VoidCallback)>{};

  ValueListenable<T> cubitField<T>(T Function(S) selector) {
    final key = selector;
    final cached = _cache[key];
    if (cached != null) return cached as ValueListenable<T>;

    final cubit = context.read<C>();
    final notifier = ValueNotifier<T>(selector(cubit.state));
    _cache[key] = notifier as ValueNotifier<Object?>;
    _subscriptions.add(cubit.stream.listen((state) {
      final next = selector(state);
      if (notifier.value != next) notifier.value = next;
    }));
    return notifier;
  }

  ValueListenable<UiFlowStatus> cubitStatus() => cubitField<UiFlowStatus>(
        _selectStatus as UiFlowStatus Function(S),
      );

  ValueListenable<Object?> cubitError() => cubitField<Object?>(
        _selectError as Object? Function(S),
      );

  @override
  void listenTo<T>(
      Object key, ValueListenable<T> listenable, VoidCallback listener) {
    if (_valueListeners.containsKey(key)) return;
    listenable.addListener(listener);
    _valueListeners[key] = (listenable, listener);
  }

  static UiFlowStatus _selectStatus(Object state) =>
      (state as IUiFlowState).status;

  static Object? _selectError(Object state) => (state as IUiFlowState).error;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final notifier in _cache.values) {
      notifier.dispose();
    }
    for (final (listenable, listener) in _valueListeners.values) {
      listenable.removeListener(listener);
    }
    widget.disposeAdapter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.buildAdapter(context, this);
}
