import '../contracts/all_contracts.dart';

/// Default implementation of [IUiFlowService].
///
/// This service orchestrates:
/// - Translating message keys to localized strings
/// - Showing/hiding loading overlays
/// - Displaying feedback messages
///
/// Example:
/// ```dart
/// final uiService = UiFlowService(
///   localization: AppLocalizationService(),
///   feedback: OverlayFeedbackService(navigatorKey),
///   loading: OverlayLoadingService(navigatorKey),
/// );
/// ```
class UiFlowService implements IUiFlowService {
  final ILocalizationService _localization;
  final IFeedbackService _feedback;
  final ILoadingService _loading;

  UiFlowService({
    required ILocalizationService localization,
    required IFeedbackService feedback,
    required ILoadingService loading,
  })  : _localization = localization,
        _feedback = feedback,
        _loading = loading;

  @override
  void handleMessage(MessageKey key) {
    // Handle loading separately
    if (key.type == MessageType.loading) {
      showLoading();
      return;
    }

    // Hide loading for any non-loading message
    hideLoading();

    // Translate and show feedback
    final message = _localization.translate(key.key, args: key.args);
    _feedback.show(FeedbackMessage(message: message, type: key.type));
  }

  @override
  void showLoading() => _loading.show();

  @override
  void hideLoading() => _loading.hide();

  @override
  void handleState<S extends IUiFlowState>(
    S state,
    IStateMessageMapper<S> mapper,
  ) {
    // Handle loading state
    if (state.isLoading) {
      showLoading();
      return;
    }

    // Hide loading when not loading
    hideLoading();

    // Map state to message key
    final key = mapper.map(state);
    if (key != null) {
      handleMessage(key);
    }
  }
}
