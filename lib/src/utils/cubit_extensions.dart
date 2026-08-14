import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../contracts/all_contracts.dart';

/// Extension on [Cubit] to provide tryOperation functionality.
///
/// This extension provides easy access to the TryOperation functionality
/// for any Cubit that uses IUiFlowState. Extensions can't be overridden, so
/// this variant has no error-side-effect hook — use [TryOperationMixin] or
/// [TryOperationCubit] if you need [onOperationError].
extension TryOperationExtension<S extends IUiFlowState> on Cubit<S> {
  /// Executes an operation with automatic state management.
  ///
  /// This method automatically handles:
  /// - Loading state emission (optional)
  /// - Success state emission (from action result)
  /// - Error state emission (errors are captured in state, not rethrown)
  ///
  /// Usage:
  /// ```dart
  /// await tryOperation(() async {
  ///   final data = await repository.loadData();
  ///   return state.copyWith(
  ///     status: UiFlowStatus.success,
  ///     data: data,
  ///     error: null,
  ///   );
  /// });
  /// ```
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    bool emitLoading = false,
  }) async {
    try {
      // Optionally emit loading state
      if (emitLoading) {
        emit(state.withLoading() as S);
      }

      // Execute action and emit success state
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      // Emit error state
      emit(state.withError(error) as S);

      // Error is now in state - no need to rethrow
    }
  }
}

/// Mixin that provides TryOperation functionality for Cubits.
///
/// Use this when you want to add tryOperation functionality but can't use
/// the extension due to inheritance constraints.
mixin TryOperationMixin<S extends IUiFlowState> on Cubit<S> {
  /// Executes an operation with automatic state management.
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    bool emitLoading = false,
  }) async {
    try {
      if (emitLoading) {
        emit(createLoadingState());
      }
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      emit(createErrorState(error));
      onOperationError(error, stackTrace);
      // Error is now in state - no need to rethrow
    }
  }

  /// Creates loading state from current state.
  /// Delegates to [IUiFlowState.withLoading]; override to customize further.
  S createLoadingState() => state.withLoading() as S;

  /// Creates error state from current state and error.
  /// Delegates to [IUiFlowState.withError]; override to customize further.
  S createErrorState(Object error) => state.withError(error) as S;

  /// Called after an operation's error state has been emitted. No-op by
  /// default — override to add a side effect (logging, diagnostics capture,
  /// etc.) without duplicating [tryOperation]'s try/catch/emit control flow.
  void onOperationError(Object error, StackTrace stackTrace) {}
}

/// Base Cubit class that provides TryOperation functionality.
///
/// Provides automatic state management for UI flow patterns.
/// Use this as your base class for Cubits that need tryOperation functionality.
abstract class TryOperationCubit<S extends IUiFlowState> extends Cubit<S> {
  TryOperationCubit(super.initialState);

  /// Executes an operation with automatic state management.
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    bool emitLoading = false,
  }) async {
    try {
      if (emitLoading) {
        emit(createLoadingState());
      }
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      emit(createErrorState(error));
      onOperationError(error, stackTrace);
      // Error is now in state - no need to rethrow
    }
  }

  /// Creates loading state from current state.
  /// Delegates to [IUiFlowState.withLoading]; override to customize further.
  S createLoadingState() => state.withLoading() as S;

  /// Creates error state from current state and error.
  /// Delegates to [IUiFlowState.withError]; override to customize further.
  S createErrorState(Object error) => state.withError(error) as S;

  /// Called after an operation's error state has been emitted. No-op by
  /// default — override to add a side effect (logging, diagnostics capture,
  /// etc.) without duplicating [tryOperation]'s try/catch/emit control flow.
  void onOperationError(Object error, StackTrace stackTrace) {}
}
