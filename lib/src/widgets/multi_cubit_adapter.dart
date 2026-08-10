import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'adapter_scope.dart';
import '../contracts/all_contracts.dart';

/// Adapter for screens with multiple explicitly supplied Cubit sources.
/// Unlike [CubitAdapter], which resolves one implicit primary Cubit with
/// `context.read<C>()`, each source is normally a constructor field:
///
/// ```dart
/// class GraphTabAdapter extends MultiCubitAdapter {
///   const GraphTabAdapter({super.key, required this.readiness, required this.graph});
///   final AppReadinessCubit readiness;
///   final GraphCubit graph;
///   @override
///   Widget buildAdapter(BuildContext context, AdapterScope scope) {
///     final gate = scope.cubitField(readiness, _selectGate);
///     return ...;
///   }
/// }
/// ```
abstract class MultiCubitAdapter extends StatefulWidget {
  const MultiCubitAdapter({super.key});

  @override
  State<MultiCubitAdapter> createState() => _MultiCubitAdapterState();

  Widget buildAdapter(BuildContext context, AdapterScope scope);
}

class _MultiCubitAdapterState extends State<MultiCubitAdapter>
    implements AdapterScope {
  final AdapterScopeImpl _scope = AdapterScopeImpl();

  @override
  ValueListenable<T> cubitField<S, T>(StateStreamable<S> cubit, T Function(S) selector) =>
      _scope.cubitField(cubit, selector);
  @override
  ValueListenable<UiFlowStatus> cubitStatus(StateStreamable<IUiFlowState> cubit) =>
      _scope.cubitStatus(cubit);
  @override
  ValueListenable<Object?> cubitError(StateStreamable<IUiFlowState> cubit) =>
      _scope.cubitError(cubit);
  @override
  void listenToCubit<S>(Object key, StateStreamable<S> cubit, void Function(S state) listener) =>
      _scope.listenToCubit(key, cubit, listener);
  @override
  void listenToTransition<S>(Object key, StateStreamable<S> cubit, void Function(S previous, S current) listener) =>
      _scope.listenToTransition(key, cubit, listener);
  @override
  void listenTo<T>(Object key, ValueListenable<T> listenable, VoidCallback listener) =>
      _scope.listenTo(key, listenable, listener);
  @override
  ValueListenable<R> combine2<A, B, R>(ValueListenable<A> a, ValueListenable<B> b, R Function(A, B) combine) =>
      _scope.combine2(a, b, combine);
  @override
  ValueListenable<R> combine3<A, B, C, R>(ValueListenable<A> a, ValueListenable<B> b, ValueListenable<C> c, R Function(A, B, C) combine) =>
      _scope.combine3(a, b, c, combine);
  @override
  T keep<T extends Object>(Object key, T Function() create, {void Function(T value)? dispose}) =>
      _scope.keep(key, create, dispose: dispose);

  @override
  Widget build(BuildContext context) => widget.buildAdapter(context, this);

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }
}
