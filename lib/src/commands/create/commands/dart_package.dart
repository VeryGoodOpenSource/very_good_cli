import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_dart_package_command}
/// A [CreateSubCommand] for creating Dart packages.
/// {@endtemplate}
class CreateDartPackage extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_dart_package_command}
  CreateDartPackage({
    required super.logger,
    required super.generatorFromBundle,
    required super.generatorFromBrick,
  });

  @override
  String get name => 'dart_package';

  @override
  List<String> get aliases => ['dart_pkg'];

  @override
  String get description => 'Generate a Very Good Dart package.';

  @override
  Template get template => DartPkgTemplate();
}
