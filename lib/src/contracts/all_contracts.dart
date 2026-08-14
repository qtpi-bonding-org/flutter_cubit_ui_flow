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

  /// The state to emit when an operation starts loading: same data,
  /// [status] transitioned to [UiFlowStatus.loading], [error] cleared.
  ///
  /// Called by [TryOperationCubit]/[TryOperationMixin]/[TryOperationExtension]
  /// instead of guessing at a `copyWith(status:, error:)` shape via a dynamic
  /// call — implement this explicitly so the compiler (not a runtime
  /// `NoSuchMethodError`) catches a state that can't represent loading.
  /// A flat, single-shape state normally mixes in [UiFlowStateMixin] and
  /// gets this for free; a sealed union overrides it to return its own
  /// `.loading()` variant.
  IUiFlowState withLoading();

  /// The state to emit when an operation fails: same data, [status]
  /// transitioned to [UiFlowStatus.failure], carrying [error].
  ///
  /// See [withLoading] for why this exists as an explicit method rather
  /// than a dynamic `copyWith` call.
  IUiFlowState withError(Object error);

  bool get isIdle => status == UiFlowStatus.idle;
  bool get isLoading => status == UiFlowStatus.loading;
  bool get isSuccess => status == UiFlowStatus.success;
  bool get isFailure => status == UiFlowStatus.failure;
  bool get hasError => error != null;
}

mixin UiFlowStateMixin implements IUiFlowState {
  /// Default implementation for flat, single-shape states: relies on a
  /// generated/hand-written `copyWith({status, error, ...})` existing on
  /// the mixing-in class (true for every `@freezed` state with `@Default`
  /// fields, which is what this mixin is meant for). States that can't
  /// satisfy that shape — sealed unions, for instance — should implement
  /// [IUiFlowState] directly and override [withLoading]/[withError]
  /// themselves instead of using this mixin.
  @override
  IUiFlowState withLoading() => (this as dynamic)
      .copyWith(status: UiFlowStatus.loading, error: null) as IUiFlowState;

  @override
  IUiFlowState withError(Object error) => (this as dynamic)
      .copyWith(status: UiFlowStatus.failure, error: error) as IUiFlowState;

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
/// Determinate progress payload. total == 0 means indeterminate.
@immutable
class UiFlowProgress {
  final String? label;
  final int current;
  final int total;

  const UiFlowProgress({this.label, this.current = 0, this.total = 0});

  bool get isDeterminate => total > 0;
  double? get fraction => total > 0 ? current / total : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiFlowProgress &&
          other.label == label &&
          other.current == current &&
          other.total == total);

  @override
  int get hashCode => Object.hash(label, current, total);

  @override
  String toString() =>
      "UiFlowProgress(label: $label, current: $current, total: $total)";
}

/// Opt-in interface: states that report determinate progress.
/// Separate from IUiFlowState so existing states compile unchanged.
abstract class IUiFlowProgressState implements IUiFlowState {
  UiFlowProgress? get progress;
}

abstract class IProgressService {
  void show(UiFlowProgress progress);
  void hide();
}