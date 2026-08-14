import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

// A flat, single-shape state relying on UiFlowStateMixin's default
// withLoading()/withError() (dynamic copyWith over status/error/data).
class _FlatState with UiFlowStateMixin {
  const _FlatState({
    this.status = UiFlowStatus.idle,
    this.error,
    this.items = const <String>[],
  });

  @override
  final UiFlowStatus status;
  @override
  final Object? error;
  final List<String> items;

  _FlatState copyWith({
    UiFlowStatus? status,
    Object? error,
    List<String>? items,
  }) =>
      _FlatState(
        status: status ?? this.status,
        error: error ?? this.error,
        items: items ?? this.items,
      );
}

class _FlatCubit extends TryOperationCubit<_FlatState> {
  _FlatCubit() : super(const _FlatState());

  Future<void> loadOk() => tryOperation(
        () async => state.copyWith(status: UiFlowStatus.success, items: const ['a']),
        emitLoading: true,
      );

  Future<void> loadFails() => tryOperation(
        () async => throw Exception('boom'),
        emitLoading: true,
      );
}

// A union-shaped state (the pattern that crashed under the old dynamic
// `copyWith(status:, error:)` call) with hand-written withLoading/withError.
sealed class _UnionState implements IUiFlowState {
  const _UnionState();

  const factory _UnionState.initial() = _UInitial;
  const factory _UnionState.loading() = _ULoading;
  const factory _UnionState.loaded(List<String> items) = _ULoaded;
  const factory _UnionState.error(String message) = _UError;

  @override
  UiFlowStatus get status => switch (this) {
        _UInitial() => UiFlowStatus.idle,
        _ULoading() => UiFlowStatus.loading,
        _ULoaded() => UiFlowStatus.success,
        _UError() => UiFlowStatus.failure,
      };

  @override
  Object? get error => switch (this) {
        _UError(:final message) => message,
        _ => null,
      };

  @override
  IUiFlowState withLoading() => const _UnionState.loading();

  @override
  IUiFlowState withError(Object error) => _UnionState.error(error.toString());

  @override
  bool get isIdle => status == UiFlowStatus.idle;
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  @override
  bool get hasError => error != null;
}

class _UInitial extends _UnionState {
  const _UInitial();
}

class _ULoading extends _UnionState {
  const _ULoading();
}

class _ULoaded extends _UnionState {
  const _ULoaded(this.items);
  final List<String> items;
}

class _UError extends _UnionState {
  const _UError(this.message);
  final String message;
}

class _UnionCubit extends TryOperationCubit<_UnionState> {
  _UnionCubit() : super(const _UnionState.initial());

  Future<void> loadOk() => tryOperation(
        () async => const _UnionState.loaded(['a']),
        emitLoading: true,
      );

  Future<void> loadFails() => tryOperation(
        () async => throw Exception('boom'),
        emitLoading: true,
      );
}

void main() {
  group('tryOperation over a flat UiFlowStateMixin state', () {
    test('emits loading then success', () async {
      final cubit = _FlatCubit();
      final states = <_FlatState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.loadOk();
      await pumpEventQueue();
      await sub.cancel();
      expect(states.map((s) => s.status),
          [UiFlowStatus.loading, UiFlowStatus.success]);
      expect(states.last.items, ['a']);
      await cubit.close();
    });

    test('emits loading then failure, error captured, not rethrown', () async {
      final cubit = _FlatCubit();
      final states = <_FlatState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.loadFails();
      await pumpEventQueue();
      await sub.cancel();
      expect(states.map((s) => s.status),
          [UiFlowStatus.loading, UiFlowStatus.failure]);
      expect(states.last.error, isA<Exception>());
      await cubit.close();
    });
  });

  group('tryOperation over a sealed-union state with custom withLoading/withError', () {
    test('emits loading then loaded — does not crash on dynamic copyWith', () async {
      final cubit = _UnionCubit();
      final states = <_UnionState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.loadOk();
      await pumpEventQueue();
      await sub.cancel();
      expect(states.map((s) => s.status),
          [UiFlowStatus.loading, UiFlowStatus.success]);
      expect((states.last as _ULoaded).items, ['a']);
      await cubit.close();
    });

    test('emits loading then error variant, error captured, not rethrown', () async {
      final cubit = _UnionCubit();
      final states = <_UnionState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.loadFails();
      await pumpEventQueue();
      await sub.cancel();
      expect(states.map((s) => s.status),
          [UiFlowStatus.loading, UiFlowStatus.failure]);
      expect(states.last.error, contains('boom'));
      await cubit.close();
    });
  });
}
