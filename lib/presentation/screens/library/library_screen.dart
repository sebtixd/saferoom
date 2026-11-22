import 'package:material_ui/material_ui.dart';

import '../../../data/datasources/local/room_customization_storage.dart';
import '../../../domain/entities/room_background.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../injection_container.dart' as di;
import '../../widgets/room_customization_shop.dart';

/// Library screen: a cozy place to browse room themes and customize the room.
class LibraryScreen extends StatefulWidget {
  final String userId;
  final void Function(RoomBackground background)? onBackgroundEquipped;

  const LibraryScreen({
    super.key,
    required this.userId,
    this.onBackgroundEquipped,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _showShop = false;

  void _openShop() => setState(() => _showShop = true);
  void _closeShop() => setState(() => _showShop = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          TextButton.icon(
            onPressed: _openShop,
            icon: const Icon(Icons.storefront),
            label: const Text('Customize Room'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/library_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => const ColoredBox(
                color: Color(0xFF3E2723),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Cozy Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Collect room themes and make your SafeRoom feel like yours.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wallpaper),
                  title: const Text('Room Customization Shop'),
                  subtitle: const Text(
                    'Buy and equip room backgrounds with real money.',
                  ),
                  trailing: ElevatedButton(
                    onPressed: _openShop,
                    child: const Text('Open Shop'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.menu_book),
                  title: Text('Reading Nook'),
                  subtitle: Text(
                    'More library features can live here later. For now, use the shop to customize your room.',
                  ),
                ),
              ),
            ],
          ),
          if (_showShop)
            RoomCustomizationShop(
              userId: widget.userId,
              storage: di.sl<RoomCustomizationStorage>(),
              userRepository: di.sl<UserRepository>(),
              onClose: _closeShop,
              onBackgroundEquipped: (background) {
                widget.onBackgroundEquipped?.call(background);
              },
            ),
        ],
      ),
    );
  }
}
