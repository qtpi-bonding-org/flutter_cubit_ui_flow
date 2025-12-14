// Pure Dart test without Flutter dependencies
import 'package:cubit_ui_flow/src/contracts/async_state.dart';
import 'package:cubit_ui_flow/src/contracts/message_key.dart';
import 'package:cubit_ui_flow/src/contracts/localization_service.dart';
import 'package:cubit_ui_flow/src/impl/base_state_mapper.dart';

void main() {
  print('=== Pure Dart Test ===');
  
  // Test AsyncStatus
  print('✓ AsyncStatus.idle.isIdle: ${AsyncStatus.idle.isIdle}');
  print('✓ AsyncStatus.loading.isLoading: ${AsyncStatus.loading.isLoading}');
  print('✓ AsyncStatus.success.isComplete: ${AsyncStatus.success.isComplete}');
  
  // Test MessageKey
  const errorKey = MessageKey.error('test.error');
  const successKey = MessageKey.success('test.success', {'count': 5});
  print('✓ Error key: ${errorKey.key} (${errorKey.type})');
  print('✓ Success key: ${successKey.key} (${successKey.type}) args: ${successKey.args}');
  
  // Test equality
  const errorKey2 = MessageKey.error('test.error');
  print('✓ MessageKey equality: ${errorKey == errorKey2}');
  
  // Test FallbackLocalizationService
  const localization = FallbackLocalizationService();
  final translated = localization.translate('hello.{name}', args: {'name': 'world'});
  print('✓ Localized: $translated');
  print('✓ Has key: ${localization.hasKey('anything')}');
  
  // Test DefaultExceptionKeyMapper
  const exceptionMapper = DefaultExceptionKeyMapper();
  final networkKey = exceptionMapper.map(Exception('Network error'));
  print('✓ Exception mapped: ${networkKey?.key ?? 'null'}');
  
  // Test BaseStateMessageMapper
  final mapper = BaseStateMessageMapper<TestState>(
    exceptionMapper: exceptionMapper,
  );
  
  final errorState = TestState(
    status: AsyncStatus.failure,
    error: Exception('Test error'),
  );
  
  final mappedKey = mapper.map(errorState);
  print('✓ Mapped error state: ${mappedKey?.key ?? 'null'}');
  
  print('✅ All pure Dart functionality works!');
}

// Test state implementation
class TestState with AsyncStateMixin {
  @override
  final AsyncStatus status;
  
  @override
  final Object? error;
  
  const TestState({
    this.status = AsyncStatus.idle,
    this.error,
  });
}