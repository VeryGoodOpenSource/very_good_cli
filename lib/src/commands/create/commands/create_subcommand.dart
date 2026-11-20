import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';
import 'package:very_good_cli/src/pubspec_workspace/pubspec_workspace.dart';
import 'package:very_good_cli/src/very_good_config/very_good_config.dart';

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');
final _orgNameRegExp = RegExp(r'^[a-zA-Z][\w-]*(\.[a-zA-Z][\w-]*)+$');

const _defaultOrgName = 'com.example.verygoodcore';
const _defaultDescription = 'A Very Good Project created by Very Good CLI.';

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef MasonGeneratorFromBundle = Future<MasonGenerator> Function(MasonBundle);

/// A method which returns the [PubspecWorkspace] that encloses a [Directory].
///
/// It throws a [PubspecWorkspaceNotFoundException] or a
/// [PubspecWorkspaceParseException] when there is none, as
/// [PubspecWorkspace.enclosing] does.
typedef PubspecWorkspaceFinder = PubspecWorkspace Function(Directory);

/// {@template create_subcommand}
/// Generic class for sub commands of [CreateCommand].
/// {@endtemplate}
///
/// It contains the common logic for all sub commands of [CreateCommand],
/// including the [run] and [runCreate] routines.
///
/// By default, adds the following arguments to the [argParser]:
/// - 'output-directory': the output directory
/// - 'description': the description of the project
///
/// Sub classes must implement [name], [description] and [template].
///
/// For sub commands with multiple templates, sub classes must mix with
/// [MultiTemplates].
///
/// For sub commands that receive an org name, sub classes must mix with
/// [OrgName].
///
/// For sub commands that receive a publishable flag, sub classes must mix with
/// [Publishable].
///
/// For sub commands that receive a workspace flag, sub classes must mix with
/// [Workspace].
abstract class CreateSubCommand({
  /// The logger user to notify the user of the command's progress.
  required final Logger logger,
  @visibleForTesting required MasonGeneratorFromBundle? generatorFromBundle,
  @visibleForTesting PubspecWorkspaceFinder? findWorkspace,
}) extends Command<int> {
  /// {@macro create_subcommand}
  this {
    argParser
      ..addOption(
        'output-directory',
        abbr: 'o',
        help: 'The desired output directory when creating a new project.',
      )
      ..addOption(
        'description',
        help: 'The description for this new project.',
        aliases: ['desc'],
        defaultsTo: _defaultDescription,
      );

    // Add the templates arg if the command has multiple templates.
    if (this is MultiTemplates) {
      final multiTemplates = this as MultiTemplates;
      final templates = multiTemplates.templates;
      final defaultTemplateName = multiTemplates.defaultTemplateName;

      argParser.addOption(
        'template',
        abbr: 't',
        help: 'The template used to generate this new project.',
        defaultsTo: defaultTemplateName,
        allowed: templates.map((template) => template.name).toList(),
        allowedHelp: templates.fold<Map<String, String>>(
          {},
          (previousTemplate, template) => {
            ...previousTemplate,
            template.name: template.help,
          },
        ),
      );
    }

    if (this is OrgName) {
      argParser.addOption(
        'org-name',
        help: 'The organization for this new project.',
        defaultsTo: _defaultOrgName,
        aliases: ['org'],
      );
    }

    if (this is Publishable) {
      argParser.addFlag(
        'publishable',
        negatable: false,
        help: 'Whether the generated project is intended to be published.',
      );
    }

    if (this is Workspace) {
      argParser.addFlag(
        'workspace',
        aliases: ['ws'],
        help:
            'Whether the generated project should be added to the closest '
            'parent Pub workspace and resolve its dependencies from it.',
      );
    }
  }

  final MasonGeneratorFromBundle _generatorFromBundle =
      generatorFromBundle ?? MasonGenerator.fromBundle;

  final PubspecWorkspaceFinder _findWorkspace =
      findWorkspace ?? PubspecWorkspace.enclosing;

  /// The resolved `very_good create` configuration read from the closest
  /// `very_good.yaml` file.
  ///
  /// Values declared here are used as defaults for any option that was not
  /// explicitly passed on the command line. It defaults to an empty
  /// configuration until [run] loads it.
  VeryGoodCreateConfig createConfig = const VeryGoodCreateConfig();

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  /// Gets the output [Directory].
  Directory get outputDirectory {
    final directoryParameter = argResults['output-directory'] as String?;
    final args = argResults.rest;

    if (args.first == '.' && directoryParameter != null) {
      usageException(
        '''--output-directory cannot be specified when using "very_good create <template> ."''',
      );
    }

    if (directoryParameter != null) {
      return Directory('$directoryParameter/$projectName');
    }

    return Directory(args.first);
  }

  /// Gets the project name.
  String get projectName {
    final args = argResults.rest;

    if (args.isEmpty) {
      usageException('No option specified for the project name.');
    }

    if (args.length > 1) {
      usageException('Multiple project names specified.');
    }

    final projectName = args.first;
    if (projectName.contains('/')) {
      usageException('Project name cannot contain "/".');
    }

    final name = args.first == '.'
        ? path.basename(Directory.current.path)
        : projectName;

    final isValidPackageName = _isValidPackageName(name);

    if (!isValidPackageName) {
      usageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
      );
    }

    return name;
  }

  /// Gets the description for the project.
  String get projectDescription => argResults.resolve<String>(
    'description',
    createConfig.description,
    fallbackValue: '',
  );

  /// Should return the desired template to be created during a command run.
  ///
  /// For sub commands with multiple templates, see [MultiTemplates].
  Template get template;

  @override
  String get invocation => 'very_good create $name <project-name> [arguments]';

  @override
  ArgResults get argResults => argResultOverrides ?? super.argResults!;

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }

  @override
  Future<int> run() async {
    final config = VeryGoodConfig.load(Directory.current, logger: logger);
    if (config == null) return ExitCode.config.code;
    createConfig = config.create;

    final template = this.template;
    final bundle = template.bundle;

    logger.detail(
      'Building generator from bundle ${bundle.name} ${bundle.version}',
    );

    final generator = await _generatorFromBundle(bundle);
    final result = await runCreate(generator, template);
    return result;
  }

  /// Timeout for the Mason hook's internal `dart pub get` during bootstrapping.
  ///
  /// When connected to a network without internet access, this can hang
  /// indefinitely. This timeout ensures the CLI surfaces a clear error instead.
  @visibleForTesting
  static const preGenTimeout = Duration(seconds: 120);

  /// Invoked by [run] to create the project, contains the logic for using
  /// the template vars obtained by [getTemplateVars] to generate the project
  /// from the [generator] and [template].
  Future<int> runCreate(MasonGenerator generator, Template template) async {
    var vars = getTemplateVars();

    // Resolved before anything is generated, so that a project that cannot
    // join a workspace fails without leaving files behind.
    PubspecWorkspace? pubspecWorkspace;
    if (this case final Workspace command when command.workspace) {
      try {
        pubspecWorkspace = _findWorkspace(outputDirectory);
      } on PubspecWorkspaceNotFoundException catch (exception) {
        logger.err(_workspaceNotFoundMessage(exception));
        return ExitCode.config.code;
      } on PubspecWorkspaceParseException catch (exception) {
        logger.err(
          'Could not parse ${exception.pubspecFile.path}.\n'
          'Fix it before creating a project that resolves from a Pub '
          'workspace.',
        );
        return ExitCode.config.code;
      }
    }

    final generateProgress = logger.progress('Bootstrapping');
    final target = DirectoryGeneratorTarget(outputDirectory);

    try {
      await generator.hooks
          .preGen(vars: vars, onVarsChanged: (v) => vars = v)
          .timeout(preGenTimeout);
    } on TimeoutException {
      generateProgress.fail('Timed out waiting for hook dependencies.');
      logger.err(
        'Bootstrapping timed out after ${preGenTimeout.inSeconds} seconds.\n'
        'Check your internet connection and try again.',
      );
      return ExitCode.unavailable.code;
    }
    final files = await generator.generate(target, vars: vars, logger: logger);
    generateProgress.complete('Generated ${files.length} file(s)');

    // The generated packages have to be members of the workspace before
    // their dependencies are installed.
    if (pubspecWorkspace != null && !_addToWorkspace(pubspecWorkspace, files)) {
      return ExitCode.cantCreate.code;
    }

    await template.onGenerateComplete(logger, outputDirectory);

    return ExitCode.success.code;
  }

  /// Adds the packages among the generated [files] that resolve from a
  /// workspace to the `workspace` list of [pubspecWorkspace].
  ///
  /// Returns whether the root pubspec could be edited. When it could not, the
  /// entries to add by hand are reported.
  bool _addToWorkspace(
    PubspecWorkspace pubspecWorkspace,
    List<GeneratedFile> files,
  ) {
    final workspaceName = pubspecWorkspace.pubspec.name;
    final members = files
        .where((file) => path.basename(file.path) == 'pubspec.yaml')
        .map((file) => Directory(path.dirname(file.path)))
        .where(PubspecWorkspace.declaresWorkspaceResolution)
        .toList();

    if (members.isEmpty) {
      logger.warn(
        'None of the generated packages resolves from a workspace; nothing '
        'was added to the $workspaceName workspace.',
      );
      return true;
    }

    try {
      final updated = pubspecWorkspace.addMembers(members);
      final added = updated.entries.skip(pubspecWorkspace.entries.length);
      for (final entry in added) {
        logger.info('Added "$entry" to the $workspaceName workspace');
      }
      return true;
    } on FileSystemException catch (exception) {
      logger.err(
        _workspaceEditFailedMessage(pubspecWorkspace, members, exception),
      );
    } on FormatException catch (exception) {
      logger.err(
        _workspaceEditFailedMessage(pubspecWorkspace, members, exception),
      );
    }
    return false;
  }

  /// The error reported when the pubspec of [pubspecWorkspace] cannot be
  /// edited, naming the entries to add by hand for the generated [members].
  String _workspaceEditFailedMessage(
    PubspecWorkspace pubspecWorkspace,
    List<Directory> members,
    Exception exception,
  ) {
    final entries = members
        .where((member) => !pubspecWorkspace.includes(member))
        .map((member) => '  - ${pubspecWorkspace.entryFor(member)}')
        .join('\n');
    return 'Could not add the generated project to the '
        '${pubspecWorkspace.pubspec.name} workspace: $exception\n'
        'Add it to the "workspace" list of the pubspec in '
        '${pubspecWorkspace.root.path} and install its dependencies:\n'
        '\n'
        'workspace:\n'
        '$entries';
  }

  /// The error reported when the [outputDirectory] has no parent Pub workspace
  /// to join, naming the pubspec to edit and the entry to add to it.
  String _workspaceNotFoundMessage(
    PubspecWorkspaceNotFoundException exception,
  ) {
    final outputDirectory = this.outputDirectory;
    final outputPath = outputDirectory.path;
    final pubspecFile = exception.pubspecFile;

    if (pubspecFile == null) {
      return 'Could not find a Pub workspace for $outputPath: none of its '
          'parent directories has a pubspec.yaml.\n'
          'Create the project inside a Pub workspace, or pass '
          '--no-workspace.';
    }

    final entry = PubspecWorkspace.entryBetween(
      pubspecFile.parent,
      outputDirectory,
    );
    return 'Could not find a Pub workspace for $outputPath: '
        '${path.relative(pubspecFile.path)} does not declare a workspace.\n'
        'Add a "workspace" list to it and try again:\n'
        '\n'
        'workspace:\n'
        '  - $entry';
  }

  /// Responsible for returns the template parameters to be passed to the
  /// template brick.
  ///
  /// Override if the create sub command requires additional template
  /// parameters.
  ///
  /// For subcommands that mix with [OrgName], it includes 'org_name'.
  /// For subcommands that mix with [Publishable], it includes 'publishable'.
  /// For subcommands that mix with [Workspace], it includes 'workspace'.
  @mustCallSuper
  Map<String, dynamic> getTemplateVars() {
    final projectName = this.projectName;
    final projectDescription = this.projectDescription;

    return <String, dynamic>{
      'project_name': projectName,
      'description': projectDescription,
      if (this is OrgName) 'org_name': (this as OrgName).orgName,
      if (this is Publishable) 'publishable': (this as Publishable).publishable,
      if (this is Workspace) 'workspace': (this as Workspace).workspace,
    };
  }
}

