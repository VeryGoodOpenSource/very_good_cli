import 'dart:async';

import 'package:test/test.dart';
import 'package:very_good_cli/src/mcp/lock.dart';

void main() {
  group('Lock', () {
    test('returns the body result', () async {
      final lock = Lock();
      expect(await lock.run(() async => 42), equals(42));
    });

    test('serializes any number of concurrent runs', () async {
      final lock = Lock();
      var active = 0;
      var maxActive = 0;

      Future<void> body() async {
        active++;
        if (active > maxActive) maxActive = active;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
      }

      await Future.wait([
        lock.run(body),
        lock.run(body),
        lock.run(body),
        lock.run(body),
      ]);

      expect(maxActive, equals(1));
    });

    test('runs bodies in FIFO order', () async {
      final lock = Lock();
      final order = <int>[];

      final futures = [
        for (var i = 0; i < 4; i++)
          lock.run(() async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            order.add(i);
          }),
      ];
      await Future.wait(futures);

      expect(order, equals([0, 1, 2, 3]));
    });

    test('a failing body does not break the queue', () async {
      final lock = Lock();
      final order = <String>[];

      final failing = lock.run(() async {
        order.add('failing');
        throw Exception('boom');
      });

      final next = lock.run(() async => order.add('next'));

      await expectLater(failing, throwsException);
      await next;
      expect(order, equals(['failing', 'next']));
    });
  });
}
