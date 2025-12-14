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

    test('Library compiles successfully', () {
      // This test passes if the library compiles
      expect(true, isTrue);
    });
  });
}