import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

int sumPair(int a, int b) => a + b;
int identityInt(int x) => x;

class _SubCubit extends Cubit<int> {
  _SubCubit() : super(0);
  int calls = 0;
  void hit() => calls++;
}

class _Outer extends CubitAdapter<TestCubit, TestState> {
  const _Outer(this.onSubCubitCreated);

  final void Function(_SubCubit) onSubCubitCreated;

  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<TestCubit, TestState> adapter) {
    return BlocProvider(
      create: (_) {
        final sub = _SubCubit();
        onSubCubitCreated(sub);
        return sub;
      },
      child: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => ctx.read<_SubCubit>().hit(),
          child: const Text('hit'),
        ),
      ),
    );
  }
}

class _Reactive extends CubitAdapter<_SubCubit, int> {
  const _Reactive();

  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<_SubCubit, int> adapter) {
    adapter.cubitField(identityInt);
    return const SizedBox();
  }
}

void main() {
  testWidgets('callback-only subsidiary resolves from descendant context and is actually called', (
    tester,
  ) async {
    final outer = TestCubit();
    _SubCubit? sub;
    await tester.pumpWidget(
      MaterialApp(home: BlocProvider.value(value: outer, child: _Outer((s) => sub = s))),
    );

    // BlocProvider(create:) is lazy — create() only runs on first read, which
    // happens inside onPressed here, not during build.
    expect(sub, isNull);

    await tester.tap(find.text('hit'));
    await tester.pump();

    expect(sub, isNotNull);
    expect(sub!.calls, 1, reason: 'the onPressed callback must reach the real subsidiary instance');

    await tester.tap(find.text('hit'));
    await tester.pump();
    expect(sub!.calls, 2);

    await outer.close();
  });

  testWidgets('nested reactive adapter tears down before its provider', (tester) async {
    final c = TestCubit();
    await tester.pumpWidget(
      BlocProvider.value(
        value: c,
        child: BlocProvider(create: (_) => _SubCubit(), child: const _Reactive()),
      ),
    );

    // If the nested adapter's AdapterScopeImpl did not unsubscribe before the
    // BlocProvider above it closes the subsidiary Cubit, this teardown would
    // throw (a listener callback firing/cancelling against an already-closed
    // stream/disposed notifier) — Flutter tears down children before
    // parents, so this is exercising real teardown order, not just a smoke
    // check.
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });

  test('listener may read second source state without a field cache entry', () async {
    final a = TestCubit();
    final b = TestCubit(const TestState(8));
    final scope = AdapterScopeImpl();
    var seen = 0;
    scope.listenToCubit('a', a, (_) => seen = b.state.value);

    a.emit(const TestState(1));
    await Future<void>.delayed(Duration.zero);
    expect(seen, 8);

    scope.dispose();
    await a.close();
    await b.close();
  });

  test('successive combine2 (four sources) seeds synchronously and emits once per source emission', () async {
    final scope = AdapterScopeImpl();
    final cubits = [
      TestCubit(),
      TestCubit(const TestState(1)),
      TestCubit(const TestState(2)),
      TestCubit(const TestState(3)),
    ];
    final fields = cubits.map((c) => scope.cubitField(c, selectValue)).toList();

    final ab = scope.combine2(fields[0], fields[1], sumPair);
    final abc = scope.combine2(ab, fields[2], sumPair);
    final all = scope.combine2(abc, fields[3], sumPair);
    expect(all.value, 6);

    var notifications = 0;
    all.addListener(() => notifications++);

    cubits[0].emit(const TestState(4));
    await Future<void>.delayed(Duration.zero);

    expect(all.value, 10);
    expect(notifications, 1);

    scope.dispose();
    for (final c in cubits) {
      await c.close();
    }
  });
}
