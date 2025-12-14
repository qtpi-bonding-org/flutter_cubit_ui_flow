import 'package:flutter/foundation.dart';

import 'message_key.dart';

/// Data class representing a feedback message to display.
///
/// This contains the already-localized message string.
@immutable
class FeedbackMessage {
  /// The localized message to display.
  final String message;

  /// The type of message (determines styling).
  final MessageType type;

  /// How long to show the message.
  final Duration? duration;

  /// Callback when the message is tapped.
  final VoidCallback? onTap;

  /// Label for an optional action button.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  const FeedbackMessage({
    required this.message,
    required this.type,
    this.duration,
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  /// Creates an error feedback message.
  factory FeedbackMessage.error(String message, {Duration? duration}) =>
      FeedbackMessage(
        message: message,
        type: MessageType.error,
        duration: duration,
      );

  /// Creates a success feedback message.
  factory FeedbackMessage.success(String message, {Duration? duration}) =>
      FeedbackMessage(
        message: message,
        type: MessageType.success,
        duration: duration,
      );

  /// Creates an info feedback message.
  factory FeedbackMessage.info(String message, {Duration? duration}) =>
      FeedbackMessage(
        message: message,
        type: MessageType.info,
        duration: duration,
      );

  /// Creates a warning feedback message.
  factory FeedbackMessage.warning(String message, {Duration? duration}) =>
      FeedbackMessage(
        message: message,
        type: MessageType.warning,
        duration: duration,
      );
}

/// Shows user feedback (toasts, snackbars, etc.).
///
/// Library provides a default implementation [OverlayFeedbackService],
/// but consumer can provide their own (e.g., using a different toast library).
abstract class IFeedbackService {
  /// Shows a feedback message to the user.
  void show(FeedbackMessage message);

  /// Dismisses any currently displayed feedback message.
  void dismiss();
}
