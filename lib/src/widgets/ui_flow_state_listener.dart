import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/all_contracts.dart';

/// Reusable BlocListener that handles state → UI feedback flow.
///
/// This widget wraps your screen content and automatically handles:
/// - Loading overlays (via [IUiFlowService])
/// - Error toasts (via mapper → [IUiFlowService])
/// - Success notifications (optional)
///
/// Example:
/// ```dart
/// UiFlowStateListener<TrackerCubit, TrackerState>(
///   mapper: BaseStateMessageMapper(
///     exceptionMapper: getIt<IExceptionKeyMapper>(),
///     domainMapper: TrackerDomainMapper(),
///   ),
///   uiService: getIt<IUiFlowService>(),
///   onStateChanged: (context, state) {
///     if (state.shouldNavigateBack) Navigator.pop(context);
///   },
///   child: TrackerScreen(),
/// )
/// ```
class UiFlowStateListener<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  /// The child widget to wrap.
  final Widget child;

  /// The mapper that converts state to message keys.
  final IStateMessageMapper<S> mapper;

  /// The UI service that handles messages.
  final IUiFlowService uiService;

  /// Optional specific bloc instance to listen to.
  final B? bloc;

  /// Optional custom listener for additional state-specific logic.
  final void Function(BuildContext context, S state)? onStateChanged;

  /// Custom condition for when to trigger the listener.
  final bool Function(S previous, S current)? listenWhen;

  /// Whether to show loading overlay during loading states.
  final bool showLoadingOverlay;

  /// Whether to show success messages.
  final bool showSuccessMessages;

  /// Optional service that displays a determinate progress bar.
  /// When provided and the state implements [IUiFlowProgressState] with a
  /// non-null progress value, the progress bar is shown instead of the
  /// generic loading overlay.
  final IProgressService? progressService;

  /// Optional label to forward to the progress bar when the state does not
  /// supply its own.
  final String? progressLabel;

  const UiFlowStateListener({
    super.key,
    required this.child,
    required this.mapper,
    required this.uiService,
    this.bloc,
    this.onStateChanged,
    this.listenWhen,
    this.showLoadingOverlay = true,
    this.showSuccessMessages = false,
    this.progressService,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      bloc: bloc,
      listenWhen: listenWhen ?? _defaultListenWhen,
      listener: (context, state) {
        // Handle loading
        if (showLoadingOverlay) {
          final p = state is IUiFlowProgressState
              ? (state as IUiFlowProgressState).progress
              : null;
          if (state.isLoading && p != null) {
            progressService?.show(UiFlowProgress(
              label: progressLabel ?? p.label,
              current: p.current,
              total: p.total,
            ));
            uiService.hideLoading();
          } else if (state.isLoading) {
            uiService.showLoading();
            progressService?.hide();
          } else {
            uiService.hideLoading();
            progressService?.hide();
          }
        }

        // Handle messages (errors, success, etc.)
        if (!state.isLoading) {
          final key = mapper.map(state);
          if (key != null) {
            // Skip success messages if disabled
            if (key.type == MessageType.success && !showSuccessMessages) {
              // Don't show success message
            } else {
              uiService.handleMessage(key);
            }
          }
        }

        // Custom listener
        onStateChanged?.call(context, state);
      },
      child: child,
    );
  }

  bool _defaultListenWhen(S previous, S current) {
    final pp = previous is IUiFlowProgressState
        ? (previous as IUiFlowProgressState).progress
        : null;
    final cp = current is IUiFlowProgressState
        ? (current as IUiFlowProgressState).progress
        : null;
    return previous.status != current.status ||
        previous.error != current.error ||
        pp != cp;
  }
}

/// Convenience widget for screens that only need basic state listening.
///
/// This is a simplified version that uses a provided mapper factory.
class SimpleUiFlowStateListener<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  final Widget child;
  final IStateMessageMapper<S> mapper;
  final IUiFlowService uiService;
  final B? bloc;
  final bool showSuccessMessages;

  const SimpleUiFlowStateListener({
    super.key,
    required this.child,
    required this.mapper,
    required this.uiService,
    this.bloc,
    this.showSuccessMessages = false,
  });

  @override
  Widget build(BuildContext context) {
    return UiFlowStateListener<B, S>(
      bloc: bloc,
      mapper: mapper,
      uiService: uiService,
      showSuccessMessages: showSuccessMessages,
      child: child,
    );
  }
}

/// Builder widget that provides UI flow state information to its child.
///
/// Useful for widgets that need to conditionally render based on
/// state without triggering side effects.
class UiFlowStateBuilder<B extends StateStreamable<S>, S extends IUiFlowState>
    extends StatelessWidget {
  final Widget Function(BuildContext context, S state, Widget? child) builder;
  final Widget? child;
  final B? bloc;
  final bool Function(S previous, S current)? buildWhen;

  const UiFlowStateBuilder({
    super.key,
    required this.builder,
    this.child,
    this.bloc,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: buildWhen,
      builder: (context, state) => builder(context, state, child),
    );
  }
}
