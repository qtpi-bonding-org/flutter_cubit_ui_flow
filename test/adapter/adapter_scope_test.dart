import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FlowState with UiFlowStateMixin implements IUiFlowState {
  const _FlowState(this.value, {this.status = UiFlowStatus.idle, this.error});

  final int value;
  @override
  final UiFlowStatus status;
  @override
  final Object? error;
}

class _FlowCubit extends Cubit<_FlowState> {
  _FlowCubit([_FlowState initial = const _FlowState(0)]) : super(initial);
}

class _PlainState {
  const _PlainState(this.value);
  final int value;
}

class _PlainCubit extends Cubit<_PlainState> {
  _PlainCubit() : super(const _PlainState(0));
}

int _selectValue(_FlowState state) => state.value;
int _selectValueAlt(_FlowState state) => state.value;
int _selectPlainValue(_PlainState state) => state.value;

class _MultiFixture extends MultiCubitAdapter {
  const _MultiFixture({required this.a, required this.b, required this.onBuild});

  final _FlowCubit a;
  final _FlowCubit b;
  final void Function(ValueListenable<int>, ValueListenable<int>) onBuild;

  @override
  Widget buildAdapter(BuildContext context, AdapterScope scope) {
    final va = scope.cubitField(a, _selectValue);
    final vb = scope.cubitField(b, _selectValue);
    onBuild(va, vb);
    return const SizedBox();
  }
}

class _SharedCacheAdapter extends CubitAdapter<_FlowCubit, _FlowState> {
  const _SharedCacheAdapter({required this.onBuild});

  final void Function(ValueListenable<int>, ValueListenable<int>) onBuild;

  @override
  Widget buildAdapter(
    BuildContext context,
    CubitAdapterState<_FlowCubit, _FlowState> adapter,
  ) {
    final viaPrimary = adapter.cubitField(_selectValue);
    final viaSources = adapter.sources.cubitField(adapter.cubit, _selectValue);
    onBuild(viaPrimary, viaSources);
    return const SizedBox();
  }
}

class _LegacyAdapter extends CubitAdapter<_FlowCubit, _FlowState> {
  const _LegacyAdapter({required this.onDispose});

  final VoidCallback onDispose;

  @override
  Widget buildAdapter(
    BuildContext context,
    CubitAdapterState<_FlowCubit, _FlowState> adapter,
  ) {
    adapter.cubitField(_selectValue);
    return const SizedBox();
  }

  @override
  void disposeAdapter() {
    onDispose();
    super.disposeAdapter();
  }
}

