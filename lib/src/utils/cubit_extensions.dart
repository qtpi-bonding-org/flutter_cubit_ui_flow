import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../contracts/all_contracts.dart';

/// Extension on [Cubit] to provide tryOperation functionality.
/// 
/// This extension provides easy access to the TryOperation functionality
/// for any Cubit that uses IUiFlowState.
extension TryOperationExtension<S extends IUiFlowState> on Cubit<S> {
  /// Executes an operation with automatic state management.
  /// 
  /// This method automatically handles:
  /// - Loading state emission (optional)
  /// - Success state emission (from action result)
  /// - Error state emission with proper error handling
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
        emit(_createLoadingState());
      }

      // Execute action and emit success state
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      // Emit error state
      emit(_createErrorState(error));
      
      // Re-throw for additional error handling if needed
      rethrow;
    }
  }

  /// Creates loading state from current state.
  /// Uses dynamic copyWith pattern for compatibility with Freezed states.
  S _createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  /// Creates error state from current state and error.
  /// Uses dynamic copyWith pattern for compatibility with Freezed states.
  S _createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
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
      rethrow;
    }
  }

  /// Creates loading state from current state.
  /// Override to customize loading state creation.
  S createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  /// Creates error state from current state and error.
  /// Override to customize error state creation.
  S createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
  }
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
      rethrow;
    }
  }

  /// Creates loading state from current state.
  /// Override to customize loading state creation.
  S createLoadingState() {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.loading,
      error: null,
    ) as S;
  }

  /// Creates error state from current state and error.
  /// Override to customize error state creation.
  S createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: UiFlowStatus.failure,
      error: error,
    ) as S;
  }
}