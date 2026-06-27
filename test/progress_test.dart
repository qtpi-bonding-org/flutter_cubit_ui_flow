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
}
