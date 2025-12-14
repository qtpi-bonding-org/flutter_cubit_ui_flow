import 'package:flutter/foundation.dart';

/// Message types for UI feedback.
enum MessageType {
  error,
  success,
  info,
  warning,
  loading,
}

/// Represents a localization key with metadata.
///
/// This is the core abstraction that flows through the system.
/// Instead of passing raw strings, we pass [MessageKey] objects
/// that can be translated by the localization service.
@immutable
class MessageKey {
  /// The localization key.
  final String key;

  /// The type of message (determines styling and behavior).
  final MessageType type;

  /// Optional arguments for string interpolation.
  final Map<String, dynamic>? args;

  const MessageKey(this.key, this.type, [this.args]);

  // Convenience constructors
  const MessageKey.error(this.key, [this.args]) : type = MessageType.error;
  const MessageKey.success(this.key, [this.args]) : type = MessageType.success;
  const MessageKey.info(this.key, [this.args]) : type = MessageType.info;
  const MessageKey.warning(this.key, [this.args]) : type = MessageType.warning;
  const MessageKey.loading(this.key, [this.args]) : type = MessageType.loading;

  // Common keys (library provides defaults)
  static const genericError = MessageKey.error('async_ui.error.generic');
  static const genericSuccess = MessageKey.success('async_ui.success.generic');
  static const genericLoading = MessageKey.loading('async_ui.loading.generic');
  static const networkError = MessageKey.error('async_ui.error.network');
  static const timeoutError = MessageKey.error('async_ui.error.timeout');
  static const unknownError = MessageKey.error('async_ui.error.unknown');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageKey &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          type == other.type &&
          mapEquals(args, other.args);

  @override
  int get hashCode => Object.hash(key, type, args);

  @override
  String toString() => 'MessageKey($key, $type${args != null ? ', $args' : ''})';
}
