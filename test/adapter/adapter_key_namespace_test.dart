import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

void main() {
  test('keep and listener share a key namespace safely', () async {
    final s=AdapterScopeImpl(); final c=TestCubit(); final key=Object(); var seen=0;
    s.keep(key, ()=>const Object()); s.listenToCubit(key,c,(_)=>seen++);
    c.emit(const TestState(1)); await Future<void>.delayed(Duration.zero); expect(seen,1); s.dispose();
  });
  test('listener registration types replace under one key', () {
    final s=AdapterScopeImpl(); final c=TestCubit(); final n=ValueNotifier(0); final key=Object(); var cubitCalls=0; var valueCalls=0;
    s.listenToCubit(key,c,(_)=>cubitCalls++); s.listenTo(key,n,()=>valueCalls++);
    c.emit(const TestState(1)); n.value=1; expect(cubitCalls,0); expect(valueCalls,1); s.dispose();
  });
  test('independent scopes over one cubit do not interfere', () async {
    final c=TestCubit(); final a=AdapterScopeImpl(); final b=AdapterScopeImpl();
    final fa=a.cubitField(c,selectValue); final fb=b.cubitField(c,selectValue); var calls=0;
    b.listenToCubit('k',c,(_)=>calls++); a.keep('k',()=>Object()); a.dispose();
    c.emit(const TestState(7)); await Future<void>.delayed(Duration.zero); expect(fb.value,7); expect(calls,1); b.dispose();
  });
}
