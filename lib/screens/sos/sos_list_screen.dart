import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class SosListScreen extends StatelessWidget {
  const SosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Mesh Log'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No distress signals logged.', style: TextStyle(color: AppTheme.textMuted)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              return _buildSosCard(context, id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildSosCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final type = data['type'] as String? ?? 'Alert';
    final status = data['status'] as String? ?? 'active';
    final isResolved = status == 'resolved';
    
    final timestamp = data['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? timeago.format(timestamp.toDate()) : 'A while ago';
    final userName = data['userName'] as String? ?? 'Unknown';
    final userId = data['userId'] as String?;

    Color getStatusColor() {
      if (isResolved) return AppTheme.textMuted;
      switch (type.toLowerCase()) {
        case 'medical': return Colors.blueAccent;
        case 'police': return Colors.indigoAccent;
        case 'help': return Colors.orangeAccent;
        case 'emergency': default: return AppTheme.danger;
      }
    }

    final accentColor = getStatusColor();
    final canResolve = !isResolved && userId == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isResolved ? Theme.of(context).dividerColor.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          if (!isDark && !isResolved) BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isResolved 
                      ? [AppTheme.textMuted.withValues(alpha: 0.2), AppTheme.textMuted.withValues(alpha: 0.1)]
                      : [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isResolved ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                      color: accentColor,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isResolved ? 'RESOLVED' : type.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1.2
                      ),
                    ),
                  ],
                ),
              ),
              Text(timeStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor.withValues(alpha: 0.1),
                child: Icon(LucideIcons.user, size: 16, color: accentColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isResolved ? AppTheme.textMuted : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Location tracked via Mesh', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
              const Spacer(),
              if (canResolve)
                GestureDetector(
                  onTap: () {
                    FirebaseFirestore.instance.collection('sos').doc(docId).update({'status': 'resolved'});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Resolve', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                )
              else if (!isResolved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Text('ACTIVE', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.2)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
