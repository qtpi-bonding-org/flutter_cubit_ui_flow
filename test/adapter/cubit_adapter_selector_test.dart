import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

void main() {
  test('same selector returns identical notifier', () {
    final scope = AdapterScopeImpl(); final c = TestCubit();
    expect(identical(scope.cubitField(c, selectValue), scope.cubitField(c, selectValue)), isTrue);
    scope.dispose(); c.close();
  });
  test('two selectors on one source stay independent', () async {
    final scope = AdapterScopeImpl(); final c = TestCubit();
    final a = scope.cubitField(c, selectValue); final b = scope.cubitField(c, selectValueAlt);
    expect(identical(a, b), isFalse); c.emit(const TestState(2));
    await Future<void>.delayed(Duration.zero);
    expect(a.value, 2); expect(b.value, 102); scope.dispose(); c.close();
  });
  test('equal projection suppresses notification', () async {
    final scope = AdapterScopeImpl(); final c = TestCubit(); final f = scope.cubitField(c, selectValue); var n = 0;
    f.addListener(() => n++); c.emit(const TestState(0)); await Future<void>.delayed(Duration.zero);
    expect(n, 0); scope.dispose(); await c.close();
  });
  test('non-IUiFlowState state compiles and updates', () async {
    final scope = AdapterScopeImpl(); final c = PlainCubit(); final f = scope.cubitField(c, selectPlain);
    c.emit(const PlainState(7)); await Future<void>.delayed(Duration.zero); expect(f.value, 7);
    scope.dispose(); await c.close();
  });
  test('non-default initial state appears on first frame', () {
    final scope = AdapterScopeImpl(); final c = TestCubit(const TestState(42));
    expect(scope.cubitField(c, selectValue).value, 42); scope.dispose(); c.close();
  });
}
