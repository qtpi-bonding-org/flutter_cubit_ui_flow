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