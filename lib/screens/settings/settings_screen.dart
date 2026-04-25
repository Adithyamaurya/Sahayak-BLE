import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/providers/theme_mode_provider.dart';
import 'package:sahayak/theme.dart';
import 'package:sahayak/services/auth_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _auth = AuthService();
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _ProfileSection(user: user),
          const SizedBox(height: 32),

          _buildSettingsGroup(
            title: 'Account',
            children: [
              _buildModernTile(
                icon: LucideIcons.user,
                title: 'Edit Profile',
                subtitle: 'Personal information',
                onTap: () => _showEditProfile(context),
              ),
              _buildDivider(context),
              _buildModernTile(
                icon: LucideIcons.users,
                title: 'Emergency Contacts',
                subtitle: 'Manage native contacts',
                iconColor: AppTheme.danger,
                onTap: () => _showEmergencyContacts(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSettingsGroup(
            title: 'Preferences',
            children: [
              _buildModernTile(
                icon: isDark ? LucideIcons.moon : LucideIcons.sun,
                title: 'Appearance',
                subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                iconColor: isDark ? AppTheme.accent : Colors.orangeAccent,
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: AppTheme.primary,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ),
              _buildDivider(context),
              _buildModernTile(
                icon: LucideIcons.bell,
                title: 'Push Alerts',
                subtitle: _notificationsEnabled ? 'Enabled' : 'Muted',
                iconColor: AppTheme.primary,
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    // Native notification toggling logic would sit here
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          
          _buildSettingsGroup(
            title: 'Privacy & Data',
            children: [
              _buildModernTile(
                icon: LucideIcons.history,
                title: 'SOS History',
                subtitle: 'Past emergency logs',
                onTap: () => _showSosHistory(context),
              ),
              _buildDivider(context),
              _buildModernTile(
                icon: LucideIcons.shieldCheck,
                title: 'Privacy Policy',
                subtitle: 'Legal and data usage',
                iconColor: Colors.teal,
                onTap: () => _showPrivacyPolicy(context),
              ),
            ],
          ),

          const SizedBox(height: 48),
          
          GestureDetector(
            onTap: () async {
              await _auth.signOut();
              if (mounted) context.go('/login');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: AppTheme.danger, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100), // Navigation spacing
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.2 : 0.05)),
            boxShadow: [
               if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
    );
  }

  Widget _buildModernTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final iColor = iconColor ?? AppTheme.textMuted;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            trailing ?? (onTap != null ? const Icon(LucideIcons.chevronRight, size: 18, color: AppTheme.textMuted) : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EditProfileSheet(),
    );
  }
  
  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EmergencyContactsSheet(),
    );
  }
  
  void _showSosHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SosHistorySheet(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BaseSheet(
        title: 'Privacy Policy',
        children: [
          SizedBox(
            height: 400,
            child: SingleChildScrollView(
              child: Text(
                '''Data Collection & Usage:\nSahayak actively collects background GPS data to facilitate mesh network tracking and emergency dispatching. Your location data is synced strictly to authenticated active distress calls.\n\nPersonal Details:\nYour phone number and name are visible to emergency respondents. Contact lists are only stored locally or within your private authenticated database space to alert guardians.\n\nBluetooth Proximity:\nYour device scans for BLE devices nearby to build peer-to-peer connection paths in offline scenarios.\n\nBy continuing to use Sahayak, you consent to background tracking during emergency phases.''',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final User? user;
  const _ProfileSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.6 : 1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.2 : 0.05)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF00FFD1), Color(0xFF00BFAF)]),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10)],
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: const Icon(LucideIcons.user, size: 36, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: user != null 
                ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
                : const Stream.empty(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final displayName = data?['displayName'] as String? ?? user?.displayName ?? 'Anonymous User';
                final phone = data?['phone'] as String? ?? user?.phoneNumber ?? 'No phone added';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheets for refined implementation

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }
  
  Future<void> _loadExistingProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _name.text = data['displayName'] as String? ?? user.displayName ?? '';
          _phone.text = data['phone'] as String? ?? user.phoneNumber ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      title: 'Edit Profile',
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(LucideIcons.user)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(LucideIcons.phone)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'displayName': _name.text.trim(),
                'phone': _phone.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 72),
      ],
      
    );
  }
}

class _EmergencyContactsSheet extends StatelessWidget {
  const _EmergencyContactsSheet();

  Future<void> _importContact(BuildContext context, String uid) async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.readWrite);
      if (status != PermissionStatus.granted) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
        return;
      }
      
      final contactId = await FlutterContacts.native.showPicker();
      if (contactId != null) {
        final contact = await FlutterContacts.get(contactId, properties: ContactProperties.all);
        if (contact != null && contact.phones.isNotEmpty) {
           final phoneStr = contact.phones.first.number;
           await FirebaseFirestore.instance.collection('users').doc(uid).collection('contacts').add({
             'name': contact.displayName,
             'phone': phoneStr,
             'createdAt': FieldValue.serverTimestamp(),
           });
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${contact.displayName}!')));
        } else {
           if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected contact has no phone number.')));
        }
      }
    } catch (e) {
       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _BaseSheet(
      title: 'Guardians',
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _importContact(context, uid),
            icon: const Icon(LucideIcons.contact, color: Colors.white),
            label: const Text('Add contacts as Emergency', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('ACTIVE CONTACTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: AppTheme.textMuted)),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('contacts').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No guardians imported yet.', style: TextStyle(color: AppTheme.textMuted)));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.danger.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.user, color: AppTheme.danger, size: 18),
                      ),
                      title: Text(data['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(data['phone'] as String? ?? '', style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 20, color: AppTheme.danger),
                        onPressed: () => docs[i].reference.delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SosHistorySheet extends StatelessWidget {
  const _SosHistorySheet();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _BaseSheet(
      title: 'SOS Activity',
      children: [
        SizedBox(
          height: 400,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('sos').where('userId', isEqualTo: uid).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text('No recent emergency activity.'));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      leading: Icon(
                        (d['status'] as String?) == 'active' ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
                        color: (d['status'] as String?) == 'active' ? AppTheme.danger : AppTheme.accent,
                      ),
                      title: Text(d['status'] as String? ?? 'Alert'),
                      subtitle: Text(((d['timestamp'] as Timestamp?)?.toDate().toLocal().toString()) ?? 'Active'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BaseSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _BaseSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(LucideIcons.x, color: AppTheme.textMuted),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.textMuted.withValues(alpha: 0.1)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }
}
