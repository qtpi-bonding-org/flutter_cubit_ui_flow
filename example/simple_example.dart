// Simple Dart example of cubit_ui_flow library
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

void main() {
  print('=== cubit_ui_flow Library Test ===');
  
  // Test UiFlowStatus
  print('UiFlowStatus.idle.isIdle: ${UiFlowStatus.idle.isIdle}');
  print('UiFlowStatus.loading.isLoading: ${UiFlowStatus.loading.isLoading}');
  print('UiFlowStatus.success.isComplete: ${UiFlowStatus.success.isComplete}');
  
  // Test MessageKey
  const errorKey = MessageKey.error('test.error');
  const successKey = MessageKey.success('test.success', {'count': 5});
  print('Error key: ${errorKey.key} (${errorKey.type})');
  print('Success key: ${successKey.key} (${successKey.type}) args: ${successKey.args}');
  
  // Test FallbackLocalizationService
  const localization = FallbackLocalizationService();
  print('Localized: ${localization.translate('hello.{name}', args: {'name': 'world'})}');
  
  // Test DefaultExceptionKeyMapper
  const exceptionMapper = DefaultExceptionKeyMapper();
  final networkKey = exceptionMapper.map(Exception('Network error'));
  print('Exception mapped: ${networkKey?.key ?? 'null'}');
  
  print('✅ All basic functionality works!');
}