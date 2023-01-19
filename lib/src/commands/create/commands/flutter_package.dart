import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// {@template very_good_create_flutter_package_command}
/// A [CreateSubCommand] for creating Flutter packages.
/// {@endtemplate}
class CreateFlutterPackage extends CreateSubCommand with Publishable {
  /// {@macro very_good_create_flutter_package_command}
  CreateFlutterPackage({
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
  String get name => 'flutter_package';

  @override
  List<String> get aliases => ['flutter_pkg'];

  @override
  String get description => 'Generate a reusable Flutter package.';

  @override
  Template get template => FlutterPkgTemplate();
}
