import 'async_state.dart';
import 'message_key.dart';

/// Maps exceptions to message keys.
///
/// This is a GLOBAL mapper shared across all features.
/// Consumer app implements this once for all exception types.
///
/// Example:
/// ```dart
/// class AppExceptionKeyMapper implements IExceptionKeyMapper {
///   @override
///   MessageKey? map(Object exception) {
///     return switch (exception) {
///       NetworkException() => MessageKey.networkError,
///       AuthException() => const MessageKey.error('error.auth'),
///       _ => null, // Falls back to generic
///     };
///   }
/// }
/// ```
abstract class IExceptionKeyMapper {
  /// Returns a [MessageKey] for any exception.
  /// Returns null if exception is not recognized (falls back to generic).
  MessageKey? map(Object exception);
}

/// Maps domain states to message keys.
///
/// This is a FEATURE-SPECIFIC mapper.
/// Each feature implements this for its own state.
///
/// Example:
/// ```dart
/// class TrackerDomainMapper implements IDomainStateKeyMapper<TrackerState> {
///   @override
///   MessageKey? map(TrackerState state) {
///     if (state.isSuccess && state.lastAction == TrackerAction.created) {
///       return MessageKey.success('tracker.created', {'name': state.tracker?.name});
///     }
///     return null;
///   }
/// }
/// ```
abstract class IDomainStateKeyMapper<S extends IAsyncState> {
  /// Returns a [MessageKey] based on domain state.
  /// Returns null if no message should be shown.
  MessageKey? map(S state);
}

/// Orchestrates exception + domain mappers.
///
/// This is THE CONTRACT that [AsyncUiListener] depends on.
/// Library provides a default implementation [BaseStateMessageMapper].
abstract class IStateMessageMapper<S extends IAsyncState> {
  /// Maps a state to a [MessageKey].
  /// Handles both exceptions and domain-specific states.
  MessageKey? map(S state);
}
