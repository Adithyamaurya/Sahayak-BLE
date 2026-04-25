import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/services/permission_service.dart';
import 'package:sahayak/theme.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _loading = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final ok = await PermissionService.areMandatoryGranted();
    if (!mounted) return;
    setState(() => _blocked = !ok);
    if (ok) context.go('/home');
  }

  Future<void> _request() async {
    setState(() => _loading = true);
    await PermissionService.requestAll();
    if (!mounted) return;
    setState(() => _loading = false);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Icon(LucideIcons.shieldAlert, size: 44, color: AppTheme.primary),
              const SizedBox(height: 14),
              Text(
                'Required to keep you safe',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Location + Notifications are mandatory for SOS alerts.\nBluetooth is optional for nearby user proximity.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _PermissionTile(
                icon: LucideIcons.mapPin,
                title: 'Location',
                subtitle: 'Used for SOS + live tracking',
                required: true,
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                icon: LucideIcons.bell,
                title: 'Notifications',
                subtitle: 'Nearby SOS + emergency pings',
                required: true,
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                icon: LucideIcons.bluetooth,
                title: 'Bluetooth',
                subtitle: 'Optional: BLE proximity scan',
                required: false,
              ),
              const Spacer(),
              if (_blocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Text(
                    'Permissions not granted. The app cannot continue until mandatory permissions are allowed.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _request,
                child: Text(_loading ? 'Requesting…' : 'Grant permissions'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool required;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.required,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    if (required)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          'Required',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

