import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'fixtures.dart';

void main() {
  testWidgets('two sources update A then B', (t) async {
    final a=TestCubit(), b=TestCubit(); List<ValueListenable<int>>? f;
    await t.pumpWidget(MultiFixture(sources:[a,b], onBuild:(x)=>f=x));
    a.emit(const TestState(1)); await t.pump(); expect(f![0].value,1); expect(f![1].value,0);
    b.emit(const TestState(2)); await t.pump(); expect(f![0].value,1); expect(f![1].value,2);
    await t.pumpWidget(const SizedBox()); await a.close(); await b.close();
  });
  testWidgets('two sources update B then A', (t) async {
    final a=TestCubit(), b=TestCubit(); List<ValueListenable<int>>? f;
    await t.pumpWidget(MultiFixture(sources:[a,b], onBuild:(x)=>f=x));
    b.emit(const TestState(3)); await t.pump(); expect(f![1].value,3); expect(f![0].value,0);
    a.emit(const TestState(4)); await t.pump(); expect(f![0].value,4); expect(f![1].value,3);
    await t.pumpWidget(const SizedBox()); await a.close(); await b.close();
  });
  testWidgets('four sources emit independently', (t) async {
    final cs=List.generate(4, (_) => TestCubit()); List<ValueListenable<int>>? f;
    await t.pumpWidget(MultiFixture(sources:cs,onBuild:(x)=>f=x));
    for(var i=0;i<4;i++){cs[i].emit(TestState(i+1)); await t.pump(); expect(f![i].value,i+1); for(var j=0;j<4;j++) if(j!=i) expect(f![j].value,j<i?j+1:0);}
    await t.pumpWidget(const SizedBox()); for(final c in cs) await c.close();
  });
  testWidgets('ten sources register successfully', (t) async {
    final cs=List.generate(10, (_) => TestCubit()); List<ValueListenable<int>>? f;
    await t.pumpWidget(MultiFixture(sources:cs,onBuild:(x)=>f=x)); expect(f,hasLength(10));
    cs[9].emit(const TestState(9)); await t.pump(); expect(f![9].value,9);
    await t.pumpWidget(const SizedBox()); for(final c in cs) await c.close();
  });
  test('same selector on different sources stays distinct', () {
    final s=AdapterScopeImpl(); final a=TestCubit(),b=TestCubit();
    expect(identical(s.cubitField(a,selectValueSame),s.cubitField(b,selectValueSame)),isFalse); s.dispose(); a.close();b.close();
  });
  testWidgets('conditional field may disappear and return', (t) async {
    final a=TestCubit(),b=TestCubit(); ValueListenable<int>? second;
    await t.pumpWidget(ConditionalFixture(a,b,true,(x,y)=>second=y)); final original=second!;
    await t.pumpWidget(ConditionalFixture(a,b,false,(x,y)=>second=y));
    await t.pumpWidget(ConditionalFixture(a,b,true,(x,y)=>second=y)); expect(identical(original,second),isTrue);
    b.emit(const TestState(8)); await t.pump(); expect(second!.value,8);
    await t.pumpWidget(const SizedBox()); await a.close();await b.close();
  });
  testWidgets('field and listener coexist', (t) async {
    final c=TestCubit(); ValueListenable<int>? f; var calls=0;
    await t.pumpWidget(_EffectFixture(c,(x)=>f=x,()=>calls++)); c.emit(const TestState(6)); await t.pump();
    expect(f!.value,6); expect(calls,1); await t.pumpWidget(const SizedBox()); await c.close();
  });
}
class _EffectFixture extends MultiCubitAdapter {
 const _EffectFixture(this.c,this.onField,this.onCall); final TestCubit c; final void Function(ValueListenable<int>) onField; final VoidCallback onCall;
 @override Widget buildAdapter(_,AdapterScope s){onField(s.cubitField(c,selectValue));s.listenToCubit('effect',c,(_)=>onCall());return const SizedBox();}
}
