import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:custom_lint_builder/custom_lint_builder.dart';

PluginBase createPlugin() => _CubitUiFlowLintPlugin();

class _CubitUiFlowLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidBlocImportsInWidgetsDir(),
        AvoidGetItInAdaptersDir(),
        RequireCubitFieldOverRawBlocApis(),
        RequireStaticSelector(),
        CubitFieldSelectorMustBeEquatable(),
        NoDuplicateCubitFieldKeys(),
        ];
}

abstract class _PathImportRule extends DartLintRule {
  const _PathImportRule({required super.code});

  bool pathContains(String path, String segment) =>
      path.split('/').contains(segment);

  String? imported(UriBasedDirective node) => node.uri.stringValue;
}

class AvoidBlocImportsInWidgetsDir extends _PathImportRule {
  const AvoidBlocImportsInWidgetsDir()
      : super(
          code: const LintCode(
            name: 'avoid_bloc_imports_in_widgets_dir',
            problemMessage:
                'Widgets must not import Cubit, DI, or routing APIs.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    if (!pathContains(resolver.path, 'widgets')) return;
    context.registry.addImportDirective((node) {
      final uri = imported(node);
      if (uri == 'package:flutter_bloc/flutter_bloc.dart' ||
          uri == 'package:get_it/get_it.dart' ||
          uri == 'package:injectable/injectable.dart' ||
          uri == 'package:go_router/go_router.dart') {
        reporter.atNode(node, code);
      }
    });
  }
}

class AvoidGetItInAdaptersDir extends _PathImportRule {
  const AvoidGetItInAdaptersDir()
      : super(
          code: const LintCode(
            name: 'avoid_getit_in_adapters_dir',
            problemMessage:
                'Adapters must not construct or locate dependencies.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    if (!pathContains(resolver.path, 'adapters')) return;
    context.registry.addImportDirective((node) {
      final uri = imported(node);
      if (uri == 'package:get_it/get_it.dart' ||
          uri == 'package:injectable/injectable.dart') {
        reporter.atNode(node, code);
      }
    });
  }
}

class RequireCubitFieldOverRawBlocApis extends DartLintRule {
  const RequireCubitFieldOverRawBlocApis()
      : super(
          code: const LintCode(
            name: 'require_cubitfield_over_raw_bloc_apis',
            problemMessage:
                'Use CubitAdapter.cubitField instead of raw Bloc rebuild APIs.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    if (resolver.path.endsWith('cubit_adapter.dart')) return;
    context.registry.addMethodInvocation((node) {
      final name = node.methodName.name;
      if (name == 'watch' || name == 'select') {
        final target = node.target;
        if (target is SimpleIdentifier && target.name == 'context') {
          reporter.atNode(node, code);
        }
      }
    });
    context.registry.addInstanceCreationExpression((node) {
      final name = node.constructorName.type.name2.lexeme;
      if (name == 'BlocBuilder' ||
          name == 'BlocSelector' ||
          name == 'BlocConsumer') {
        reporter.atNode(node, code);
      }
    });
  }
}

class RequireStaticSelector extends DartLintRule {
  const RequireStaticSelector()
      : super(
          code: const LintCode(
            name: 'require_static_selector',
            problemMessage:
                'cubitField selectors must be static or top-level tear-offs.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'cubitField' ||
          node.argumentList.arguments.isEmpty) {
        return;
      }
      final argument = node.argumentList.arguments.first;
      if (argument is FunctionExpression || argument is FunctionReference) {
        reporter.atNode(argument, code);
      }
    });
  }
}

class CubitFieldSelectorMustBeEquatable extends DartLintRule {
  const CubitFieldSelectorMustBeEquatable()
      : super(
          code: const LintCode(
            name: 'cubit_field_selector_must_be_equatable',
            problemMessage:
                'Selector outputs should have stable value equality.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'cubitField') return;
      final argument = node.argumentList.arguments.firstOrNull;
      if (argument is FunctionExpression &&
          argument.body is ExpressionFunctionBody) {
        final expression = (argument.body as ExpressionFunctionBody).expression;
        if (expression is ListLiteral ||
            expression is SetOrMapLiteral ||
            expression is RecordLiteral) {
          reporter.atNode(expression, code);
        }
      }
    });
  }
}

class NoDuplicateCubitFieldKeys extends DartLintRule {
  const NoDuplicateCubitFieldKeys()
      : super(
          code: const LintCode(
            name: 'no_duplicate_cubit_field_keys',
            problemMessage:
                'Avoid declaring duplicate cubitField selectors in one adapter.',
          ),
        );

  @override
  void run(CustomLintResolver resolver, ErrorReporter reporter,
      CustomLintContext context) {
    final seen = <String, MethodInvocation>{};
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'cubitField') return;
      final argument = node.argumentList.arguments.firstOrNull;
      if (argument is SimpleIdentifier) {
        final previous = seen[argument.name];
        if (previous != null) reporter.atNode(node, code);
        seen[argument.name] = node;
      }
    });
  }
}
