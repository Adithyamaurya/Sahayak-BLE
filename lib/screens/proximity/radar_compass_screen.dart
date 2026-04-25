import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sahayak/theme.dart';

class RadarCompassScreen extends StatefulWidget {
  const RadarCompassScreen({super.key});

  @override
  State<RadarCompassScreen> createState() => _RadarCompassScreenState();
}

class _RadarCompassScreenState extends State<RadarCompassScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  
  Position? _currentPos;
  double _heading = 0; // Device's magnetic heading
  
  // Mock target (In real app, this would be an active SOS from Firestore)
  final double _targetLat = 28.6139; 
  final double _targetLng = 77.2090;
  bool _isTracking = false;

  final List<Map<String, dynamic>> _mockDevices = [
    {'name': 'Dr. Smith (Responder)', 'distance': 15, 'angle': 45.0, 'type': 'Medical'},
    {'name': 'Alex (Volunteer)', 'distance': 42, 'angle': 120.0, 'type': 'Help'},
    {'name': 'Sarah (Nearby)', 'distance': 80, 'angle': 210.0, 'type': 'User'},
  ];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Magnetometer for heading
    magnetometerEventStream().listen((event) {
      double heading = atan2(event.y, event.x) * (180 / pi) + 90;
      if (heading < 0) heading += 360;
      if (mounted) setState(() => _heading = heading);
    });

    // Location for distance/bearing
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((pos) {
      if (mounted) setState(() => _currentPos = pos);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
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
    
    // Calculate direction to victim if tracking
    double victimBearing = 0;
    double victimDistance = 0;
    if (_currentPos != null) {
      victimBearing = _calculateBearing(_currentPos!.latitude, _currentPos!.longitude, _targetLat, _targetLng);
      victimDistance = Geolocator.distanceBetween(_currentPos!.latitude, _currentPos!.longitude, _targetLat, _targetLng);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isTracking ? 'Rescue Pointer' : 'Nearby Radar'),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? LucideIcons.radar : LucideIcons.locate, size: 20),
            onPressed: () => setState(() => _isTracking = !_isTracking),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 32),
              Text(
                _isTracking ? 'Pointing toward SOS victim' : 'Scanning for nearby helpers...',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              if (_isTracking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${(victimDistance / 1000).toStringAsFixed(1)} KM AWAY',
                    style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 48),

              // UI Content
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radar Base Rings
                      ...List.generate(3, (index) {
                        return Container(
                          width: 320 - (index * 100.0),
                          height: 320 - (index * 100.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1), width: 1.5),
                          ),
                        );
                      }),

                      if (!_isTracking) ...[
                         // Scanning Sweep
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _radarController.value * 2 * pi,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: [Colors.transparent, AppTheme.primary.withValues(alpha: 0.0), AppTheme.primary.withValues(alpha: 0.2)],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Device Dots
                        ..._mockDevices.map((device) => _buildDeviceNode(device)),
                      ] else ...[
                        // Rescue Pointer (The "Berserk" Compass)
                        _buildRescuePointer(victimBearing - _heading),
                      ],

                      // Center Node
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle, boxShadow: AppTheme.softShadow),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.primary,
                          child: const Icon(LucideIcons.user, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          
          if (!_isTracking) _buildBottomList(theme),
        ],
      ),
    );
  }

  Widget _buildRescuePointer(double angleDegrees) {
    return Transform.rotate(
      angle: angleDegrees * pi / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.1), width: 2),
            ),
          ),
          // Gradient Needle
          Column(
            children: [
              Container(
                width: 40,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.danger, AppTheme.danger.withValues(alpha: 0.2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.danger.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, -10))
                  ],
                ),
                child: const Icon(LucideIcons.chevronUp, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 40), // Gap for center orb
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomList(ThemeData theme) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Responders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  Text('${_mockDevices.length} Detected', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _mockDevices.length,
                itemBuilder: (context, index) {
                  final device = _mockDevices[index];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: AppTheme.background, child: Icon(LucideIcons.user, size: 16, color: AppTheme.primary)),
                    title: Text(device['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(LucideIcons.arrowUpRight, size: 16, color: AppTheme.textMuted),
                    onTap: () => setState(() => _isTracking = true),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceNode(Map<String, dynamic> device) {
    final distance = device['distance'] as int;
    final angleDegrees = device['angle'] as double;
    final radius = (distance / 100.0) * 160;
    final angleRad = (angleDegrees - 90) * pi / 180;
    final x = radius * cos(angleRad);
    final y = radius * sin(angleRad);

    return Transform.translate(
      offset: Offset(x, y),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 24 * _pulseController.value,
                height: 24 * _pulseController.value,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.2 * (1 - _pulseController.value))),
              ),
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ],
          );
        },
      ),
    );
  }
}
