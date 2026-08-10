import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../contracts/all_contracts.dart';
import 'combine_latest.dart';

/// Shared scope machinery for reading Cubits, reacting to their transitions,
/// deriving combined values, and owning UI-local resources with a single
/// teardown owner.
///
/// [cubitField] selectors must be static or top-level tear-offs — their
/// identity is the memoization key, so a closure defeats caching.
abstract interface class AdapterScope {
  /// Narrows [cubit]'s state, memoized on the record `(cubit, selector)`.
  /// [S] carries no bound: plain states that implement no flow interface
  /// compile and work here.
  ValueListenable<T> cubitField<S, T>(
    StateStreamable<S> cubit,
    T Function(S state) selector,
  );

  /// Flow-state convenience — only for `StateStreamable<IUiFlowState>`.
  ValueListenable<UiFlowStatus> cubitStatus(StateStreamable<IUiFlowState> cubit);

  /// Flow-state convenience — only for `StateStreamable<IUiFlowState>`.
  ValueListenable<Object?> cubitError(StateStreamable<IUiFlowState> cubit);

  /// One subscription per [key]. The first call creates it; every later
  /// call for the same [key] refreshes the delivered callback without
  /// creating a duplicate subscription. If [cubit] differs (identity) from
  /// the currently subscribed source under [key], the old subscription is
  /// cancelled and a new one created.
  void listenToCubit<S>(
    Object key,
    StateStreamable<S> cubit,
    void Function(S state) listener,
  );

  /// Same contract as [listenToCubit], delivering `(previous, current)`.
  /// On (re)subscribe, `previous` is seeded from `cubit.state`.
  void listenToTransition<S>(
    Object key,
    StateStreamable<S> cubit,
    void Function(S previous, S current) listener,
  );

  /// Same refresh-not-duplicate contract as [listenToCubit], for an
  /// arbitrary [ValueListenable] rather than a Cubit stream.
  void listenTo<T>(Object key, ValueListenable<T> listenable, VoidCallback listener);

  /// Derived value owned and disposed by the scope, memoized on
  /// `(a, b, combine)`. [a] and [b] should themselves be scope-owned.
  ValueListenable<R> combine2<A, B, R>(
    ValueListenable<A> a,
    ValueListenable<B> b,
    R Function(A a, B b) combine,
  );

  /// Derived value owned and disposed by the scope, memoized on
  /// `(a, b, c, combine)`. [a], [b], and [c] should themselves be
  /// scope-owned.
  ValueListenable<R> combine3<A, B, C, R>(
    ValueListenable<A> a,
    ValueListenable<B> b,
    ValueListenable<C> c,
    R Function(A a, B b, C c) combine,
  );

  /// UI-local object with scope lifetime. [create] runs exactly once per
  /// [key]; later calls return the cached instance. [dispose], if given,
  /// runs on scope teardown; otherwise a `ChangeNotifier` (or anything
  /// exposing a no-arg `dispose()`) is disposed automatically.
  T keep<T extends Object>(
    Object key,
    T Function() create, {
    void Function(T value)? dispose,
  });
}

class _Field {
  _Field(this.notifier, this.subscription);
  final ValueNotifier<Object?> notifier;
  final StreamSubscription<Object?> subscription;
}

/// One `listenToCubit`/`listenToTransition`/`listenTo` registration.
///
/// The callback is stored in a mutable slot ([callback]) and every
/// subscription/listener wrapper reads through that slot at fire time, so
/// refreshing [callback] on a later call actually changes what runs — it is
/// never re-attached to the underlying stream/notifier.
class _Registration {
  _Registration(this.source);
  final Object source;
  StreamSubscription<Object?>? subscription;
  ValueListenable<Object?>? listenable;
  VoidCallback? listenableWrapper;
  Object? callback;
}

class _Kept {
  _Kept(this.value, this.dispose);
  final Object value;
  final void Function()? dispose;
}

/// Concrete [AdapterScope]. Not a widget — whatever owns an instance (a
/// [State]) must call [dispose] exactly once.
class AdapterScopeImpl implements AdapterScope {
  final _fields = <Object, _Field>{};
  final _registrations = <Object, _Registration>{};
  final _combines = <Object, ValueListenable<Object?>>{};
  final _combinators = <ChangeNotifier>[];
  final _kept = <Object, _Kept>{};
  bool _disposed = false;

  @override
  ValueListenable<T> cubitField<S, T>(
    StateStreamable<S> cubit,
    T Function(S state) selector,
  ) {
    final key = (cubit, selector);
    final existing = _fields[key];
    if (existing != null) return existing.notifier as ValueListenable<T>;

    final notifier = ValueNotifier<T>(selector(cubit.state));
    final subscription = cubit.stream.listen((state) {
      if (_disposed) return;
      final next = selector(state);
      if (notifier.value != next) notifier.value = next;
    });
    _fields[key] = _Field(
      notifier as ValueNotifier<Object?>,
      subscription as StreamSubscription<Object?>,
    );
    return notifier;
  }

