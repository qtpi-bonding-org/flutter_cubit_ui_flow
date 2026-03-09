import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/src/contracts/all_contracts.dart';

void main() {
  group('Cubit UI Flow Library', () {
    test('UiFlowStatus enum works correctly', () {
      expect(UiFlowStatus.idle.isIdle, isTrue);
      expect(UiFlowStatus.loading.isLoading, isTrue);
      expect(UiFlowStatus.success.isSuccess, isTrue);
      expect(UiFlowStatus.failure.isFailure, isTrue);
    });

    test('MessageKey creation works', () {
      const errorKey = MessageKey.error('test.error');
      expect(errorKey.type, MessageType.error);
      expect(errorKey.key, 'test.error');
    });

    test('MessageKey.errorFrom accepts typed record', () {
      final key = MessageKey.errorFrom(('error.validation', {'field': 'name'}));
      expect(key.type, MessageType.error);
      expect(key.key, 'error.validation');
      expect(key.args, {'field': 'name'});
    });

    test('MessageKey.successFrom accepts typed record', () {
      final key = MessageKey.successFrom(('op.complete', {'count': 5}));
      expect(key.type, MessageType.success);
      expect(key.key, 'op.complete');
      expect(key.args, {'count': 5});
    });

    test('MessageKey.infoFrom accepts typed record', () {
      final key = MessageKey.infoFrom(('info.loaded', {'item': 'template'}));
      expect(key.type, MessageType.info);
      expect(key.key, 'info.loaded');
      expect(key.args, {'item': 'template'});
    });

    test('MessageKey from record equals manually constructed', () {
      final fromRecord = MessageKey.errorFrom(('error.test', {'x': 1}));
      const manual = MessageKey.error('error.test', {'x': 1});
      expect(fromRecord, equals(manual));
    });

    test('Library compiles successfully', () {
      // This test passes if the library compiles
      expect(true, isTrue);
    });
  });
}