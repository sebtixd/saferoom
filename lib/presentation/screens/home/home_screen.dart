import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';

import '../../../data/datasources/local/local_storage_service.dart';
import '../../../data/datasources/local/notes_storage.dart';
import '../../../data/datasources/local/room_customization_storage.dart';
import '../../../domain/entities/room_background.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../game/components/breakable_object.dart';
import '../../../game/safe_room_game.dart';
import '../../../injection_container.dart' as di;
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/task/task_bloc.dart';
import '../../blocs/task/task_event.dart';
import '../../blocs/task/task_state.dart';
import '../library/library_screen.dart';
import '../../widgets/notes_overlay.dart';
import '../../widgets/psychologist_overlay.dart';
import '../../widgets/shop_overlay.dart';
import '../../widgets/task_list_widget.dart';

/// Full-screen game - PORTRAIT MODE (default)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showNotes = false;
  bool _showTasks = false;
  bool _showShop = false;
  bool _showPsychologist = false;
  bool _psychologistUnlocked = false;
  bool _placementMode = false;
  BreakableDecorType? _pendingDecorType;
  bool _wasAllTasksComplete = false;

  late SafeRoomGame _game;
  String _roomBackgroundAsset = 'room_background.png';

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthAuthenticated) ? authState.user.id : 'guest';

    _game = SafeRoomGame(
      userId: userId,
      localStorage: di.sl<LocalStorageService>(),
      initialRoomBackground: _roomBackgroundAsset,
      onDeskInteraction: _handleDeskInteraction,
      onCouchInteraction: (_) {},
      onCouchProximity: (isNear) {
        if (_showTasks != isNear) {
          setState(() => _showTasks = isNear);
        }
      },
      onShopInteraction: (isInside) {
        if (_showShop != isInside && !_placementMode) {
          setState(() => _showShop = isInside);
        }
      },
      onLibraryInteraction: _handleLibraryInteraction,
    );
    _loadRoomBackground(userId);
    _loadPsychologistUnlock(userId);
  }

  Future<void> _loadRoomBackground(String userId) async {
    final storage = di.sl<RoomCustomizationStorage>();
    final equipped = await storage.getEquipped(userId);
    if (!mounted) return;
    setState(() {
      _roomBackgroundAsset = equipped.assetPath;
    });
    await _game.setRoomBackground(equipped.assetPath);
  }

  Future<void> _loadPsychologistUnlock(String userId) async {
    final local = di.sl<LocalStorageService>();
    final unlocked = await local.getBool(_psychologistKey(userId)) ?? false;
    if (!mounted) return;
    setState(() => _psychologistUnlocked = unlocked);
  }

  String _psychologistKey(String userId) =>
      'psychologist_unlocked_${userId.isEmpty ? 'guest' : userId}';

  Future<void> _unlockPsychologist() async {
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthAuthenticated) ? authState.user.id : 'guest';
    await di.sl<LocalStorageService>().saveBool(_psychologistKey(userId), true);
    if (!mounted) return;
    setState(() => _psychologistUnlocked = true);
  }

  Future<void> _openLibrary() async {
    final authState = context.read<AuthBloc>().state;
    final userId = (authState is AuthAuthenticated) ? authState.user.id : 'guest';
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibraryScreen(
          userId: userId,
          onBackgroundEquipped: _onBackgroundEquipped,
        ),
      ),
    );
  }

  void _onBackgroundEquipped(RoomBackground background) {
    setState(() => _roomBackgroundAsset = background.assetPath);
    _game.setRoomBackground(background.assetPath);
  }

  void _handleDeskInteraction(bool isNearDesk) {
    if (isNearDesk && !_showNotes) {
      setState(() => _showNotes = true);
    }
  }

  void _closeNotes() {
    setState(() => _showNotes = false);
  }

  void _handleLibraryInteraction(bool isNearLibrary) {
    if (isNearLibrary && !_showPsychologist) {
      setState(() => _showPsychologist = true);
    }
  }

  void _closePsychologist() {
    setState(() => _showPsychologist = false);
  }
  
  // -- SHOP LOGIC --

  Future<void> _buyDecor(BreakableDecorType type) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    if (authState.user.points < type.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough points for ${type.label}.')),
      );
      return;
    }

    final userRepo = di.sl<UserRepository>();
    final updatedUser = authState.user.copyWith(
      points: authState.user.points - type.cost,
    );

    // Update UI immediately, then persist remotely.
    context.read<AuthBloc>().add(AuthUpdateUser(updatedUser));
    await userRepo.updateUser(updatedUser);
    if (!mounted) return;

    setState(() {
      _showShop = false;
      _placementMode = true;
      _pendingDecorType = type;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tap anywhere on the floor to place ${type.label}.'),
      ),
    );
  }

  Future<void> _handleTap(TapUpDetails details) async {
    if (!_placementMode || _pendingDecorType == null) return;
    final tapPosition = Vector2(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    final placedType = _pendingDecorType!;
    await _game.placeDecor(placedType, tapPosition);
    if (!mounted) return;
    setState(() {
      _placementMode = false;
      _pendingDecorType = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${placedType.label} placed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userPoints = (authState is AuthAuthenticated) ? authState.user.points : 0;
    final userId = (authState is AuthAuthenticated) ? authState.user.id : 'guest';
  
    return BlocProvider(
      create: (context) => di.sl<TaskBloc>()..add(const LoadDailyTasks()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Full-screen game in PORTRAIT
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: _handleTap,
                  child: GameWidget(game: _game),
                ),
              ),
              
              Positioned(
                top: 16,
                left: 16,
                child: ElevatedButton.icon(
                  onPressed: _openLibrary,
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Library'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              // Placement Mode Indicator
              if (_placementMode)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.black54,
                      child: Text(
                        'PLACEMENT MODE - Tap to place ${_pendingDecorType?.label ?? 'decor'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Shop Overlay (Top Right)
              if (_showShop && !_placementMode)
                Positioned(
                  top: 50,
                  right: 20,
                  child: ShopOverlay(
                    userPoints: userPoints,
                    onBuy: _buyDecor,
                    onClose: () => setState(() => _showShop = false),
                  ),
                ),
              
              // Daily Tasks Overlay (Only when Sitting)
              if (_showTasks && !_showShop && !_placementMode)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: BlocConsumer<TaskBloc, TaskState>(
                    listener: (context, state) async {
                      if (state is TaskLoaded) {
                        // FIX 2: Check for point updates!
                        // Fetch fresh user data whenever tasks update (completion/load)
                        if (authState is AuthAuthenticated) {
                           final userRepo = di.sl<UserRepository>();
                           final result = await userRepo.getUserById(authState.user.id);
                           if (!context.mounted) return;
                           result.fold(
                             (l) => null,
                             (freshUser) {
                               if (freshUser.points != authState.user.points) {
                                 context.read<AuthBloc>().add(AuthUpdateUser(freshUser));
                               }
                             }
                           );
                        }

                        final allCompleted = state.dailyTask.tasks.isNotEmpty &&
                            state.dailyTask.tasks.every((t) => t.completed);
                        final justCompleted = allCompleted && !_wasAllTasksComplete;
                        _wasAllTasksComplete = allCompleted;

                        if (justCompleted) {
                          _game.resetBreakableObject();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'All tasks done! Your broken decor has been repaired.',
                              ),
                            ),
                          );
                        }
                      } else if (state is TaskError) {
                        _wasAllTasksComplete = false;
                      }
                    },
                    builder: (context, state) {
                      if (state is TaskLoaded) {
                        return TaskListWidget(
                          tasks: state.dailyTask.tasks,
                          dailyTaskId: state.dailyTask.id,
                        );
                      } else if (state is TaskLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is TaskError) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.withValues(alpha: 0.5),
                          child: Text(
                            'Error: ${state.message}', 
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

              // Notes overlay (persistent, paginated notebook)
              if (_showNotes)
                NotesOverlay(
                  onClose: _closeNotes,
                  userId: userId,
                  storage: di.sl<NotesStorage>(),
                ),

              // Psychologist overlay (paid feature, near background library)
              if (_showPsychologist)
                PsychologistOverlay(
                  userId: userId,
                  notesStorage: di.sl<NotesStorage>(),
                  userRepository: di.sl<UserRepository>(),
                  unlocked: _psychologistUnlocked,
                  onUnlock: _unlockPsychologist,
                  onClose: _closePsychologist,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
