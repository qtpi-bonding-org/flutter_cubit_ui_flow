import 'ui_flow_status.dart';

abstract class IUiFlowState {
  UiFlowStatus get status;
  Object? get error;
  
  bool get isIdle => status == UiFlowStatus.idle;
  bool get isLoading => status == UiFlowStatus.loading;
  bool get isSuccess => status == UiFlowStatus.success;
  bool get isFailure => status == UiFlowStatus.failure;
  bool get hasError => error != null;
}

abstract class IUiFlowService {
  void handleMessage(dynamic key);
  void showLoading();
  void hideLoading();
}