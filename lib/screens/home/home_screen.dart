import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/services/notification_service.dart';
import 'package:sahayak/theme.dart';
import 'package:sahayak/screens/proximity/direction_pointer_screen.dart';
import 'package:sahayak/screens/sos/sos_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<List<ScanResult>>? _scanSub;
  final Map<String, ScanResult> _devices = {};
  bool _scanning = false;
  int _activeSosCount = 0;
  double? _targetLat;
  double? _targetLng;

  StreamSubscription? _sosSub;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;

  Position? _currentPosition;
  double? _deviceHeading;

  Future<void> _startScan() async {
    if (mounted) setState(() => _scanning = true);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          _devices[r.device.remoteId.str] = r;
        }
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  void _initSensors() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 1),
    ).listen((Position position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() => _deviceHeading = event.heading);
      }
    });
  }

  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    double startLatRad = startLat * pi / 180;
    double startLngRad = startLng * pi / 180;
    double endLatRad = endLat * pi / 180;
    double endLngRad = endLng * pi / 180;

    double dLng = endLngRad - startLngRad;
    double y = sin(dLng) * cos(endLatRad);
    double x = cos(startLatRad) * sin(endLatRad) - sin(startLatRad) * cos(endLatRad) * cos(dLng);

    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  @override
  void initState() {
    super.initState();
    _startScan();
    _listenSos();
    _initSensors();
  }

  void _listenSos() {
    _sosSub = FirebaseFirestore.instance
      .collection('sos')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .listen((snap) {
        if (!mounted) return;
        
        double? bestDist;
        double? tLat;
        double? tLng;

        for (final d in snap.docs) {
          final loc = d.data()['location'] as Map<String, dynamic>?;
          final lat = (loc?['lat'] as num?)?.toDouble();
          final lng = (loc?['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          if (_currentPosition != null) {
            final dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, lat, lng);
            if (bestDist == null || dist < bestDist) {
              bestDist = dist;
              tLat = lat;
              tLng = lng;
            }
          } else {
             // Fallback if no loc yet
             tLat = lat;
             tLng = lng;
          }
        }

        setState(() {
          _activeSosCount = snap.docs.length;
          _targetLat = tLat;
          _targetLng = tLng;
        });
      });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _sosSub?.cancel();
    _positionSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Cyberpunk glowing ambient background (subtle in light mode)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.05),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: isDark ? 0.15 : 0.05),
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 100, spreadRadius: 50)],
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // padding for auto-hide scroll nav
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sahayak',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32),
                        ),
                        Text(
                          'Scanning Nearby',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SosListScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.5 : 1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                          boxShadow: [
                             if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_scanning) 
                               const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                            Icon(LucideIcons.radar, color: _scanning ? AppTheme.primary : AppTheme.textMuted, size: _scanning ? 16 : 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Stunning E-commerce style cards
                Row(
                  children: [
                     Expanded(
                       child: GestureDetector(
                         onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectionPointerScreen()));
                         },
                         child: _buildGlowingCard(
                           context,
                           title: 'Bluetooth',
                           value: '${_devices.length}',
                           subtitle: 'Nearby Users',
                           icon: LucideIcons.bluetooth,
                           gradientColors: const [Color(0xFF00BFAF), Color(0xFF00FFD1)],
                         ),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: GestureDetector(
                         onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectionPointerScreen()));
                         },
                         child: _buildInlineCompassCard(),
                       ),
                     ),
                  ],
                ),
                
                const SizedBox(height: 32),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                const SizedBox(height: 16),
                
                // Big beautiful smooth action button
                GestureDetector(
                  onTap: () => _showSosBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF2A55), Color(0xFFFF5E7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF2A55).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.bellRing, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send Emergency Ping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 4),
                              Text('Alert all nearby users', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: Colors.white),
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

  Widget _buildGlowingCard(BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.8 : 1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
               color: Theme.of(context).colorScheme.onSurface,
               fontSize: 36,
               fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
               color: Theme.of(context).colorScheme.onSurface,
               fontSize: 14,
               fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
               color: AppTheme.textMuted,
               fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineCompassCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = _activeSosCount > 0 
        ? const [Color(0xFFFF2A55), Color(0xFFFF5E7E)]
        : const [Color(0xFF8A8A9E), Color(0xFFB0B0C0)];

    double? pointerAngle;
    if (_currentPosition != null && _targetLat != null && _targetLng != null && _activeSosCount > 0) {
      double heading = _deviceHeading ?? 0.0; // Fallback to 0 if no compass sensor on device
      double targetBearing = _calculateBearing(_currentPosition!.latitude, _currentPosition!.longitude, _targetLat!, _targetLng!);
      double finalAngle = targetBearing - heading;
      pointerAngle = (finalAngle + 360) % 360;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.8 : 1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: pointerAngle == null 
               ? const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 20)
               : AnimatedRotation(
                   turns: pointerAngle / 360,
                   duration: const Duration(milliseconds: 300),
                   curve: Curves.easeOutCubic,
                   child: const Icon(LucideIcons.navigation, color: Colors.white, size: 20),
                 ),
          ),
          const SizedBox(height: 20),
          Text(
            '$_activeSosCount',
            style: TextStyle(
               color: Theme.of(context).colorScheme.onSurface,
               fontSize: 36,
               fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Emergencies',
            style: TextStyle(
               color: Theme.of(context).colorScheme.onSurface,
               fontSize: 14,
               fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _activeSosCount > 0 ? 'Active Nearby' : 'All Clear',
            style: const TextStyle(
               color: AppTheme.textMuted,
               fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showSosBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 24),
                const Text('Select Emergency Type', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 8),
                const Text('This will instantly alert users in your proximity.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSosTypeBtn(ctx, 'Emergency', LucideIcons.alertTriangle, AppTheme.danger),
                    _buildSosTypeBtn(ctx, 'Medical', LucideIcons.cross, Colors.blueAccent),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSosTypeBtn(ctx, 'Help', LucideIcons.lifeBuoy, Colors.orangeAccent),
                    _buildSosTypeBtn(ctx, 'Police', LucideIcons.shieldAlert, Colors.indigoAccent),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSosTypeBtn(BuildContext ctx, String type, IconData icon, Color color) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx); // Close sheet
        
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in!')));
           return;
        }

        Position? loc = _currentPosition;
        if (loc == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acquiring GPS lock...')));
          try {
             loc = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 5));
          } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Could not get GPS location.')));
             return;
          }
        }
        
        try {
          await FirebaseFirestore.instance.collection('sos').add({
             'userId': user.uid,
             'userName': user.displayName ?? 'Unknown',
             'type': type,
             'location': {
                'lat': loc.latitude,
                'lng': loc.longitude,
             },
             'timestamp': FieldValue.serverTimestamp(),
             'status': 'active',
          });
          NotificationService.showHighPriority(title: '$type Broadcasted', body: 'Local mesh initialized.');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type distress signal broadcasted!'), backgroundColor: AppTheme.danger));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reach server: $e')));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 12),
          Text(type, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
