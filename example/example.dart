// Example usage of cubit_ui_flow library
import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'example_implementations.dart';

// Example state using UiFlowStateMixin
class ExampleState with UiFlowStateMixin {
  @override
  final UiFlowStatus status;
  @override
  final Object? error;
  final List<String> items;

  const ExampleState({
    this.status = UiFlowStatus.idle,
    this.error,
    this.items = const [],
  });

  ExampleState copyWith({
    UiFlowStatus? status,
    Object? error,
    List<String>? items,
  }) {
    return ExampleState(
      status: status ?? this.status,
      error: error ?? this.error,
      items: items ?? this.items,
    );
  }
}

// Example Cubit using TryOperationCubit
class ExampleCubit extends TryOperationCubit<ExampleState> {
  ExampleCubit() : super(const ExampleState());

  // Async operation
  Future<void> loadItems() async {
    await tryOperation(() async {
      // Simulate network call
      await Future.delayed(const Duration(seconds: 1));
      final items = ['Item 1', 'Item 2', 'Item 3'];
      
      return state.copyWith(
        status: UiFlowStatus.success,
        items: items,
      );
    });
  }

  // Sync operation
  Future<void> clearItems() async {
    await tryOperation(() {
      return state.copyWith(
        status: UiFlowStatus.success,
        items: [],
      );
    });
  }

  // Operation that might fail
  Future<void> riskyOperation() async {
    await tryOperation(() async {
      if (DateTime.now().millisecond % 2 == 0) {
        throw Exception('Random failure');
      }
      
      return state.copyWith(
        status: UiFlowStatus.success,
        items: [...state.items, 'New Item'],
      );
    });
  }
}

// Example exception mapper
class ExampleExceptionMapper implements IExceptionKeyMapper {
  @override
  MessageKey? map(Object exception) {
    if (exception is Exception) {
      return const MessageKey.error('error.generic');
    }
    return null;
  }
}

// Example domain mapper
class ExampleDomainMapper implements IDomainStateKeyMapper<ExampleState> {
  @override
  MessageKey? map(ExampleState state) {
    if (state.isSuccess && state.items.isNotEmpty) {
      return MessageKey.success('items.loaded', {'count': state.items.length});
    }
    return null;
  }
}

void main() {
  // Example of how the library would be used
  final cubit = ExampleCubit();
  final exceptionMapper = ExampleExceptionMapper();
  final domainMapper = ExampleDomainMapper();
  
  final stateMapper = BaseStateMessageMapper<ExampleState>(
    exceptionMapper: exceptionMapper,
    domainMapper: domainMapper,
  );

  print('cubit_ui_flow example setup complete!');
  print('State mapper created: ${stateMapper.runtimeType}');
  print('Initial state: ${cubit.state.status}');
}