import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TestState { const TestState(this.value); final int value; }
class TestCubit extends Cubit<TestState> { TestCubit([TestState initial = const TestState(0)]) : super(initial); }
int selectValue(TestState s) => s.value;
int selectValueAlt(TestState s) => s.value + 100;
int selectValueSame(TestState s) => s.value;

class PlainState { const PlainState(this.value); final int value; }
class PlainCubit extends Cubit<PlainState> { PlainCubit() : super(const PlainState(0)); }
int selectPlain(PlainState s) => s.value;

class MultiFixture extends MultiCubitAdapter {
  const MultiFixture({required this.sources, required this.onBuild, this.flag = true});
  final List<TestCubit> sources;
  final void Function(List<ValueListenable<int>>) onBuild;
  final bool flag;
  @override Widget buildAdapter(BuildContext context, AdapterScope scope) {
    final fields = <ValueListenable<int>>[];
    for (final source in sources) fields.add(scope.cubitField(source, selectValue));
    onBuild(fields); return const SizedBox();
  }
}

class ConditionalFixture extends MultiCubitAdapter {
  const ConditionalFixture(this.first, this.second, this.enabled, this.onBuild);
  final TestCubit first, second; final bool enabled;
  final void Function(ValueListenable<int>, ValueListenable<int>?) onBuild;
  @override Widget buildAdapter(BuildContext context, AdapterScope scope) {
    final a = scope.cubitField(first, selectValue);
    final b = enabled ? scope.cubitField(second, selectValue) : null;
    onBuild(a, b); return const SizedBox();
  }
}

class LegacyFixture extends CubitAdapter<TestCubit, TestState> {
  const LegacyFixture({required this.onDispose, required this.onBuild, this.listenable, this.onContext});
  final VoidCallback onDispose;
  final void Function(CubitAdapterState<TestCubit, TestState>) onBuild;
  final ValueListenable<int>? listenable;
  final void Function(BuildContext context)? onContext;
  @override Widget buildAdapter(BuildContext context, CubitAdapterState<TestCubit, TestState> adapter) {
    onContext?.call(context);
    onBuild(adapter); return const SizedBox();
  }
  @override void disposeAdapter() { onDispose(); super.disposeAdapter(); }
}
