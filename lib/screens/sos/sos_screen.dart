import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/features/sos/sos_controller.dart';

class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sosControllerProvider);
    final controller = ref.read(sosControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Community'),
        actions: [
          IconButton(
            onPressed: state.isActive ? () => controller.stop() : null,
            icon: const Icon(LucideIcons.square),
            tooltip: 'Stop SOS',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.18),
                  Theme.of(context).colorScheme.surfaceContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    state.isActive ? 'Your SOS is Active' : 'Need Help Fast?',
                    style: text.headlineLarge?.copyWith(
                      color: state.isActive ? Colors.red : colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isActive
                        ? 'Nearby Sahayak users can see your live location now.'
                        : 'Hold the SOS button to instantly alert nearby community helpers.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  _SosButton(
                    enabled: !state.isActive && !state.isStarting,
                    loading: state.isStarting,
                    onPressed: () => controller.start(),
                  ),
                  const SizedBox(height: 10),
                  if (state.isActive)
                    ElevatedButton.icon(
                      onPressed: () => controller.stop(),
                      icon: const Icon(LucideIcons.square),
                      label: const Text('Resolve / Stop SOS'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Active community alerts', style: text.titleLarge),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sos')
                  .where('status', isEqualTo: 'active')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('No active SOS right now'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: ListTile(
                        leading: const Icon(LucideIcons.siren, color: Colors.red),
                        title: Text((d['userId'] as String?) ?? 'User'),
                        subtitle: Text(((d['timestamp'] as Timestamp?)?.toDate().toLocal().toString()) ?? 'Active'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  const _SosButton({
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width.clamp(240.0, 320.0);
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.12),
              ),
            ),
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.22),
              ),
            ),
            GestureDetector(
              onLongPress: enabled ? onPressed : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: enabled ? 1 : 0.6,
                child: Container(
                  width: size * 0.76,
                  height: size * 0.76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFF5C6A),
                        Color(0xFFFF3344),
                      ],
                      radius: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.45),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 42,
                            height: 42,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : Text(
                            'SOS',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              child: Text(
                enabled ? 'Hold to send' : 'Active',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

