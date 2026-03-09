import 'package:flutter/foundation.dart';

// UI Flow State
enum UiFlowStatus {
  idle,
  loading,
  success,
  failure,
}

extension UiFlowStatusExtension on UiFlowStatus {
  bool get isIdle => this == UiFlowStatus.idle;
  bool get isLoading => this == UiFlowStatus.loading;
  bool get isSuccess => this == UiFlowStatus.success;
  bool get isFailure => this == UiFlowStatus.failure;
}

abstract class IUiFlowState {
  UiFlowStatus get status;
  Object? get error;
  
  bool get isIdle => status == UiFlowStatus.idle;
  bool get isLoading => status == UiFlowStatus.loading;
  bool get isSuccess => status == UiFlowStatus.success;
  bool get isFailure => status == UiFlowStatus.failure;
  bool get hasError => error != null;
}

mixin UiFlowStateMixin implements IUiFlowState {
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  
  @override
  bool get hasError => error != null;
}

// Message Key
enum MessageType {
  info,
  success,
  warning,
  error,
  loading,
}

@immutable
class MessageKey {
  final String key;
  final MessageType type;
  final Map<String, dynamic>? args;

  const MessageKey._(this.key, this.type, [this.args]);

  const MessageKey.info(this.key, [this.args]) : type = MessageType.info;
  const MessageKey.success(this.key, [this.args]) : type = MessageType.success;
  const MessageKey.warning(this.key, [this.args]) : type = MessageType.warning;
  const MessageKey.error(this.key, [this.args]) : type = MessageType.error;
  const MessageKey.loading(this.key, [this.args]) : type = MessageType.loading;

  /// Factories that accept typed (key, args) records from L10nKeys.
  MessageKey.infoFrom((String, Map<String, dynamic>) record)
      : key = record.$1, args = record.$2, type = MessageType.info;
  MessageKey.successFrom((String, Map<String, dynamic>) record)
      : key = record.$1, args = record.$2, type = MessageType.success;
  MessageKey.warningFrom((String, Map<String, dynamic>) record)
      : key = record.$1, args = record.$2, type = MessageType.warning;
  MessageKey.errorFrom((String, Map<String, dynamic>) record)
      : key = record.$1, args = record.$2, type = MessageType.error;
  MessageKey.loadingFrom((String, Map<String, dynamic>) record)
      : key = record.$1, args = record.$2, type = MessageType.loading;

  static const MessageKey genericError = MessageKey._('error.generic', MessageType.error);
  static const MessageKey genericSuccess = MessageKey._('success.generic', MessageType.success);
  static const MessageKey networkError = MessageKey._('error.network', MessageType.error);
  static const MessageKey timeoutError = MessageKey._('error.timeout', MessageType.error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageKey &&
        other.key == key &&
        other.type == type &&
        mapEquals(other.args, args);
  }

  @override
  int get hashCode => Object.hash(key, type, args);

  @override
  String toString() => 'MessageKey(key: $key, type: $type, args: $args)';
}

// Mappers
abstract class IExceptionKeyMapper {
  MessageKey? map(Object exception);
}

abstract class IDomainStateKeyMapper<S extends IUiFlowState> {
  MessageKey? map(S state);
}

abstract class IStateMessageMapper<S extends IUiFlowState> {
  MessageKey? map(S state);
}

// Services
abstract class ILocalizationService {
  String translate(String key, {Map<String, dynamic>? args});
}

@immutable
class FeedbackMessage {
  final String message;
  final MessageType type;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const FeedbackMessage({
    required this.message,
    required this.type,
    this.onTap,
    this.onDismiss,
  });
}

abstract class IFeedbackService {
  void show(FeedbackMessage message);
}

abstract class ILoadingService {
  void show();
  void hide();
}

abstract class IUiFlowService {
  void handleMessage(MessageKey key);
  void showLoading();
  void hideLoading();
  void handleState<S extends IUiFlowState>(S state, IStateMessageMapper<S> mapper);
}