import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _State with UiFlowStateMixin implements IUiFlowState {
  const _State(this.value, {this.status = UiFlowStatus.idle, this.error});

  final int value;
  @override
  final UiFlowStatus status;
  @override
  final Object? error;
}

class _Cubit extends Cubit<_State> {
  _Cubit() : super(const _State(0));
}

class _Adapter extends CubitAdapter<_Cubit, _State> {
  const _Adapter({required this.onBuild});

  final void Function(ValueListenable<int>, ValueListenable<int>) onBuild;

  static int selectValue(_State state) => state.value;
  static int selectUnrelated(_State state) => state.value;

  @override
  Widget buildAdapter(
      BuildContext context, CubitAdapterState<_Cubit, _State> adapter) {
    final value = adapter.cubitField(selectValue);
    final valueAgain = adapter.cubitField(selectValue);
    onBuild(value, valueAgain);
    return const SizedBox();
  }
}

void main() {
  testWidgets('memoizes a selector and updates only when its value changes',
      (tester) async {
    final cubit = _Cubit();
    ValueListenable<int>? selected;
    ValueListenable<int>? selectedAgain;
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: _Adapter(onBuild: (a, b) {
        selected = a;
        selectedAgain = b;
      }),
    ));

    expect(identical(selected, selectedAgain), isTrue);
    expect(selected!.value, 0);
    cubit.emit(const _State(1));
    await tester.pump();
    expect(selected!.value, 1);

    final sameNotifier = selected;
    cubit.emit(const _State(1, status: UiFlowStatus.loading));
    await tester.pump();
    expect(identical(selected, sameNotifier), isTrue);
    expect(selected!.value, 1);

    await tester.pumpWidget(const SizedBox());
    cubit.emit(const _State(2));
    await tester.pump();
    expect(selected!.value, 1);
    await cubit.close();
  });

  test('combineLatest2 only notifies when the combined value changes', () {
    final a = ValueNotifier(1);
    final b = ValueNotifier(2);
    final combined = combineLatest2(a, b, (left, right) => left + right);
    var notifications = 0;
    combined.addListener(() => notifications++);

    a.value = 2;
    expect(combined.value, 4);
    expect(notifications, 1);
    b.value = 1;
    expect(combined.value, 3);
    expect(notifications, 2);
    b.value = 1;
    expect(notifications, 2);

    (combined as ChangeNotifier).dispose();
    a.dispose();
    b.dispose();
  });
}