void main() {
  group('AdapterScopeImpl.cubitField', () {
    test('same (cubit, selector) pair returns the identical notifier', () {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      final a = scope.cubitField(cubit, _selectValue);
      final b = scope.cubitField(cubit, _selectValue);
      expect(identical(a, b), isTrue);
      scope.dispose();
      cubit.close();
    });

    test('two different static selectors on one cubit stay independent', () {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      final a = scope.cubitField(cubit, _selectValue);
      final b = scope.cubitField(cubit, _selectValueAlt);
      expect(identical(a, b), isFalse);
      scope.dispose();
      cubit.close();
    });

    test('an equal projected value does not notify', () async {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      final field = scope.cubitField(cubit, _selectValue);
      var notifications = 0;
      field.addListener(() => notifications++);

      cubit.emit(const _FlowState(0, status: UiFlowStatus.loading));
      await Future<void>.delayed(Duration.zero);

      expect(notifications, 0);
      scope.dispose();
      await cubit.close();
    });

    test('a state implementing no flow interface compiles and updates', () async {
      final scope = AdapterScopeImpl();
      final cubit = _PlainCubit();
      final field = scope.cubitField(cubit, _selectPlainValue);
      expect(field.value, 0);

      cubit.emit(const _PlainState(5));
      await Future<void>.delayed(Duration.zero);

      expect(field.value, 5);
      scope.dispose();
      await cubit.close();
    });

    test('a non-default initial state is reflected before any emission', () {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit(const _FlowState(42));
      final field = scope.cubitField(cubit, _selectValue);
      expect(field.value, 42);
      scope.dispose();
      cubit.close();
    });
  });

  group('AdapterScopeImpl.listenToCubit / listenToTransition', () {
    test('registering the same key twice does not duplicate the subscription', () async {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      var calls = 0;
      scope.listenToCubit('k', cubit, (_) => calls++);
      scope.listenToCubit('k', cubit, (_) => calls++);

      cubit.emit(const _FlowState(1));
      await Future<void>.delayed(Duration.zero);

      expect(calls, 1);
      scope.dispose();
      await cubit.close();
    });

    test('listenToTransition supplies the correct previous/current pair', () async {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      _FlowState? seenPrevious;
      _FlowState? seenCurrent;
      scope.listenToTransition('k', cubit, (previous, current) {
        seenPrevious = previous;
        seenCurrent = current;
      });

      cubit.emit(const _FlowState(9));
      await Future<void>.delayed(Duration.zero);

      expect(seenPrevious!.value, 0);
      expect(seenCurrent!.value, 9);
      scope.dispose();
      await cubit.close();
    });

    test('re-registering under the same key fires only the new closure', () async {
      final scope = AdapterScopeImpl();
      final cubit = _FlowCubit();
      var oldCalls = 0;
      var newCalls = 0;
      scope.listenToCubit('k', cubit, (_) => oldCalls++);
      scope.listenToCubit('k', cubit, (_) => newCalls++);

      cubit.emit(const _FlowState(1));
      await Future<void>.delayed(Duration.zero);

      expect(oldCalls, 0);
      expect(newCalls, 1);
      scope.dispose();
      await cubit.close();
    });
  });

  group('AdapterScopeImpl.listenTo', () {
    test('re-registering under the same key rewires to the new closure, not the old one', () {
      final scope = AdapterScopeImpl();
      final source = ValueNotifier(0);
      var oldCalls = 0;
      var newCalls = 0;
      scope.listenTo('k', source, () => oldCalls++);
      scope.listenTo('k', source, () => newCalls++);

      source.value = 1;

      expect(oldCalls, 0);
      expect(newCalls, 1);
      scope.dispose();
      source.dispose();
    });
  });

  group('AdapterScopeImpl.keep', () {
    test('the same key returns the identical instance and create() runs once', () {
      final scope = AdapterScopeImpl();
      var creates = 0;
      Object make() {
        creates++;
        return Object();
      }

      final a = scope.keep('k', make);
      final b = scope.keep('k', make);
      final c = scope.keep('k', make);

      expect(identical(a, b), isTrue);
      expect(identical(b, c), isTrue);
      expect(creates, 1);
      scope.dispose();
    });

    test('an explicit dispose callback runs exactly once on teardown', () {
      final scope = AdapterScopeImpl();
      var disposals = 0;
      scope.keep('k', Object.new, dispose: (_) => disposals++);

      expect(disposals, 0);
      scope.dispose();
      expect(disposals, 1);
      scope.dispose();
      expect(disposals, 1);
    });

    test('R14 regression: a Timer.periodic held in keep is created once and '
        'stops ticking after dispose', () async {
      final scope = AdapterScopeImpl();
      var liveTimers = 0;
      var ticks = 0;
      Timer make() {
        liveTimers++;
        return Timer.periodic(const Duration(milliseconds: 20), (_) => ticks++);
      }

      // Simulate three forced parent rebuilds re-requesting the same key.
      for (var i = 0; i < 3; i++) {
        scope.keep<Timer>('poll', make, dispose: (t) => t.cancel());
      }
      expect(liveTimers, 1);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      final ticksBeforeDispose = ticks;
      expect(ticksBeforeDispose, greaterThan(0));

      scope.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(ticks, ticksBeforeDispose);
    });
  });

  test('teardown disposes cubitField, keep, and combine2 in order without throwing', () async {
    final scope = AdapterScopeImpl();
    final cubitA = _FlowCubit();
    final cubitB = _FlowCubit(const _FlowState(10));
    final fieldA = scope.cubitField(cubitA, _selectValue);
    final fieldB = scope.cubitField(cubitB, _selectValue);
    final combined = scope.combine2(fieldA, fieldB, (a, b) => a + b);
    expect(combined.value, 10);
    final notifier = scope.keep('notifier', () => ValueNotifier<int>(0));
    expect(notifier, isA<ValueNotifier<int>>());

    expect(scope.dispose, returnsNormally);
    await cubitA.close();
    await cubitB.close();
  });

  testWidgets(
    'MultiCubitAdapter projects two explicit sources independently, both emission orders',
    (tester) async {
      final cubitA = _FlowCubit();
      final cubitB = _FlowCubit();
      ValueListenable<int>? va;
      ValueListenable<int>? vb;
      await tester.pumpWidget(_MultiFixture(
        a: cubitA,
        b: cubitB,
        onBuild: (a, b) {
          va = a;
          vb = b;
        },
      ));

      cubitA.emit(const _FlowState(1));
      await tester.pump();
      expect(va!.value, 1);
      expect(vb!.value, 0);

      cubitB.emit(const _FlowState(2));
      await tester.pump();
      expect(va!.value, 1);
      expect(vb!.value, 2);

      await tester.pumpWidget(const SizedBox());
      await cubitA.close();
      await cubitB.close();
    },
  );

  testWidgets(
    'primary cubitField and sources.cubitField share one cache for the same cubit/selector',
    (tester) async {
      final cubit = _FlowCubit();
      ValueListenable<int>? viaPrimary;
      ValueListenable<int>? viaSources;
      await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: _SharedCacheAdapter(onBuild: (a, b) {
          viaPrimary = a;
          viaSources = b;
        }),
      ));

      expect(identical(viaPrimary, viaSources), isTrue);
      await cubit.close();
    },
  );

  testWidgets('legacy disposeAdapter override still fires exactly once', (tester) async {
    final cubit = _FlowCubit();
    var disposals = 0;
    await tester.pumpWidget(BlocProvider.value(
      value: cubit,
      child: _LegacyAdapter(onDispose: () => disposals++),
    ));

    await tester.pumpWidget(const SizedBox());

    expect(disposals, 1);
    await cubit.close();
  });
}
