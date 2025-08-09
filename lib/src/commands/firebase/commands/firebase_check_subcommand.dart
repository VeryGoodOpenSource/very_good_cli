import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';

/// {@template firebase_check_command}
/// `very_good firebase check` command checks Firebase configurations.
/// {@endtemplate}
class FirebaseCheckCommand extends Command<int> {
  /// {@macro firebase_check_command}
  FirebaseCheckCommand({
    required Logger logger,
  }) : _logger = logger {
    // very_good firebase check
    argParser
      ..addFlag(
        'storage_rules',
        abbr: 's',
        help: 'Enable checking of the storage rules.',
        defaultsTo: true,
      )
      ..addFlag(
        'allow_public_read',
        abbr: 'r',
        help: 'Allows public access to read operations',
        defaultsTo: true,
      );
  }

  final Logger _logger;

  @override
  String get description => 'Perform checks on Firebase configurations.';

  @override
  String get name => 'check';

  @override
  FutureOr<int>? run() async {
    final firebaseJsonFile = File('firebase.json');

    if (!firebaseJsonFile.existsSync()) {
      _logger.err('firebase.json file not found in the current directory.');
      return ExitCode.config.code;
    }

    late Map<String, dynamic> firebaseJsonObject;

    try {
      firebaseJsonObject =
          jsonDecode(firebaseJsonFile.readAsStringSync())
              as Map<String, dynamic>;
    } on Exception catch (e) {
      _logger.err('Failed to parse firebase.json: $e');
      return ExitCode.data.code;
    }

    final storageObject =
        firebaseJsonObject['storage'] as Map<String, dynamic>? ?? {};
    final storageRulesFilePath = storageObject['rules'] as String?;

    if (storageRulesFilePath == null) {
      _logger.err('Storage rules file path not found in firebase.json.');
      return ExitCode.config.code;
    }

    var hasErrors = false;

    final storageRulesFile = File(storageRulesFilePath);
    if (!storageRulesFile.existsSync()) {
      _logger.err('Storage rules file not found: $storageRulesFilePath');
      return ExitCode.config.code;
    }

    final allowPublicRead = argResults?['allow_public_read'] as bool;

    final checkers = [
      CloudStorageOpenAccessChecker(readOperationsAllowed: allowPublicRead),
      CloudStorageAccessForAuthenticatedUsersChecker(),
    ];

    final cloudStorageCheckers = checkers.where(
      (checker) => checker.type == ServiceType.storage,
    );

    final cloudStorageFileContent = await storageRulesFile.readAsString();
    for (final checker in cloudStorageCheckers) {
      final isValid = await checker.check(fileContent: cloudStorageFileContent);

      if (!isValid) {
        hasErrors = true;
        _logger
          ..err(' ❌ ${checker.invalidRulesMessage}')
          ..err('For more information, visit: ${checker.ruleUrl}');
      } else {
        _logger.info(' ✅ ${checker.name}.');
      }
    }

    return hasErrors ? ExitCode.software.code : ExitCode.success.code;
  }
}

/// Types of services that can be checked.
enum ServiceType {
  /// Firebase Storage
  storage,
}

/// Abstract class for checking Firebase rules.
abstract class FirebaseRulesChecker {
  /// Creates a new [FirebaseRulesChecker].
  FirebaseRulesChecker({
    required this.name,
    required this.type,
    required this.invalidRulesMessage,
    required this.ruleUrl,
  });

  /// The name of the checker.
  final String name;

  /// The type of service this checker is for.
  final ServiceType type;

  /// The message to display when the rules are invalid.
  final String invalidRulesMessage;

  /// The URL to the Firebase rules documentation for this checker.
  final String ruleUrl;

  /// Checks the Firebase rules for the given file.
  Future<bool> check({
    required String fileContent,
  });

  /// Helper method to normalize lines in the rule file content.
  List<String> normalizedLines(String content) {
    return content
        .split(Platform.lineTerminator)
        .map((line) => line.trim())
        // Remove any double spaces to make sure we don't fail to get a
        // vulnerability because of an extra space.
        .map((line) => line.replaceAll('  ', ' '))
        .where((line) => line.isNotEmpty)
        .toList();
  }
}

/// Checker for Firebase Storage rules that allows open access.
class CloudStorageOpenAccessChecker extends FirebaseRulesChecker {
  /// Creates a new [CloudStorageOpenAccessChecker].
  CloudStorageOpenAccessChecker({
    required this.readOperationsAllowed,
  }) : super(
         name: 'Cloud Storage open access',
         type: ServiceType.storage,
         invalidRulesMessage: 'Storage rules allow open access to all users',
         ruleUrl:
             'https://firebase.google.com/docs/rules/insecure-rules#open_access',
       );

  /// Whether public read operations are allowed in the rules.
  final bool readOperationsAllowed;

  @override
  Future<bool> check({
    required String fileContent,
  }) async {
    final regexps = [
      RegExp(
        r'allow\s+((read|write|create|update)(\s*,\s*)?){1,4}:\s*if\s*true;',
      ),
      RegExp(r'allow\s+((read|write|create|update)(\s*,\s*)?){1,4};'),
    ];
    final lines = normalizedLines(fileContent);

    for (final regexp in regexps) {
      for (final line in lines) {
        final matches = regexp.allMatches(line);
        if (matches.isNotEmpty) {
          final operation = matches.first.group(1);
          if (readOperationsAllowed && operation == 'read') {
            continue;
          }

          return false; // Found a rule that allows open access.
        }
      }
    }

    return true;
  }
}

/// Checker for Firebase Storage rules that allow access for
/// authenticated users.
class CloudStorageAccessForAuthenticatedUsersChecker
    extends FirebaseRulesChecker {
  /// Creates a new [CloudStorageAccessForAuthenticatedUsersChecker].
  CloudStorageAccessForAuthenticatedUsersChecker()
    : super(
        name: 'Cloud Storage access for all authenticated users',
        type: ServiceType.storage,
        invalidRulesMessage:
            'Cloud Storage rules allow free access to authenticated users',
        ruleUrl:
            'https://firebase.google.com/docs/rules/insecure-rules#access_for_any_authenticated_user',
      );

  @override
  Future<bool> check({
    required String fileContent,
  }) async {
    final regex = RegExp(
      r'allow\s+((read|write|create|update)(\s*,\s*)?){1,4}:\s*if\s*request\.auth\s*!=\s*null;',
    );
    final lines = normalizedLines(fileContent);
    for (final line in lines) {
      if (regex.hasMatch(line)) {
        return false;
      }
    }

    return true;
  }
}
