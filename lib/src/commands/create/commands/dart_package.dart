import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_dart_package_command}
/// A [CreateSubCommand] for creating Dart packages.
/// {@endtemplate}
class CreateDartPackage extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_dart_package_command}
  CreateDartPackage({
    required Analytics analytics,
    required Logger logger,
    required MasonGeneratorFromBundle? generatorFromBundle,
    required MasonGeneratorFromBrick? generatorFromBrick,
  }) : super(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: generatorFromBundle,
          generatorFromBrick: generatorFromBrick,
        );

  @override
  String get name => 'dart_package';

  @override
  List<String> get aliases => ['dart_pkg'];

  @override
  String get description =>
      'Creates a new very good Dart package in the specified directory.';

  @override
  Template get template => DartPkgTemplate();
}
