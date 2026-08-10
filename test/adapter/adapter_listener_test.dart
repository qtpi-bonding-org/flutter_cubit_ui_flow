import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

void main() {
  test('two different keys on same cubit both fire once', () async {
    final s=AdapterScopeImpl(); final c=TestCubit(); var a=0,b=0;
    s.listenToCubit('a',c,(_)=>a++); s.listenToCubit('b',c,(_)=>b++); c.emit(const TestState(1)); await Future<void>.delayed(Duration.zero);
    expect(a,1); expect(b,1); s.dispose(); await c.close();
  });
  test('transition supplies previous and current', () async { final s=AdapterScopeImpl();final c=TestCubit(); TestState? p,n;
    s.listenToTransition('k',c,(x,y){p=x;n=y;}); c.emit(const TestState(2)); await Future<void>.delayed(Duration.zero);
    expect(p!.value,0);expect(n!.value,2);s.dispose();await c.close(); });
  test('Cubit callback refreshes after rebuild', () async { final s=AdapterScopeImpl();final c=TestCubit();var old=0,newer=0;
    s.listenToCubit('k',c,(_)=>old++);s.listenToCubit('k',c,(_)=>newer++);c.emit(const TestState(1));await Future<void>.delayed(Duration.zero);expect(old,0);expect(newer,1);s.dispose();await c.close(); });
  test('ValueListenable callback refreshes under same key', () {final s=AdapterScopeImpl();final v=ValueNotifier(0);var old=0,n=0;
    s.listenTo('k',v,()=>old++);s.listenTo('k',v,()=>n++);v.value=1;expect(old,0);expect(n,1);s.dispose();v.dispose();});
  test('replacing source cancels old and resubscribes', () async {final s=AdapterScopeImpl();final a=TestCubit(),b=TestCubit();var calls=0;TestState? p;
    s.listenToTransition('k',a,(_,__)=>calls++);a.emit(const TestState(1));await Future<void>.delayed(Duration.zero);
    s.listenToTransition('k',b,(x,_) {calls++;p=x;});a.emit(const TestState(2));b.emit(const TestState(5));await Future<void>.delayed(Duration.zero);
    expect(calls,2);expect(p!.value,0);s.dispose();await a.close();await b.close();});
  test('no callback after scope disposed', () async {final s=AdapterScopeImpl();final c=TestCubit();var n=0;s.listenToCubit('k',c,(_)=>n++);s.dispose();c.emit(const TestState(1));await Future<void>.delayed(Duration.zero);expect(n,0);await c.close();});
}
