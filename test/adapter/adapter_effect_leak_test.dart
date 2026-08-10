import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'R14 regression: a guard and a Timer.periodic held in keep are each '
    "created once across repeated rebuilds, and stop after dispose — this is "
    'a passing characterization test, not an expected failure',
    () async {
      final scope = AdapterScopeImpl();
      var guardCreates = 0;
      var timerCreates = 0;
      var ticks = 0;

      bool makeGuard() {
        guardCreates++;
        return false;
      }

      Timer makeTimer() {
        timerCreates++;
        return Timer.periodic(const Duration(milliseconds: 10), (_) => ticks++);
      }

      // Simulate three forced parent rebuilds re-requesting the same keys —
      // every call's create closure increments its counter, so a keep() bug
      // that re-ran create() on every call would show up here.
      for (var i = 0; i < 3; i++) {
        scope.keep('openedChat', makeGuard);
        scope.keep<Timer>('poll', makeTimer, dispose: (t) => t.cancel());
      }

      expect(guardCreates, 1);
      expect(timerCreates, 1);

      await Future<void>.delayed(const Duration(milliseconds: 35));
      final ticksBeforeDispose = ticks;
      expect(ticksBeforeDispose, greaterThan(0));

      scope.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(ticks, ticksBeforeDispose);
    },
  );
}
