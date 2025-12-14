/// Status enum for async operations.
enum AsyncStatus {
  /// Idle state - no async operation in progress
  idle,

  /// Loading state - an async operation is in progress
  loading,

  /// Success state - the operation completed successfully
  success,

  /// Failure state - the operation failed with an error
  failure,
}

/// Extension methods for [AsyncStatus].
extension AsyncStatusX on AsyncStatus {
  bool get isIdle => this == AsyncStatus.idle;
  bool get isLoading => this == AsyncStatus.loading;
  bool get isSuccess => this == AsyncStatus.success;
  bool get isFailure => this == AsyncStatus.failure;
  bool get isComplete => isSuccess || isFailure;
}

/// Base interface all Cubit states must implement.
///
/// This interface ensures consistent state management across all Cubits
/// by providing standard properties for status and error tracking.
abstract class IAsyncState {
  /// The current status of async operations.
  AsyncStatus get status;

  /// Raw error object - NOT exposed to UI directly.
  /// Used by mappers to determine the appropriate message key.
  Object? get error;

  /// Convenience getter for checking if an operation is in progress.
  bool get isLoading => status.isLoading;

  /// Convenience getter for checking if the operation completed successfully.
  bool get isSuccess => status.isSuccess;

  /// Convenience getter for checking if the operation failed.
  bool get isFailure => status.isFailure;

  /// Convenience getter for checking if there's an error.
  bool get hasError => error != null;
}

/// Mixin for Freezed states to implement [IAsyncState].
///
/// Example usage:
/// ```dart
/// @freezed
/// class TrackerState with _$TrackerState, AsyncStateMixin {
///   const factory TrackerState({
///     @Default(AsyncStatus.initial) AsyncStatus status,
///     @Default([]) List<Tracker> trackers,
///     Object? error,
///   }) = _TrackerState;
/// }
/// ```
mixin AsyncStateMixin implements IAsyncState {
  @override
  AsyncStatus get status;

  @override
  Object? get error;

  @override
  bool get isLoading => status.isLoading;

  @override
  bool get isSuccess => status.isSuccess;

  @override
  bool get isFailure => status.isFailure;

  @override
  bool get hasError => error != null;
}
