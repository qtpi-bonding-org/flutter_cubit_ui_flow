// Example implementations for cubit_ui_flow library
// These are reference implementations that projects can copy and customize

import 'package:cubit_ui_flow/cubit_ui_flow.dart';

/// Base implementation of [IStateMessageMapper] that combines exception and domain mappers
class BaseStateMessageMapper<S extends IUiFlowState> implements IStateMessageMapper<S> {
  final IExceptionKeyMapper exceptionMapper;
  final IDomainStateKeyMapper<S> domainMapper;

  const BaseStateMessageMapper({
    required this.exceptionMapper,
    required this.domainMapper,
  });

  @override
  MessageKey? map(S state) {
    // First try domain-specific mapping
    final domainKey = domainMapper.map(state);
    if (domainKey != null) {
      return domainKey;
    }

    // If state has error, try exception mapping
    if (state.hasError && state.error != null) {
      return exceptionMapper.map(state.error!);
    }

    return null;
  }
}

/// Default implementation of [IExceptionKeyMapper]
class DefaultExceptionKeyMapper implements IExceptionKeyMapper {
  const DefaultExceptionKeyMapper();

  @override
  MessageKey? map(Object exception) {
    final message = exception.toString().toLowerCase();
    
    if (message.contains('network') || message.contains('connection')) {
      return MessageKey.networkError;
    }
    
    if (message.contains('timeout')) {
      return MessageKey.timeoutError;
    }
    
    return MessageKey.genericError;
  }
}

/// Fallback implementation of [ILocalizationService]
class FallbackLocalizationService implements ILocalizationService {
  const FallbackLocalizationService();

  @override
  String translate(String key, {Map<String, dynamic>? args}) {
    String result = key;
    
    // Simple template replacement
    if (args != null) {
      args.forEach((placeholder, value) {
        result = result.replaceAll('{$placeholder}', value.toString());
      });
    }
    
    return result;
  }
}