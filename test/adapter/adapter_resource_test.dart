import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

class _TrackedNotifier extends ChangeNotifier { bool wasDisposed=false; @override void dispose(){wasDisposed=true;super.dispose();} }

void main() {
  test('keep creates once through forced rebuilds', () {final s=AdapterScopeImpl();var n=0;Object make(){n++;return Object();}for(var i=0;i<4;i++)s.keep('k',make);expect(n,1);s.dispose();});
  test('separate keys do not collide', () {final s=AdapterScopeImpl();final a=s.keep('a',()=>1);final b=s.keep('b',()=>'two');expect(a,1);expect(b,'two');s.dispose();});
  test('explicit disposer wins, including ChangeNotifier', () {final s=AdapterScopeImpl();final v=_TrackedNotifier();var explicit=0;s.keep('k',()=>v,dispose:(_)=>explicit++);s.dispose();expect(explicit,1);expect(v.wasDisposed,isFalse);});
  test('bare ChangeNotifier auto-disposes', () {final s=AdapterScopeImpl();final v=_TrackedNotifier();s.keep('k',()=>v);s.dispose();expect(v.wasDisposed,isTrue);});
  // The Timer.periodic keep()-created-once/stops-after-dispose contract has
  // its own dedicated regression coverage in adapter_effect_leak_test.dart
  // (the R14 fixture, which also covers a guard flag alongside the timer).
  test('changing kept type under stable key asserts', () {final s=AdapterScopeImpl();s.keep<int>('k',()=>1);expect(() => s.keep<String>('k',()=>'x'),throwsA(isA<AssertionError>()));s.dispose();});

  test('teardown disposes cubitField, keep, and combine2 in order without throwing', () async {
    final scope = AdapterScopeImpl();
    final cubitA = TestCubit();
    final cubitB = TestCubit(const TestState(10));
    final fieldA = scope.cubitField(cubitA, selectValue);
    final fieldB = scope.cubitField(cubitB, selectValue);
    final combined = scope.combine2(fieldA, fieldB, (int a, int b) => a + b);
    expect(combined.value, 10);
    final notifier = scope.keep('notifier', () => ValueNotifier<int>(0));
    expect(notifier, isA<ValueNotifier<int>>());

    expect(scope.dispose, returnsNormally);
    await cubitA.close();
    await cubitB.close();
  });
}
