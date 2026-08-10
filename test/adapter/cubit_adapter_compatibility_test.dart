import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

void main() {
  testWidgets('legacy one-argument cubitField compiles and works', (t) async {
    final c=TestCubit(); ValueListenable<int>? field;
    await t.pumpWidget(BlocProvider.value(value:c,child:LegacyFixture(onDispose:(){},onBuild:(a){field=a.cubitField(selectValue);}))); c.emit(const TestState(5)); await t.pump(); expect(field!.value,5); await c.close();
  });
  testWidgets('scope.cubit is the context provider cubit', (t) async {final c=TestCubit(); TestCubit? seen;
    await t.pumpWidget(BlocProvider.value(value:c,child:LegacyFixture(onDispose:(){},onContext:(context){seen=context.read<TestCubit>();},onBuild:(a){expect(identical(a.cubit,seen),isTrue);}))); expect(identical(seen,c),isTrue); await c.close();});
  testWidgets('primary and explicit field share cache', (t) async {final c=TestCubit();ValueListenable<int>? a,b;
    await t.pumpWidget(BlocProvider.value(value:c,child:LegacyFixture(onDispose:(){},onBuild:(x){a=x.cubitField(selectValue);b=x.sources.cubitField(x.cubit,selectValue);})));expect(identical(a,b),isTrue);await c.close();});
  testWidgets('legacy listenTo entry point fires', (t) async {final c=TestCubit();final v=ValueNotifier(0);var calls=0;
    await t.pumpWidget(BlocProvider.value(value:c,child:LegacyFixture(onDispose:(){},onBuild:(x){x.listenTo('k',v,()=>calls++);})));v.value=1;expect(calls,1);await t.pumpWidget(const SizedBox());v.dispose();await c.close();});
  testWidgets('legacy disposeAdapter fires once', (t) async {final c=TestCubit();var n=0;
    await t.pumpWidget(BlocProvider.value(value:c,child:LegacyFixture(onDispose:()=>n++,onBuild:(_){ })));await t.pumpWidget(const SizedBox());expect(n,1);await c.close();});
}
