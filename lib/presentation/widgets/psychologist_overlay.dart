import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/local/notes_storage.dart';
import '../../domain/entities/note_page.dart';
import '../../domain/repositories/user_repository.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

/// Paid feature: contact a psychologist who can read notes and give advice.
/// Unlock is persisted per user by caller; this widget handles UI/flow.
class PsychologistOverlay extends StatefulWidget {
  final String userId;
  final NotesStorage notesStorage;
  final UserRepository userRepository;
  final bool unlocked;
  final Future<void> Function() onUnlock;
  final VoidCallback onClose;

  const PsychologistOverlay({
    super.key,
    required this.userId,
    required this.notesStorage,
    required this.userRepository,
    required this.unlocked,
    required this.onUnlock,
    required this.onClose,
  });

  @override
  State<PsychologistOverlay> createState() => _PsychologistOverlayState();
}

class _PsychologistOverlayState extends State<PsychologistOverlay> {
  bool _loadingNotes = true;
  bool _unlocking = false;
  bool _requesting = false;
  bool _requestSent = false;
  List<NotePage> _pages = const [];
  final TextEditingController _messageController = TextEditingController();

  static const double priceUsd = 4.99;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final pages = await widget.notesStorage.loadPages(widget.userId);
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _loadingNotes = false;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _buy() async {
    if (_unlocking || widget.unlocked) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _unlocking = true);
    try {
      // UI shows real-money price; unlock is persisted by caller.
      await widget.onUnlock();
      _snack('Psychologist feature unlocked!');
    } catch (e) {
      _snack('Could not unlock feature: $e');
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _sendRequest() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _requestSent = true;
    });
    _snack('Your request was sent to the psychologist.');
  }

  String _adviceForNotes() {
    final text = _pages.map((p) => p.content).join('\n').toLowerCase();
    if (text.trim().isEmpty) {
      return 'I do not see notes yet. Try writing what you feel in your notebook, then come back. Small reflections can help you notice patterns and needs.';
    }
    if (text.contains('anx') || text.contains('stress') || text.contains('worry')) {
      return 'I notice signs of stress or anxiety in your notes. Try grounding: name 5 things you see, 4 you feel, 3 you hear. Be gentle with yourself and take one small step at a time.';
    }
    if (text.contains('sad') || text.contains('lonely') || text.contains('tired')) {
      return 'Your notes sound heavy. It may help to rest, reach out to someone you trust, and do one kind thing for yourself today. Your feelings are valid.';
    }
    if (text.contains('angry') || text.contains('mad') || text.contains('frustrat')) {
      return 'I hear frustration in your notes. A pause, slow breathing, or writing what you need can help before reacting. It is okay to feel angry; what matters is how you care for yourself.';
    }
    return 'Thank you for sharing your notes. I see your effort in reflecting. Keep tracking your feelings, celebrate small wins, and ask for support when you need it.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              height: MediaQuery.of(context).size.height * 0.86,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF8B5E3C), width: 2),
              ),
              child: widget.unlocked ? _unlockedView() : _lockedView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lockedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 16),
        const Icon(Icons.lock_outline, size: 64, color: Color(0xFF8B5E3C)),
        const SizedBox(height: 16),
        const Text(
          'Psychologist Support (Premium)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E1B14)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Contact a psychologist who can read your notebook notes and give you personalized advice. This is a paid feature.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFF4A3728)),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _unlocking ? null : _buy,
          icon: _unlocking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.payment),
          label: Text(_unlocking ? 'Unlocking...' : 'Unlock for \$${priceUsd.toStringAsFixed(2)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5E3C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Price shown as real money. No real payment is processed in this demo build.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _unlockedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              _psychologistCard(),
              const SizedBox(height: 12),
              _notesCard(),
              const SizedBox(height: 12),
              _adviceCard(),
              const SizedBox(height: 12),
              _contactCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.psychology, color: Color(0xFF8B5E3C)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Contact a Psychologist',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E1B14)),
          ),
        ),
        IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _psychologistCard() {
    return _card(
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFD7CCC8),
            child: Icon(Icons.person, color: Color(0xFF5D4037), size: 32),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. Maya Rivera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Licensed Psychologist • SafeRoom Support', style: TextStyle(color: Colors.black54)),
                SizedBox(height: 4),
                Text('“I can review your notes and offer supportive advice.”'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes visible to psychologist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (_loadingNotes)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (_pages.isEmpty)
            const Text('No saved notes yet. Your psychologist will see notes once you save them.', style: TextStyle(color: Colors.black54))
          else
            ..._pages.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD7CCC8)),
                    ),
                    child: Text(
                      p.content.trim().isEmpty ? '(Empty page)' : p.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
          if (_pages.length > 3)
            Text('+ ${_pages.length - 3} more page(s)', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _adviceCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Advice based on your notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_adviceForNotes()),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send a message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write what you want to talk about...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFFFFDF8),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _requesting ? null : _sendRequest,
            icon: _requesting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_requestSent ? 'Send another message' : 'Contact Psychologist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5E3C),
              foregroundColor: Colors.white,
            ),
          ),
          if (_requestSent)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Request sent. A psychologist will review your notes and message.', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7CCC8)),
      ),
      child: child,
    );
  }
}
