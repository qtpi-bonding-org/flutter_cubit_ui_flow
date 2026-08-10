import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

int addInts(int a, int b) => a + b;
int addIntsOther(int a, int b) => a + b;
bool sameParity(int a, int b) => a.isEven == b.isEven;
int sum3(int a, int b, int c) => a + b + c;

void main() {
  test('combine2 seeds and updates from each input', () async {
    final s = AdapterScopeImpl(); final a = TestCubit(); final b = TestCubit(const TestState(2));
    final fa = s.cubitField(a, selectValue); final fb = s.cubitField(b, selectValue);
    final out = s.combine2(fa, fb, addInts); expect(out.value, 2);
    a.emit(const TestState(3)); await Future<void>.delayed(Duration.zero); expect(out.value, 5);
    b.emit(const TestState(4)); await Future<void>.delayed(Duration.zero); expect(out.value, 7); s.dispose();
  });
  test('combine3 seeds and updates from every input', () async {
    final s = AdapterScopeImpl(); final a=TestCubit(); final b=TestCubit(const TestState(2)); final c=TestCubit(const TestState(3));
    final out=s.combine3(s.cubitField(a,selectValue),s.cubitField(b,selectValue),s.cubitField(c,selectValue),sum3);
    expect(out.value,5); a.emit(const TestState(1)); await Future<void>.delayed(Duration.zero); expect(out.value,6); b.emit(const TestState(5)); await Future<void>.delayed(Duration.zero); expect(out.value,9); c.emit(const TestState(7)); await Future<void>.delayed(Duration.zero); expect(out.value,13); s.dispose();
  });
  test('equal derived result suppresses notification', () async {
    final s=AdapterScopeImpl(); final a=TestCubit(); final b=TestCubit();
    final out=s.combine2(s.cubitField(a,selectValue),s.cubitField(b,selectValue),sameParity); var calls=0; out.addListener(() => calls++);
    a.emit(const TestState(2)); await Future<void>.delayed(Duration.zero); expect(out.value,isTrue); expect(calls,0); b.emit(const TestState(1)); await Future<void>.delayed(Duration.zero); expect(out.value,isFalse); expect(calls,1); s.dispose();
  });
  test('identical inputs and combiner are memoized', () { final s=AdapterScopeImpl(); final a=TestCubit(); final b=TestCubit(); final x=s.cubitField(a,selectValue); final y=s.cubitField(b,selectValue); expect(identical(s.combine2(x,y,addInts),s.combine2(x,y,addInts)),isTrue); s.dispose(); });
  test('different combiner functions remain distinct', () { final s=AdapterScopeImpl(); final a=TestCubit(); final b=TestCubit(); final x=s.cubitField(a,selectValue); final y=s.cubitField(b,selectValue); expect(identical(s.combine2(x,y,addInts),s.combine2(x,y,addIntsOther)),isFalse); s.dispose(); });
  test('derived-of-derived teardown is safe', () { final s=AdapterScopeImpl(); final a=TestCubit(); final b=TestCubit(); final c=TestCubit(); final ab=s.combine2(s.cubitField(a,selectValue),s.cubitField(b,selectValue),addInts); s.combine2(ab,s.cubitField(c,selectValue),addInts); expect(s.dispose,returnsNormally); });
}
