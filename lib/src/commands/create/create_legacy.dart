import 'dart:collection';
import 'dart:math';

import 'package:args/command_runner.dart';

// ignore: implementation_imports
import 'package:args/src/utils.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:very_good_cli/src/commands/commands.dart';
import 'package:very_good_cli/src/commands/create/create_subcommand.dart';
import 'package:very_good_cli/src/commands/create/templates/templates.dart';

/// Legacy elements of the [CreateCommand] class kept to maintain backwards
/// compatibility with the `very_good create <project name>` command syntax.
abstract class CreateCommandLegacy extends CreateSubCommand
    with OrgName, MultiTemplates {
  CreateCommandLegacy({
    required Analytics analytics,
    required Logger logger,
    MasonGeneratorFromBundle? generatorFromBundle,
    MasonGeneratorFromBrick? generatorFromBrick,
  }) : super(
          analytics: analytics,
          logger: logger,
          generatorFromBundle: generatorFromBundle,
          generatorFromBrick: generatorFromBrick,
          hideOptions: true,
        ) {
    argParser
      ..addOption(
        'executable-name',
        help: 'Used by the dart_cli template, the CLI executable name '
            '(defaults to the project name)',
        hide: true,
      )
      ..addOption(
        'android',
        help: 'The plugin supports the Android platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'ios',
        help: 'The plugin supports the iOS platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'web',
        help: 'The plugin supports the Web platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'linux',
        help: 'The plugin supports the Linux platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'macos',
        help: 'The plugin supports the macOS platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'windows',
        help: 'The plugin supports the Windows platform.',
        defaultsTo: 'true',
        hide: true,
      )
      ..addOption(
        'application-id',
        help: 'The bundle identifier on iOS or application id on Android. '
            '(defaults to <org-name>.<project-name>)',
        hide: true,
      )
      ..addFlag(
        'publishable',
        negatable: false,
        help: 'Whether the generated project is intended to be published '
            '(Does not affect flutter application templates)',
        hide: true,
      );
  }

  @override
  String get defaultTemplateName => 'core';

  @override
  List<Template> get templates => [
        VeryGoodCoreTemplate(),
        DartPkgTemplate(),
        FlutterPkgTemplate(),
        FlutterPluginTemplate(),
        VeryGoodDartCLITemplate(),
        VeryGoodDocsSiteTemplate(),
        VeryGoodFlameGameTemplate(),
      ];

  @override
  Future<int> runCreate(MasonGenerator generator, Template template) {
    logger.warn(
      "Deprecated: 'very_good create <project name>' is deprecated. "
      "Use 'very_good create [sub_command] <project name>' instead.",
    );
    return super.runCreate(generator, template);
  }

  @override
  Map<String, dynamic> getTemplateVars() {
    final vars = super.getTemplateVars();

    final applicationId = argResults['application-id'] as String?;

    final android = argResults['android'] as String? ?? 'true';
    final ios = argResults['ios'] as String? ?? 'true';
    final web = argResults['web'] as String? ?? 'true';
    final linux = argResults['linux'] as String? ?? 'true';
    final macos = argResults['macos'] as String? ?? 'true';
    final windows = argResults['windows'] as String? ?? 'true';

    final executableName =
        argResults['executable-name'] as String? ?? projectName;

    return <String, dynamic>{
      ...vars,
      'executable_name': executableName,
      if (applicationId != null) 'application_id': applicationId,
      'platforms': <String>[
        if (android.toBool()) 'android',
        if (ios.toBool()) 'ios',
        if (web.toBool()) 'web',
        if (linux.toBool()) 'linux',
        if (macos.toBool()) 'macos',
        if (windows.toBool()) 'windows',
      ],
    };
  }

  @override
  void addSubcommand(Command<int> command) {
    final names = [command.name, ...command.aliases];
    for (final name in names) {
      _optionalSubCommands[name] = command;
      argParser.addCommand(name, command.argParser);
    }
  }

  /// An unmodifiable view of all sublevel commands of this command.
  @override
  Map<String, Command<int>> get subcommands =>
      UnmodifiableMapView(_optionalSubCommands);

  /// Throws a [UsageException] with [message].
  @override
  Never usageException(String message) =>
      throw UsageException(_wrap(message), _usageWithoutDescription);

  @override
  String get usage => _wrap('$description\n\n') + _usageWithoutDescription;

  /// Returns [usage] with [description] removed from the beginning.
  String get _usageWithoutDescription {
    const usagePrefix = 'Usage: ';
    final buffer = StringBuffer()
      ..writeln(_wrap(usagePrefix + invocation))
      ..writeln(argParser.usage);

    if (subcommands.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(_getCommandUsage());
    }

    buffer
      ..writeln()
      ..write(
        _wrap('Run "${runner!.executableName} help" to see global options.'),
      );

    if (usageFooter != null) {
      buffer
        ..writeln()
        ..write(_wrap(usageFooter!));
    }

    return buffer.toString();
  }

  String _getCommandUsage() {
    final lineLength = argParser.usageLineLength;
    final entries = subcommands.entries
        .where(
          (entry) => !entry.value.aliases.contains(name) && !entry.value.hidden,
        )
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final length = entries.map((entry) => entry.key.length).reduce(max);
    final columnStart = length + 5;
    final buffer = StringBuffer('Available subcommands:');
    for (final entry in entries) {
      final command = entry.value;
      final lines = wrapTextAsLines(
        command.summary,
        start: columnStart,
        length: lineLength,
      );

      buffer
        ..writeln()
        ..write('  ${padRight(command.name, length)}   ${lines.first}');

      for (final line in lines.skip(1)) {
        buffer
          ..writeln()
          ..write(' ' * columnStart)
          ..write(line);
      }
    }

    return buffer.toString();
  }

  String _wrap(String text, {int? hangingIndent}) => wrapText(
        text,
        length: argParser.usageLineLength,
        hangingIndent: hangingIndent,
      );

  final _optionalSubCommands = <String, Command<int>>{};
}

extension on String {
  bool toBool() => toLowerCase() == 'true';
}