  @override
  ValueListenable<UiFlowStatus> cubitStatus(StateStreamable<IUiFlowState> cubit) =>
      cubitField(cubit, (state) => state.status);

  @override
  ValueListenable<Object?> cubitError(StateStreamable<IUiFlowState> cubit) =>
      cubitField(cubit, (state) => state.error);

  @override
  void listenToCubit<S>(
    Object key,
    StateStreamable<S> cubit,
    void Function(S state) listener,
  ) {
    final existing = _registrations[key];
    if (existing != null && identical(existing.source, cubit)) {
      existing.callback = listener;
      return;
    }
    existing?.subscription?.cancel();

    final registration = _Registration(cubit)..callback = listener;
    registration.subscription = cubit.stream.listen((state) {
      if (_disposed) return;
      (registration.callback as void Function(S))(state);
    }) as StreamSubscription<Object?>;
    _registrations[key] = registration;
  }

  @override
  void listenToTransition<S>(
    Object key,
    StateStreamable<S> cubit,
    void Function(S previous, S current) listener,
  ) {
    final existing = _registrations[key];
    if (existing != null && identical(existing.source, cubit)) {
      existing.callback = listener;
      return;
    }
    existing?.subscription?.cancel();

    var previous = cubit.state;
    final registration = _Registration(cubit)..callback = listener;
    registration.subscription = cubit.stream.listen((current) {
      if (_disposed) return;
      (registration.callback as void Function(S, S))(previous, current);
      previous = current;
    }) as StreamSubscription<Object?>;
    _registrations[key] = registration;
  }

  @override
  void listenTo<T>(Object key, ValueListenable<T> listenable, VoidCallback listener) {
    final existing = _registrations[key];
    if (existing != null && identical(existing.source, listenable)) {
      existing.callback = listener;
      return;
    }
    existing?.subscription?.cancel();
    if (existing?.listenable != null && existing?.listenableWrapper != null) {
      existing!.listenable!.removeListener(existing.listenableWrapper!);
    }

    final registration = _Registration(listenable)
      ..listenable = listenable as ValueListenable<Object?>
      ..callback = listener;
    void wrapper() {
      if (_disposed) return;
      (registration.callback as VoidCallback)();
    }

    registration.listenableWrapper = wrapper;
    listenable.addListener(wrapper);
    _registrations[key] = registration;
  }

  @override
  ValueListenable<R> combine2<A, B, R>(
    ValueListenable<A> a,
    ValueListenable<B> b,
    R Function(A a, B b) combine,
  ) {
    final key = (a, b, combine);
    final existing = _combines[key];
    if (existing != null) return existing as ValueListenable<R>;

    final result = combineLatest2(a, b, combine);
    _combines[key] = result as ValueListenable<Object?>;
    _combinators.add(result as ChangeNotifier);
    return result;
  }

  @override
  ValueListenable<R> combine3<A, B, C, R>(
    ValueListenable<A> a,
    ValueListenable<B> b,
    ValueListenable<C> c,
    R Function(A a, B b, C c) combine,
  ) {
    final key = (a, b, c, combine);
    final existing = _combines[key];
    if (existing != null) return existing as ValueListenable<R>;

    final result = combineLatest3(a, b, c, combine);
    _combines[key] = result as ValueListenable<Object?>;
    _combinators.add(result as ChangeNotifier);
    return result;
  }

  @override
  T keep<T extends Object>(
    Object key,
    T Function() create, {
    void Function(T value)? dispose,
  }) {
    final existing = _kept[key];
    if (existing != null) {
      assert(
        existing.value is T,
        'AdapterScope.keep key $key was created as ${existing.value.runtimeType}; '
        'requested $T. Hot-reload does not re-run keep(); restart instead.',
      );
      return existing.value as T;
    }
    final value = create();
    _kept[key] = _Kept(
      value,
      dispose == null ? _automaticDisposer(value) : () => dispose(value),
    );
    return value;
  }

  void Function()? _automaticDisposer(Object value) {
    if (value is ChangeNotifier) return value.dispose;
    return () {
      try {
        (value as dynamic).dispose();
      } on NoSuchMethodError {
        // No dispose() to call — nothing to do.
      }
    };
  }

  /// Cancel Cubit subscriptions -> remove ValueListenable listeners ->
  /// dispose combinators -> dispose kept objects -> dispose notifiers. A
  /// later step must never touch something an earlier step disposed.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final field in _fields.values) {
      field.subscription.cancel();
    }
    for (final registration in _registrations.values) {
      registration.subscription?.cancel();
    }
    for (final registration in _registrations.values) {
      if (registration.listenable != null && registration.listenableWrapper != null) {
        registration.listenable!.removeListener(registration.listenableWrapper!);
      }
    }
    for (final combinator in _combinators) {
      combinator.dispose();
    }
    for (final kept in _kept.values) {
      kept.dispose?.call();
    }
    for (final field in _fields.values) {
      field.notifier.dispose();
    }

    _fields.clear();
    _registrations.clear();
    _combines.clear();
    _combinators.clear();
    _kept.clear();
  }
}
