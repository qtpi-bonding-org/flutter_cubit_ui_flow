/// Manages global loading overlay.
///
/// Library provides a default implementation [OverlayLoadingService],
/// but consumer can provide their own.
abstract class ILoadingService {
  /// Shows a global loading overlay.
  ///
  /// Displays a loading indicator that covers the entire screen
  /// to prevent user interaction during async operations.
  void show();

  /// Hides the currently displayed loading overlay.
  void hide();

  /// Checks if a loading overlay is currently displayed.
  bool get isLoading;
}
