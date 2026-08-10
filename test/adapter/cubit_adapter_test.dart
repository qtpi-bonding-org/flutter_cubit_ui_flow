import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The widget-level selector-memoization case this file used to hold is
  // now covered, with more depth, by cubit_adapter_compatibility_test.dart
  // and cubit_adapter_selector_test.dart. This file keeps the one case that
  // isn't a CubitAdapter/AdapterScope test at all — combineLatest2 is a
  // standalone top-level function with no home in the adapter-scope split.

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
