import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/domain/models.dart';
import 'package:wordwise/domain/pacing.dart';

void main() {
  const cfg = PacingConfig();

  test('jump grows and is capped', () {
    expect([1, 2, 3, 4, 5, 9].map(cfg.skipSize), [100, 200, 400, 800, 1000, 1000]);
  });

  test('mixing starts only once the window is full and the know-rate drops', () {
    expect(cfg.shouldMix(List.filled(19, Grade.unknown)), isFalse, reason: 'window not full');
    expect(cfg.shouldMix(List.filled(20, Grade.know)), isFalse);
    expect(cfg.shouldMix([...List.filled(14, Grade.know), ...List.filled(6, Grade.issues)]), isFalse, reason: '70 % is the threshold');
    expect(cfg.shouldMix([...List.filled(13, Grade.know), ...List.filled(7, Grade.unknown)]), isTrue);
    expect(cfg.shouldMix([...List.filled(7, Grade.unknown), ...List.filled(30, Grade.know)]), isTrue, reason: 'only the most recent window counts');
  });
}
