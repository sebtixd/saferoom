import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/local/room_customization_storage.dart';
import '../../domain/entities/room_background.dart';
import '../../domain/repositories/user_repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class RoomCustomizationShop extends StatefulWidget {
  final String userId;
  final RoomCustomizationStorage storage;
  final UserRepository userRepository;
  final VoidCallback onClose;
  final void Function(RoomBackground background) onBackgroundEquipped;

  const RoomCustomizationShop({
    super.key,
    required this.userId,
    required this.storage,
    required this.userRepository,
    required this.onClose,
    required this.onBackgroundEquipped,
  });

  @override
  State<RoomCustomizationShop> createState() =>
      _RoomCustomizationShopState();
}

class _RoomCustomizationShopState extends State<RoomCustomizationShop> {
  List<RoomBackground> _backgrounds = const [];
  String _selectedId = RoomCustomizationStorage.defaultBackgroundId;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await widget.storage.load(widget.userId);
    if (!mounted) return;
    setState(() {
      _backgrounds = state.backgrounds;
      _selectedId = state.equippedBackgroundId;
      _loading = false;
    });
  }

  RoomBackground get _selected => _backgrounds.firstWhere(
        (item) => item.id == _selectedId,
        orElse: () => _backgrounds.first,
      );

  Future<void> _saveAndNotify(List<RoomBackground> backgrounds) async {
    await widget.storage.save(widget.userId, backgrounds);
    final equipped = backgrounds.firstWhere((item) => item.equipped);
    widget.onBackgroundEquipped(equipped);
    if (!mounted) return;
    setState(() => _backgrounds = backgrounds);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _buy(RoomBackground background) async {
    if (_busy || background.owned) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (authState.user.points < background.price) {
      _message('Not enough balance to buy ${background.name}.');
      return;
    }

    setState(() => _busy = true);
    try {
      final updatedUser = authState.user.copyWith(
        points: authState.user.points - background.price,
      );
      context.read<AuthBloc>().add(AuthUpdateUser(updatedUser));
      await widget.userRepository.updateUser(updatedUser);

      final updated = _backgrounds
          .map(
            (item) => item.id == background.id
                ? item.copyWith(owned: true)
                : item,
          )
          .toList(growable: false);
      await _saveAndNotify(updated);
      _message('${background.name} unlocked!');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _equip(RoomBackground background) async {
    if (_busy || !background.owned) return;
    setState(() => _busy = true);
    try {
      final updated = _backgrounds
          .map((item) => item.copyWith(equipped: item.id == background.id))
          .toList(growable: false);
      await _saveAndNotify(updated);
      _message('${background.name} equipped.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final points = authState is AuthAuthenticated ? authState.user.points : 0;
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: size.width * 0.94,
              height: size.height * 0.86,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2430),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFC857), width: 2),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(points),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: _previewPanel()),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: _itemsPanel(points)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(int points) {
    return Row(
      children: [
        const Icon(Icons.storefront, color: Color(0xFFFFC857)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Room Customization Shop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFFFFC857), size: 18),
              const SizedBox(width: 6),
              Text(
                '\$${(points / 100).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _previewPanel() {
    final background = _selected;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Preview',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/${background.assetPath}',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                cacheWidth: 900,
                errorBuilder: (_, error, stackTrace) => Container(
                  color: const Color(0xFF394055),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            background.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            background.description,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          _actionButton(background),
        ],
      ),
    );
  }

  Widget _actionButton(RoomBackground background) {
    final authState = context.watch<AuthBloc>().state;
    final points = authState is AuthAuthenticated ? authState.user.points : 0;
    if (background.equipped) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: const Text('Equipped'),
      );
    }
    if (background.owned) {
      return ElevatedButton.icon(
        onPressed: _busy ? null : () => _equip(background),
        icon: const Icon(Icons.wallpaper),
        label: const Text('Equip'),
      );
    }
    final canAfford = points >= background.price;
    final priceLabel = '\$${(background.price / 100).toStringAsFixed(2)}';
    return ElevatedButton.icon(
      onPressed: _busy || !canAfford ? null : () => _buy(background),
      icon: const Icon(Icons.shopping_cart),
      label: Text(
        canAfford ? 'Buy for $priceLabel' : 'Need $priceLabel',
      ),
    );
  }

  Widget _itemsPanel(int points) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: _backgrounds.length,
      itemBuilder: (context, index) {
        final background = _backgrounds[index];
        final selected = background.id == _selectedId;
        final canAfford = points >= background.price;
        return InkWell(
          onTap: () => setState(() => _selectedId = background.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF2D3650) : Colors.black26,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFFC857)
                    : Colors.white24,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/${background.assetPath}',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 400,
                      errorBuilder: (_, error, stackTrace) => Container(
                        color: const Color(0xFF394055),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  background.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _statusChip(background, canAfford),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(RoomBackground background, bool canAfford) {
    String label;
    Color color;
    if (background.equipped) {
      label = 'Equipped';
      color = const Color(0xFF66BB6A);
    } else if (background.owned) {
      label = 'Owned';
      color = const Color(0xFF64B5F6);
    } else {
      label = '\$${(background.price / 100).toStringAsFixed(2)}';
      color = canAfford ? const Color(0xFFFFC857) : const Color(0xFFEF5350);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
    );
  }
}
