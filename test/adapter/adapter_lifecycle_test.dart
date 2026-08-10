import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

class _KeepAdapter extends CubitAdapter<TestCubit, TestState> {
  const _KeepAdapter(this.onCreate, this.onDispose, {super.key});

  final VoidCallback onCreate;
  final VoidCallback onDispose;

  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<TestCubit, TestState> adapter) {
    adapter.keep('x', () {
      onCreate();
      return Object();
    }, dispose: (_) => onDispose());
    return const SizedBox();
  }
}

class _FieldAdapter extends CubitAdapter<TestCubit, TestState> {
  const _FieldAdapter(this.onValue, {super.key});

  final ValueChanged<int> onValue;

  @override
  Widget buildAdapter(BuildContext context, CubitAdapterState<TestCubit, TestState> adapter) {
    final field = adapter.cubitField(selectValue);
    onValue(field.value);
    field.addListener(() => onValue(field.value));
    return const SizedBox();
  }
}

void _noop() {}

void main() {
  testWidgets('inactive IndexedStack child remains mounted and subscribed', (tester) async {
    final c = TestCubit();
    var activeSeen = 0;
    var inactiveSeen = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: c,
          child: IndexedStack(
            index: 0,
            children: [
              _FieldAdapter((v) => activeSeen = v),
              _FieldAdapter((v) => inactiveSeen = v),
            ],
          ),
        ),
      ),
    );
    expect(activeSeen, 0);
    expect(inactiveSeen, 0);

    c.emit(const TestState(3));
    await tester.pump();

    // Index 1's subtree is not currently displayed (index: 0 is active) but
    // IndexedStack keeps every child mounted, so its Cubit subscription must
    // still be live and updated.
    expect(activeSeen, 3, reason: 'the active child must reflect the emission');
    expect(inactiveSeen, 3, reason: 'the inactive-but-mounted child must also reflect it');

    await tester.pumpWidget(const SizedBox());
    await c.close();
  });

  testWidgets('a forced parent rebuild that does not change adapter identity preserves scope resources', (
    tester,
  ) async {
    var creates = 0;
    var disposes = 0;
    late StateSetter setState;
    final c = TestCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: c,
          child: StatefulBuilder(
            builder: (ctx, setter) {
              setState = setter;
              return Column(
                children: [_KeepAdapter(() => creates++, () => disposes++)],
              );
            },
          ),
        ),
      ),
    );
    expect(creates, 1);

    // Force three real parent rebuilds via setState — the adapter's Key and
    // type are unchanged, so Flutter reuses the same Element/State and
    // buildAdapter() runs again each time without recreating the underlying
    // scope or its keep()-owned resources.
    for (var i = 0; i < 3; i++) {
      setState(() {});
      await tester.pump();
    }
    expect(creates, 1, reason: 'keep() must not re-run create() on ordinary rebuilds');
    expect(disposes, 0);

    await tester.pumpWidget(const SizedBox());
    expect(disposes, 1);
    await c.close();
  });

  testWidgets('keyed replacement disposes the old scope exactly once', (tester) async {
    var disposed = 0;
    final a = TestCubit();
    final b = TestCubit(const TestState(9));

    await tester.pumpWidget(
      BlocProvider.value(value: a, child: const _KeepAdapter(_noop, _noop, key: ValueKey('a'))),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: b,
        child: _KeepAdapter(_noop, () => disposed++, key: const ValueKey('b')),
      ),
    );
    expect(disposed, 0);

    await tester.pumpWidget(
      BlocProvider.value(
        value: b,
        child: _KeepAdapter(_noop, () => disposed++, key: const ValueKey('c')),
      ),
    );
    expect(disposed, 1);

    await a.close();
    await b.close();
  });

  testWidgets('a typed CubitAdapter under a lazy BlocProvider constructs its primary on resolve', (
    tester,
  ) async {
    var count = 0;
    await tester.pumpWidget(
      BlocProvider(
        create: (_) {
          count++;
          return TestCubit();
        },
        child: _FieldAdapter(_noop2),
      ),
    );
    expect(count, 1);
  });

  testWidgets('BlocProvider.value cubit is not closed by a MultiCubitAdapter', (tester) async {
    final c = TestCubit();
    await tester.pumpWidget(
      BlocProvider.value(value: c, child: MultiFixture(sources: [c], onBuild: (_) {})),
    );
    await tester.pumpWidget(const SizedBox());
    expect(c.isClosed, isFalse);
    await c.close();
  });

  testWidgets('a late queued stream event during teardown is tolerated', (tester) async {
    final c = TestCubit();
    await tester.pumpWidget(BlocProvider.value(value: c, child: _FieldAdapter(_noop2)));
    c.emit(const TestState(4));
    // No intervening pump — the emission may still be in flight when the
    // widget is torn down, which is the scenario being proven safe.
    await tester.pumpWidget(const SizedBox());
    await c.close();
  });
}

void _noop2(int _) {}
