import 'package:flutter_test/flutter_test.dart';
import 'package:safe_room/game/components/player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all player sprites load through Flame with the correct frame size', () async {
    expect(Player.spriteFiles.length, 8);

    for (final path in Player.spriteFiles) {
      final image = await Player.spriteImages.load(path);
      expect(image.width, 50, reason: 'Wrong width for $path');
      expect(image.height, 65, reason: 'Wrong height for $path');
    }
  });
}
