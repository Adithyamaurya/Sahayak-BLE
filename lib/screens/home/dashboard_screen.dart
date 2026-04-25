import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sahayak/features/sos/sos_controller.dart';
import 'package:sahayak/services/firestore_service.dart';
import 'package:sahayak/services/nearby_service.dart';
import 'package:sahayak/theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // Compass State
  bool _compassExpanded = false;
  double _heading = 0;
  Position? _currentPos;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Compass & Location Hooks
    magnetometerEventStream().listen((event) {
      double heading = atan2(event.y, event.x) * (180 / pi) + 90;
      if (heading < 0) heading += 360;
      if (mounted) setState(() => _heading = heading);
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((pos) {
      if (mounted) setState(() => _currentPos = pos);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double dLon = (lon2 - lon1) * pi / 180;
    lat1 = lat1 * pi / 180;
    lat2 = lat2 * pi / 180;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sosState = ref.watch(sosControllerProvider);
    final sosController = ref.read(sosControllerProvider.notifier);
    final nearbyCount = ref.watch(nearbyServiceProvider).streamNearbyDeviceCount();

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SAHAYAK',
              style: theme.textTheme.titleSmall?.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const Text(
              'A.W.A.R.E. NETWORK LIVE',
              style: TextStyle(fontSize: 9, color: AppTheme.accent, letterSpacing: 2, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Berserk Background Glow
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (sosState.isActive ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Live Status Bar (Ultra Sleek)
                        StreamBuilder<int>(
                          stream: nearbyCount,
                          builder: (context, snap) {
                            final count = (snap.data ?? 0) + 8; // Simulated floor
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('NETWORK STATUS', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1.5)),
                                      const SizedBox(height: 4),
                                      Text('$count NODES ACTIVE', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.radio, color: AppTheme.accent, size: 20),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                        
                        const SizedBox(height: 24),

                        // Expandable Rescue Compass Module
                        _buildExpandableCompass(),

                        const SizedBox(height: 32),

                        // Berserk SOS Button
                        _buildBerserkSos(sosState, sosController),

                        const SizedBox(height: 48),
                        
                        // ACTIVE ALERTS FEED (Sleek List)
                        Row(
                          children: [
                            const Icon(LucideIcons.activity, color: AppTheme.accent, size: 16),
                            const SizedBox(width: 8),
                            const Text('INCIDENT FEED', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirestoreService().streamActiveAlerts(),
                          builder: (context, snap) {
                            final alerts = snap.data ?? [];
                            if (alerts.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: const Center(child: Text('NO LOCAL INCIDENTS', style: TextStyle(color: AppTheme.textMuted, letterSpacing: 1))),
                              );
                            }
                            return Column(
                              children: alerts.map((a) => _buildAlertCard(context, a)).toList(),
                            );
                          }
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCompass() {
    // We will just grab the first incident for this mockup compass target
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().streamActiveAlerts(),
      builder: (context, snap) {
        final alerts = snap.data ?? [];
        final hasAlert = alerts.isNotEmpty;

        double targetBearing = 0;
        double targetDist = 0;

        if (hasAlert && _currentPos != null) {
          final target = alerts.first['location']; // Assuming firestore structure has location map
          if (target != null && target['lat'] != null) {
            targetBearing = _calculateBearing(_currentPos!.latitude, _currentPos!.longitude, target['lat'], target['lng']);
            targetDist = Geolocator.distanceBetween(_currentPos!.latitude, _currentPos!.longitude, target['lat'], target['lng']);
          }
        }

        return GestureDetector(
          onTap: () => setState(() => _compassExpanded = !_compassExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: hasAlert ? AppTheme.danger.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: hasAlert ? AppTheme.danger.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
              boxShadow: hasAlert ? [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.1), blurRadius: 30, spreadRadius: -5)] : [],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(hasAlert ? LucideIcons.loader : LucideIcons.compass, color: hasAlert ? AppTheme.danger : AppTheme.primary, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasAlert ? 'EMERGENCY DETECTED' : 'RESCUE COMPASS',
                              style: TextStyle(color: hasAlert ? AppTheme.danger : Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                            ),
                            Text(
                              hasAlert ? 'Target ${(targetDist/1000).toStringAsFixed(1)}km away' : 'Tap to initialize tracking',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(_compassExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: AppTheme.textMuted),
                  ],
                ),
                
                // Expanding Compass Area
                AnimatedCrossFade(
                  firstChild: const SizedBox(height: 0, width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 16),
                    child: SizedBox(
                      height: 220,
                      width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base Ring
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                            ),
                          ),
                          Container(
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
                            ),
                          ),
                          
                          // The Needle (Points to target if alert, else North)
                          Transform.rotate(
                            angle: hasAlert ? ((targetBearing - _heading) * pi / 180) : ((0 - _heading) * pi / 180),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4, height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                          colors: [hasAlert ? AppTheme.danger : AppTheme.accent, Colors.transparent],
                                        ),
                                        boxShadow: [
                                          BoxShadow(color: (hasAlert ? AppTheme.danger : AppTheme.accent).withValues(alpha: 0.6), blurRadius: 10)
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 90), // Balance
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Center Dot
                          Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: _compassExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 400),
                  sizeCurve: Curves.easeOutBack,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBerserkSos(SosState sosState, SosController sosController) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final isActive = sosState.isActive;
        final baseColor = isActive ? AppTheme.danger : const Color(0xFFF93822); // A brutal orange-red
        
        return GestureDetector(
          onLongPress: isActive ? null : () => sosController.start(),
          onTap: isActive ? () => sosController.stop() : null,
          child: Transform.scale(
            scale: isActive ? _pulseAnimation.value : 1.0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: isActive ? _glowAnimation.value : 0.3),
                    blurRadius: isActive ? 40 : 20,
                    spreadRadius: isActive ? 5 : 0,
                    offset: const Offset(0, 8),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    baseColor.withValues(alpha: 0.8),
                    baseColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isActive ? LucideIcons.power : LucideIcons.alertTriangle, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    isActive ? 'ABORT BROADCAST' : 'INITIATE SOS OVERRIDE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppTheme.danger.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.radioTower, color: AppTheme.danger, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DISTRESS SIGNAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.danger, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('Nearby node requesting assistance', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: AppTheme.textMuted, size: 16),
        ],
      ),
    );
  }
}
