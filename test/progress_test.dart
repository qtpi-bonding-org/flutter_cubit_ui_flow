import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:cubit_ui_flow/cubit_ui_flow.dart";

void main() {
  group("UiFlowProgress", () {
    test("total 0 is indeterminate with null fraction", () {
      const p = UiFlowProgress(total: 0, current: 0);
      expect(p.isDeterminate, isFalse);
      expect(p.fraction, isNull);
    });

    test("total > 0 is determinate with a 0..1 fraction", () {
      const p = UiFlowProgress(label: "x", current: 3, total: 12);
      expect(p.isDeterminate, isTrue);
      expect(p.fraction, closeTo(0.25, 1e-9));
    });

    test("value equality over label/current/total", () {
      expect(const UiFlowProgress(label: "a", current: 1, total: 2),
          const UiFlowProgress(label: "a", current: 1, total: 2));
      expect(const UiFlowProgress(current: 1, total: 2),
          isNot(const UiFlowProgress(current: 2, total: 2)));
    });
  });

  group("listener progress drive", () {
    testWidgets("progress state shows bar and suppresses spinner", (tester) async {
      final loading = _FakeLoadingService();
      final progress = _FakeProgressService();
      final cubit = _ProgCubit();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: UiFlowStateListener<_ProgCubit, _ProgState>(
          bloc: cubit,
          mapper: _NoopMapper(),
          uiService: _FakeUiFlowService(loading),
          progressService: progress,
          progressLabel: "Importing",
          child: const SizedBox(),
        ),
      ));

      cubit.push(const _ProgState(UiFlowStatus.loading, UiFlowProgress(current: 1, total: 10)));
      await tester.pump();
      cubit.push(const _ProgState(UiFlowStatus.loading, UiFlowProgress(current: 5, total: 10)));
      await tester.pump();
      cubit.push(const _ProgState(UiFlowStatus.success, null));
      await tester.pump();

      expect(progress.shown.length, 2);
      expect(progress.shown.first.label, "Importing");
      expect(progress.shown.last.current, 5);
      expect(progress.hides, greaterThanOrEqualTo(1));
      expect(loading.shows, 0);
    });

    testWidgets("loading without progress shows spinner", (tester) async {
      final loading = _FakeLoadingService();
      final progress = _FakeProgressService();
      final cubit = _ProgCubit();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: UiFlowStateListener<_ProgCubit, _ProgState>(
          bloc: cubit,
          mapper: _NoopMapper(),
          uiService: _FakeUiFlowService(loading),
          progressService: progress,
          child: const SizedBox(),
        ),
      ));
      cubit.push(const _ProgState(UiFlowStatus.loading, null));
      await tester.pump();
      expect(loading.shows, 1);
      expect(progress.shown, isEmpty);
    });
  });
}

class _ProgState implements IUiFlowProgressState {
  @override
  final UiFlowStatus status;
  @override
  final UiFlowProgress? progress;
  const _ProgState(this.status, this.progress);
  @override
  Object? get error => null;
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  @override
  bool get hasError => false;
}

class _ProgCubit extends Cubit<_ProgState> {
  _ProgCubit() : super(const _ProgState(UiFlowStatus.idle, null));
  void push(_ProgState s) => emit(s);
}

class _FakeLoadingService implements ILoadingService {
  int shows = 0, hides = 0;
  @override
  void show() => shows++;
  @override
  void hide() => hides++;
}

class _FakeProgressService implements IProgressService {
  final List<UiFlowProgress> shown = [];
  int hides = 0;
  @override
  void show(UiFlowProgress p) => shown.add(p);
  @override
  void hide() => hides++;
}

class _NoopMapper implements IStateMessageMapper<_ProgState> {
  @override
  MessageKey? map(_ProgState state) => null;
}

class _FakeUiFlowService implements IUiFlowService {
  final _FakeLoadingService _loading;
  _FakeUiFlowService(this._loading);
  @override
  void showLoading() => _loading.show();
  @override
  void hideLoading() => _loading.hide();
  @override
  void handleMessage(MessageKey key) {}
  @override
  void handleState<S extends IUiFlowState>(S state, IStateMessageMapper<S> mapper) {}
}
