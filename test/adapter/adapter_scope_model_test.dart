import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

enum _Action { rebuild, emitA, emitB, replaceCallback, toggleActivity, keyedRemount, dispose }

void main() {
  for (final seed in [1, 42, 1337]) {
    test('seeded scope model $seed', () async {
      final random = Random(seed); final scope = AdapterScopeImpl();
      final a = TestCubit(); final b = TestCubit();
      final field = scope.cubitField(a, selectValue); final other = scope.cubitField(b, selectValue);
      var callbacks = 0; var disposed = false; var active = true;
      final actions = <String>[];
      void check() { if (!disposed) { expect(field.value, a.state.value, reason: 'seed=$seed actions=$actions'); expect(other.value,b.state.value,reason:'seed=$seed actions=$actions'); } expect(callbacks,isNonNegative,reason:'seed=$seed actions=$actions'); }
      for (var i=0; i<30; i++) {
        final action = _Action.values[random.nextInt(_Action.values.length)]; actions.add(action.name);
        try {
          switch (action) {
            case _Action.rebuild: scope.cubitField(a, selectValue); break;
            case _Action.emitA: a.emit(TestState(a.state.value + 1)); break;
            case _Action.emitB: b.emit(TestState(b.state.value + 1)); break;
            case _Action.replaceCallback: scope.listenToCubit('model', a, (_) => callbacks++); break;
            case _Action.toggleActivity: active=!active; break;
            case _Action.keyedRemount: if (active) scope.listenToCubit('model', a, (_) => callbacks++); break;
            case _Action.dispose: if (!disposed) { scope.dispose(); disposed=true; } break;
          }
          if (action == _Action.emitA || action == _Action.emitB) await Future<void>.delayed(Duration.zero);
          check();
        } catch (e) { fail('seed=$seed actions=$actions error=$e'); }
      }
      if (!disposed) scope.dispose();
      a.close(); b.close();
    });
  }
}
