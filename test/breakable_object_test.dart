import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safe_room/game/components/breakable_object.dart';

void main() {
  test('BreakableObject breaks after max health hits and repairs on reset', () {
    final object = BreakableObject(
      id: 'lamp-1',
      position: Vector2(10, 20),
      decorType: BreakableDecorType.lamp,
    );

    expect(object.isBroken, isFalse);
    expect(object.health, BreakableDecorType.lamp.maxHealth);

    object.hit();
    object.update(1.0);
    object.hit();
    expect(object.isBroken, isFalse);

    object.update(1.0);
    object.hit();
    expect(object.isBroken, isTrue);
    expect(object.health, 0);

    object.reset();
    expect(object.isBroken, isFalse);
    expect(object.health, BreakableDecorType.lamp.maxHealth);
  });

  test('BreakableObject state map round-trips type, position, and damage', () {
    final original = BreakableObject(
      id: 'vase-1',
      position: Vector2(120.5, 240.25),
      decorType: BreakableDecorType.vase,
      health: 1,
      isBroken: false,
    );

    final restored = BreakableObject.fromStateMap(original.toStateMap());

    expect(restored.id, 'vase-1');
    expect(restored.decorType, BreakableDecorType.vase);
    expect(restored.position.x, closeTo(120.5, 0.001));
    expect(restored.position.y, closeTo(240.25, 0.001));
    expect(restored.health, 1);
    expect(restored.isBroken, isFalse);
  });
}
