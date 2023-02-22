/// {@template dart_identifier_generator}
/// A class that generates valid Dart identifiers.
///
/// See also:
///
/// * Section 17.37 from [Dart Language Specification](https://dart.dev/guides/language/specifications/DartLangSpec-v2.10.pdf)
/// {@endtemplate}
class DartIdentifierGenerator {
  /// {@macro dart_identifier_generator}
  DartIdentifierGenerator([
    this._chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ]) : _nextId = [0];

  final String _chars;
  final List<int> _nextId;

  /// Generate the next short identifier.
  String next() {
    final r = <String>['_', for (final char in _nextId) _chars[char]];
    _increment();
    return r.join();
  }

  void _increment() {
    for (var i = 0; i < _nextId.length; i++) {
      final val = ++_nextId[i];
      if (val >= _chars.length) {
        _nextId[i] = 0;
      } else {
        return;
      }
    }
    _nextId.add(0);
  }
}
