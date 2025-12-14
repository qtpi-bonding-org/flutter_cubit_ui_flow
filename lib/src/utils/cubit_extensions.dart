import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/async_state.dart';

/// Signature for error reporting callback.
typedef ErrorReporter = void Function(
  Object error,
  StackTrace stackTrace,
  String? context,
);

/// Base class for Cubits with built-in operation state management.
///
/// Provides a try-catch wrapper with automatic state emission.
/// Handles both sync and async operations.
/// Can be inherited and customized for specific needs.
///
/// Example:
/// ```dart
/// class TrackerCubit extends TryOperationCubit<TrackerState> {
///   TrackerCubit() : super(const TrackerState());
///
///   // Async operation
///   Future<void> loadTrackers() async {
///     await tryOperation(() async {
///       final trackers = await _repository.getAll();
///       return state.copyWith(
///         status: AsyncStatus.success,
///         trackers: trackers,
///       );
///     });
///   }
///
///   // Sync operation
///   Future<void> clearTrackers() async {
///     await tryOperation(() {
///       return state.copyWith(
///         status: AsyncStatus.success,
///         trackers: [],
///       );
///     });
///   }
/// }
/// ```
abstract class TryOperationCubit<S extends IAsyncState> extends Cubit<S> {
  TryOperationCubit(super.initialState);

  /// Executes an operation with automatic state management.
  ///
  /// 1. Emits loading state
  /// 2. Executes action (sync or async)
  /// 3. Emits success state returned by action
  /// 4. On error: emits error state
  ///
  /// [action] Function that returns the success state
  /// [errorReporter] Optional error reporting callback
  /// [context] Optional context for error reporting
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    ErrorReporter? errorReporter,
    String? context,
  }) async {
    try {
      // Emit loading state
      emit(createLoadingState());

      // Execute action and emit success state
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      // Emit error state
      emit(createErrorState(error));

      // Report error if reporter provided
      errorReporter?.call(error, stackTrace, context ?? runtimeType.toString());
    }
  }

  /// Creates loading state from current state.
  /// Override to customize loading state creation.
  S createLoadingState() {
    // Default implementation - assumes copyWith pattern
    return (state as dynamic).copyWith(status: AsyncStatus.loading) as S;
  }

  /// Creates error state from current state and error.
  /// Override to customize error state creation.
  S createErrorState(Object error) {
    // Default implementation - assumes copyWith pattern
    return (state as dynamic).copyWith(
      status: AsyncStatus.failure,
      error: error,
    ) as S;
  }
}

/// Mixin version for when you can't extend TryOperationCubit.
///
/// Example:
/// ```dart
/// class TrackerCubit extends Cubit<TrackerState> with TryOperationMixin<TrackerState> {
///   // Async operation
///   Future<void> loadTrackers() async {
///     await tryOperation(() async {
///       final trackers = await _repository.getAll();
///       return state.copyWith(
///         status: AsyncStatus.success,
///         trackers: trackers,
///       );
///     });
///   }
///
///   // Sync operation
///   Future<void> clearTrackers() async {
///     await tryOperation(() {
///       return state.copyWith(
///         status: AsyncStatus.success,
///         trackers: [],
///       );
///     });
///   }
/// }
/// ```
mixin TryOperationMixin<S extends IAsyncState> on Cubit<S> {
  /// Executes an operation with automatic state management.
  Future<void> tryOperation(
    FutureOr<S> Function() action, {
    ErrorReporter? errorReporter,
    String? context,
  }) async {
    try {
      // Emit loading state
      emit(createLoadingState());

      // Execute action and emit success state
      final successState = await action();
      emit(successState);
    } catch (error, stackTrace) {
      // Emit error state
      emit(createErrorState(error));

      // Report error if reporter provided
      errorReporter?.call(error, stackTrace, context ?? runtimeType.toString());
    }
  }

  /// Creates loading state from current state.
  /// Override to customize loading state creation.
  S createLoadingState() {
    return (state as dynamic).copyWith(status: AsyncStatus.loading) as S;
  }

  /// Creates error state from current state and error.
  /// Override to customize error state creation.
  S createErrorState(Object error) {
    return (state as dynamic).copyWith(
      status: AsyncStatus.failure,
      error: error,
    ) as S;
  }
}

/// Helper class for running operations outside of a Cubit.
///
/// Useful for one-off operations or when you need more control.
class TryOperationRunner {
  /// Executes an async action with error handling.
  ///
  /// Returns the result of the action, or null if an error occurred.
  static Future<T?> run<T>({
    required Future<T> Function() action,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      onError?.call(error, stackTrace);
      return null;
    }
  }

  /// Executes an async action and returns a Result.
  static Future<Result<T>> runWithResult<T>({
    required Future<T> Function() action,
  }) async {
    try {
      final value = await action();
      return Result.success(value);
    } catch (error, stackTrace) {
      return Result.failure(error, stackTrace);
    }
  }
}

/// Simple Result type for async operations.
sealed class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Object error, [StackTrace? stackTrace]) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T> s => s.value,
        Failure<T> _ => null,
      };

  Object? get errorOrNull => switch (this) {
        Success<T> _ => null,
        Failure<T> f => f.error,
      };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;
  const Failure(this.error, [this.stackTrace]);
}
