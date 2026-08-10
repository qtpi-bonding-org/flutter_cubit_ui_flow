import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/all_contracts.dart';
import 'adapter_scope.dart';

/// Stateful presentation boundary between a Cubit and dumb widgets.
abstract class CubitAdapter<C extends Cubit<S>, S> extends StatefulWidget {
  const CubitAdapter({super.key});
  @override
  State<CubitAdapter<C, S>> createState() => _CubitAdapterState<C, S>();
  Widget buildAdapter(BuildContext context, CubitAdapterState<C, S> adapter);
  @mustCallSuper
  void disposeAdapter() {}
}

abstract class CubitAdapterState<C extends Cubit<S>, S>
    extends State<CubitAdapter<C, S>> {
  /// The primary Cubit resolved from the nearest provider.
  C get cubit;
  /// Shared scope used by this adapter's primary and secondary sources.
  AdapterScope get sources;
  T keep<T extends Object>(Object key, T Function() create,
      {void Function(T value)? dispose});

  ValueListenable<T> cubitField<T>(T Function(S) selector);
  ValueListenable<UiFlowStatus> cubitStatus();
  ValueListenable<Object?> cubitError();
  void listenTo<T>(Object key, ValueListenable<T> listenable, VoidCallback listener);
}

class _CubitAdapterState<C extends Cubit<S>, S>
    extends CubitAdapterState<C, S> {
  final AdapterScopeImpl _scope = AdapterScopeImpl();
  C? _primary;

  @override
  C get cubit => _primary ??= context.read<C>();

  @override
  AdapterScope get sources => _scope;

  @override
  T keep<T extends Object>(Object key, T Function() create,
          {void Function(T value)? dispose}) =>
      _scope.keep(key, create, dispose: dispose);

  @override
  ValueListenable<T> cubitField<T>(T Function(S) selector) =>
      _scope.cubitField<S, T>(cubit, selector);

  @override
  ValueListenable<UiFlowStatus> cubitStatus() =>
      _scope.cubitStatus(cubit as StateStreamable<IUiFlowState>);

  @override
  ValueListenable<Object?> cubitError() =>
      _scope.cubitError(cubit as StateStreamable<IUiFlowState>);

  @override
  void listenTo<T>(Object key, ValueListenable<T> listenable, VoidCallback listener) =>
      _scope.listenTo(key, listenable, listener);

  @override
  void dispose() {
    _scope.dispose();
    widget.disposeAdapter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.buildAdapter(context, this);
}
