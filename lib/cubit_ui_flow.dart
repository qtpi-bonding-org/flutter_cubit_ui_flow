/// Cubit UI Flow - Cubit state to UI feedback orchestration for Flutter.
///
/// This library provides contracts and orchestration for handling Cubit state changes
/// and converting them to UI feedback (loading overlays, toasts, etc.).
/// Consumer provides UI implementations.
library cubit_ui_flow;

// Contracts
export 'src/contracts/async_state.dart';
export 'src/contracts/message_key.dart';
export 'src/contracts/mappers.dart';
export 'src/contracts/localization_service.dart';
export 'src/contracts/feedback_service.dart';
export 'src/contracts/loading_service.dart';
export 'src/contracts/global_ui_service.dart';

// Implementations (orchestration only)
export 'src/impl/base_state_mapper.dart';
export 'src/impl/global_ui_service_impl.dart';

// Widgets
export 'src/widgets/async_ui_listener.dart';

// Utils
export 'src/utils/cubit_extensions.dart';
