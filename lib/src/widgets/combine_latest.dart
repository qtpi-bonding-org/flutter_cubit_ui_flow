import 'package:flutter/foundation.dart';

/// A value-listenable that derives its value from two inputs.
class _CombinedValueListenable2<A, B, R> extends ChangeNotifier
    implements ValueListenable<R> {
  _CombinedValueListenable2(this._a, this._b, this._combine)
      : _value = _combine(_a.value, _b.value) {
    _a.addListener(_onInputChanged);
    _b.addListener(_onInputChanged);
  }

  final ValueListenable<A> _a;
  final ValueListenable<B> _b;
  final R Function(A, B) _combine;
  R _value;

  @override
  R get value => _value;

  void _onInputChanged() {
    final next = _combine(_a.value, _b.value);
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _a.removeListener(_onInputChanged);
    _b.removeListener(_onInputChanged);
    super.dispose();
  }
}

/// Combines two value listenables and only notifies when the derived value
/// changes according to `==`.
ValueListenable<R> combineLatest2<A, B, R>(
  ValueListenable<A> a,
  ValueListenable<B> b,
  R Function(A, B) combine,
) =>
    _CombinedValueListenable2(a, b, combine);

class _CombinedValueListenable3<A, B, C, R> extends ChangeNotifier
    implements ValueListenable<R> {
  _CombinedValueListenable3(this._a, this._b, this._c, this._combine)
      : _value = _combine(_a.value, _b.value, _c.value) {
    _a.addListener(_onInputChanged);
    _b.addListener(_onInputChanged);
    _c.addListener(_onInputChanged);
  }

  final ValueListenable<A> _a;
  final ValueListenable<B> _b;
  final ValueListenable<C> _c;
  final R Function(A, B, C) _combine;
  R _value;

  @override
  R get value => _value;

  void _onInputChanged() {
    final next = _combine(_a.value, _b.value, _c.value);
    if (_value == next) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _a.removeListener(_onInputChanged);
    _b.removeListener(_onInputChanged);
    _c.removeListener(_onInputChanged);
    super.dispose();
  }
}

/// Combines three value listenables and only notifies when the derived value
/// changes according to `==`.
ValueListenable<R> combineLatest3<A, B, C, R>(
  ValueListenable<A> a,
  ValueListenable<B> b,
  ValueListenable<C> c,
  R Function(A, B, C) combine,
) =>
    _CombinedValueListenable3(a, b, c, combine);