/// Mixin for [CreateSubCommand] subclasses that receives the org name
/// parameter.
///
/// Takes care of parsing from [argResults] and validating the org name.
mixin OrgName on CreateSubCommand {
  /// Gets the organization name.
  String get orgName {
    final orgName = argResults.resolve<String>(
      'org-name',
      createConfig.orgName,
      fallbackValue: _defaultOrgName,
    );
    _validateOrgName(orgName);
    return orgName;
  }

  void _validateOrgName(String name) {
    logger.detail('Validating org name; $name');
    final isValidOrgName = _isValidOrgName(name);
    if (!isValidOrgName) {
      usageException(
        '"$name" is not a valid org name.\n\n'
        'A valid org name has at least 2 parts separated by "."\n'
        'Each part must start with a letter and only include '
        'alphanumeric characters (A-Z, a-z, 0-9), underscores (_), '
        'and hyphens (-)\n'
        '(ex. very.good.org)',
      );
    }
  }

  bool _isValidOrgName(String name) {
    return _orgNameRegExp.hasMatch(name);
  }
}

/// Mixin for [CreateSubCommand] subclasses that receives multiple templates.
///
/// Subcommands that mix with this mixin should override [templates].
///
/// Takes care of parsing the desired template from [argResults] and
/// validating the org name.
mixin MultiTemplates on CreateSubCommand {
  /// Gets the desired template to be created during a command run when the
  /// template argument is not provided.
  ///
  /// Defaults to the first template in [templates].
  String get defaultTemplateName => templates.first.name;

  /// Gets all the templates to be created during a command run.
  List<Template> get templates;

  @nonVirtual
  @override
  Template get template {
    final templateName = argResults.resolve<String>(
      'template',
      createConfig.template,
      fallbackValue: defaultTemplateName,
    );

    return templates.firstWhere(
      (template) => template.name == templateName,
      orElse: () {
        // When the value came from `very_good.yaml` rather than the command
        // line, point the user at the config key instead of the CLI option so
        // they debug the right place.
        final source = argResults.wasParsed('template')
            ? 'option "--template"'
            : 'the `create.template` key in `$veryGoodConfigFileName`';
        usageException('"$templateName" is not an allowed value for $source.');
      },
    );
  }
}

/// Mixin for [CreateSubCommand] subclasses that receives the publishable
/// flag.
///
/// Takes care of parsing it from [argResults] and pass it
/// to the brick generator.
mixin Publishable on CreateSubCommand {
  /// Gets the publishable flag.
  bool get publishable => argResults.resolve<bool>(
    'publishable',
    createConfig.publishable,
    fallbackValue: false,
  );
}

/// Mixin for [CreateSubCommand] subclasses that receives the workspace flag.
///
/// Takes care of parsing it from [argResults] and pass it
/// to the brick generator.
///
/// When the flag is set, [CreateSubCommand.runCreate] joins the closest
/// parent Pub workspace: it finds the workspace before generating anything,
/// failing with [ExitCode.config] if there is none, and adds the generated
/// packages to its `workspace` list before their dependencies are installed.
mixin Workspace on CreateSubCommand {
  /// Gets the workspace flag.
  bool get workspace => argResults.resolve<bool>(
    'workspace',
    createConfig.workspace,
    fallbackValue: false,
  );
}
