import 'async_state.dart';
import 'mappers.dart';
import 'message_key.dart';

/// The "Boss" - coordinates all UI feedback.
///
/// This service orchestrates:
/// - Translating message keys to localized strings
/// - Showing/hiding loading overlays
/// - Displaying feedback messages (toasts, snackbars)
///
/// Library provides a default implementation [GlobalUiService].
abstract class IGlobalUiService {
  /// Handles a message key: translates → decides action → executes.
  void handleMessage(MessageKey key);

  /// Shows loading overlay.
  void showLoading();

  /// Hides loading overlay.
  void hideLoading();

  /// Convenience: handle state directly using a mapper.
  ///
  /// This is useful when you want to handle state changes
  /// without using [AsyncUiListener].
  void handleState<S extends IAsyncState>(S state, IStateMessageMapper<S> mapper);
}
