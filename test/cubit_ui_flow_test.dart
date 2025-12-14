import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

void main() {
  group('cubit_ui_flow', () {
    test('exports all required classes', () {
      // Test that all main classes are exported
      expect(AsyncStatus.idle, isA<AsyncStatus>());
      expect(MessageType.error, isA<MessageType>());
      expect(const MessageKey.error('test'), isA<MessageKey>());
      expect(const FallbackLocalizationService(), isA<ILocalizationService>());
    });

    test('AsyncStatus extensions work', () {
      expect(AsyncStatus.idle.isIdle, isTrue);
      expect(AsyncStatus.loading.isLoading, isTrue);
      expect(AsyncStatus.success.isSuccess, isTrue);
      expect(AsyncStatus.failure.isFailure, isTrue);
      expect(AsyncStatus.success.isComplete, isTrue);
      expect(AsyncStatus.failure.isComplete, isTrue);
      expect(AsyncStatus.loading.isComplete, isFalse);
    });

    test('MessageKey factory constructors work', () {
      const errorKey = MessageKey.error('test.error');
      const successKey = MessageKey.success('test.success');
      const infoKey = MessageKey.info('test.info');
      const warningKey = MessageKey.warning('test.warning');

      expect(errorKey.type, MessageType.error);
      expect(successKey.type, MessageType.success);
      expect(infoKey.type, MessageType.info);
      expect(warningKey.type, MessageType.warning);
    });

    test('FallbackLocalizationService works', () {
      const service = FallbackLocalizationService();
      
      expect(service.translate('test.key'), 'test.key');
      expect(service.translate('hello.{name}', args: {'name': 'world'}), 'hello.world');
      expect(service.hasKey('anything'), isFalse);
    });
  });
}