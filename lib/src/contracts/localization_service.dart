/// Translates message keys to localized strings.
///
/// Consumer app MUST implement this to connect the library
/// to their localization system.
///
/// Example:
/// ```dart
/// class AppLocalizationService implements ILocalizationService {
///   final AppLocalizations Function() _getL10n;
///
///   AppLocalizationService(this._getL10n);
///
///   @override
///   String translate(String key, {Map<String, dynamic>? args}) {
///     final l10n = _getL10n();
///     return switch (key) {
///       'async_ui.error.generic' => l10n.errorGeneric,
///       'async_ui.error.network' => l10n.errorNetwork,
///       'tracker.created' => l10n.trackerCreated(args?['name'] ?? ''),
///       _ => key,
///     };
///   }
///
///   @override
///   bool hasKey(String key) => true;
/// }
/// ```
abstract class ILocalizationService {
  /// Translates a key to a localized string.
  ///
  /// [key] The message key to translate.
  /// [args] Optional arguments for string interpolation.
  String translate(String key, {Map<String, dynamic>? args});

  /// Checks if a key exists in the localization system.
  ///
  /// Used for fallback handling when a key is not found.
  bool hasKey(String key);
}

/// A simple fallback localization service that returns keys as-is.
///
/// Useful for testing or when localization is not yet set up.
class FallbackLocalizationService implements ILocalizationService {
  const FallbackLocalizationService();

  @override
  String translate(String key, {Map<String, dynamic>? args}) {
    if (args == null || args.isEmpty) return key;

    // Simple interpolation: replace {key} with value
    var result = key;
    args.forEach((k, v) {
      result = result.replaceAll('{$k}', v.toString());
    });
    return result;
  }

  @override
  bool hasKey(String key) => false;
}
