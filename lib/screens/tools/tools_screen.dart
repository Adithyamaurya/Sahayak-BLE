import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/theme.dart';
import 'package:sahayak/screens/proximity/direction_pointer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  // Logic states
  bool _isStrobeOn = false;
  Timer? _strobeTimer;

  @override
  void dispose() {
    _strobeTimer?.cancel();
    super.dispose();
  }

  // --- Real Functionalities ---

  Future<void> _makeCall(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _toggleStrobe() async {
    try {
      bool hasFlash = await TorchLight.isTorchAvailable();
      if (!hasFlash) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flashlight not available on this device.')));
        return;
      }

      setState(() => _isStrobeOn = !_isStrobeOn);

      if (_isStrobeOn) {
        _strobeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          if (timer.tick % 2 == 0) {
            await TorchLight.enableTorch();
          } else {
            await TorchLight.disableTorch();
          }
        });
      } else {
        _strobeTimer?.cancel();
        await TorchLight.disableTorch();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openCompass(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectionPointerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Text(
                'Tools & Utilities',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling hardware tools
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildSquareToolCard(
                  context,
                  title: 'Flashlight',
                  icon: LucideIcons.flashlight,
                  color: _isStrobeOn ? Colors.orange : AppTheme.primary,
                  status: _isStrobeOn ? 'ACTIVE' : 'Ready',
                  isPulsing: _isStrobeOn,
                  onTap: _toggleStrobe,
                ),
                const SizedBox(width: 16),
                _buildSquareToolCard(
                  context,
                  title: 'Compass',
                  icon: LucideIcons.compass,
                  color: Colors.cyanAccent,
                  status: 'Calibrated',
                  isPulsing: false,
                  onTap: () => _openCompass(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          Row(
            children: [
              Container(width: 4, height: 20, color: AppTheme.danger),
              const SizedBox(width: 8),
              const Text(
                'QUICK CONNECTIONS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildMassiveCallBlock(
            context,
            label: 'POLICE DISPATCH',
            number: '100',
            icon: LucideIcons.shieldAlert,
            gradientColors: [Colors.indigo, Colors.indigoAccent],
            onTap: () => _makeCall('100'),
          ),
          const SizedBox(height: 16),
          _buildMassiveCallBlock(
            context,
            label: 'AMBULANCE & MEDICAL',
            number: '108',
            icon: LucideIcons.cross,
            gradientColors: [Colors.blue, Colors.lightBlueAccent],
            onTap: () => _makeCall('108'),
          ),
          const SizedBox(height: 16),
          _buildMassiveCallBlock(
            context,
            label: 'NATIONAL EMERGENCY',
            number: '112',
            icon: LucideIcons.phoneCall,
            gradientColors: [ AppTheme.danger,  Colors.redAccent],
            onTap: () => _makeCall('112'),
          ),
          const SizedBox(height: 16),
          _buildMassiveCallBlock(
            context,
            label: 'FIRE BRIGADE',
            number: '101',
            icon: LucideIcons.phoneCall,
            gradientColors: [const Color.fromARGB(255, 195, 42, 255), const Color.fromARGB(255, 255, 82, 235)],
            onTap: () => _makeCall('101'),
          ),
          const SizedBox(height: 16),
          _buildMassiveCallBlock(
            context,
            label: 'WOMEN HELPLINE',
            number: '1098',
            icon: LucideIcons.phoneCall,
            gradientColors: [const Color.fromARGB(255, 223, 255, 42), const Color.fromARGB(255, 255, 252, 82)],
            onTap: () => _makeCall('1098'),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareToolCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String status,
    required bool isPulsing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.8 : 1),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isPulsing ? color.withValues(alpha: 0.5) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: isPulsing ? 2 : 1,
          ),
          boxShadow: [
            if (isPulsing) BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5),
            if (!isDark && !isPulsing) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isPulsing) ...[
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: isPulsing ? color : AppTheme.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMassiveCallBlock(BuildContext context, {
    required String label,
    required String number,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientColors[0].withValues(alpha: 0.9), gradientColors[1].withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.phoneOutgoing, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}