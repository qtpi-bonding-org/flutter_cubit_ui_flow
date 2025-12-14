import '../contracts/async_state.dart';
import '../contracts/mappers.dart';
import '../contracts/message_key.dart';

/// Default implementation that combines exception + domain mappers.
///
/// This mapper:
/// 1. First checks for errors and maps them using [IExceptionKeyMapper]
/// 2. Then checks domain-specific mapping using [IDomainStateKeyMapper]
/// 3. Falls back to generic messages if no specific mapping is found
///
/// Example:
/// ```dart
/// final mapper = BaseStateMessageMapper<TrackerState>(
///   exceptionMapper: AppExceptionKeyMapper(),
///   domainMapper: TrackerDomainMapper(),
/// );
/// ```
class BaseStateMessageMapper<S extends IAsyncState>
    implements IStateMessageMapper<S> {
  final IExceptionKeyMapper _exceptionMapper;
  final IDomainStateKeyMapper<S>? _domainMapper;
  final bool _showGenericSuccess;

  /// Creates a [BaseStateMessageMapper].
  ///
  /// [exceptionMapper] Maps exceptions to message keys (required).
  /// [domainMapper] Maps domain states to message keys (optional).
  /// [showGenericSuccess] Whether to show generic success message when
  ///   no domain mapper provides one. Defaults to false.
  const BaseStateMessageMapper({
    required IExceptionKeyMapper exceptionMapper,
    IDomainStateKeyMapper<S>? domainMapper,
    bool showGenericSuccess = false,
  })  : _exceptionMapper = exceptionMapper,
        _domainMapper = domainMapper,
        _showGenericSuccess = showGenericSuccess;

  @override
  MessageKey? map(S state) {
    // 1. Check for errors first
    if (state.hasError && state.error != null) {
      final key = _exceptionMapper.map(state.error!);
      return key ?? MessageKey.genericError;
    }

    // 2. Check domain-specific mapping
    if (_domainMapper != null) {
      final domainKey = _domainMapper!.map(state);
      if (domainKey != null) return domainKey;
    }

    // 3. Optional generic success message
    if (state.isSuccess && _showGenericSuccess) {
      return MessageKey.genericSuccess;
    }

    return null;
  }
}

/// A simple exception mapper that maps common exceptions.
///
/// Consumer apps should extend or replace this with their own implementation.
class DefaultExceptionKeyMapper implements IExceptionKeyMapper {
  const DefaultExceptionKeyMapper();

  @override
  MessageKey? map(Object exception) {
    // Map common exception types
    final typeName = exception.runtimeType.toString().toLowerCase();

    if (typeName.contains('network') || typeName.contains('socket')) {
      return MessageKey.networkError;
    }
    if (typeName.contains('timeout')) {
      return MessageKey.timeoutError;
    }

    // Return null to fall back to generic error
    return null;
  }
}
