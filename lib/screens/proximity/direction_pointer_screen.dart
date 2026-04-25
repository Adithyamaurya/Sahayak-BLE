import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sahayak/screens/proximity/utils/compass_math.dart';
import 'package:sahayak/screens/proximity/utils/compass_smoothing.dart';
import 'package:sahayak/theme.dart';

class DirectionPointerScreen extends StatefulWidget {
  final double? initialTargetLat;
  final double? initialTargetLng;

  const DirectionPointerScreen({super.key, this.initialTargetLat, this.initialTargetLng});

  @override
  State<DirectionPointerScreen> createState() => _DirectionPointerScreenState();
}

class _DirectionPointerScreenState extends State<DirectionPointerScreen> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sosSub;
  Timer? _pendingUiTimer;

  Position? _currentPosition;
  double? _smoothedHeading;
  double? _displayPointerAngle;
  double? _targetDistanceMeters;

  double? _targetLat;
  double? _targetLng;

  bool _isCompassAvailable = true;
  String? _statusMessage;

  final AngleLowPassFilter _headingFilter = AngleLowPassFilter(alpha: 0.24);
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _uiThrottle = Duration(milliseconds: 130);
  static const double _pointerLerpFactor = 0.15;
  static const int _gpsJumpIgnoreMeters = 120;

  @override
  void initState() {
    super.initState();
    _targetLat = widget.initialTargetLat;
    _targetLng = widget.initialTargetLng;

    unawaited(_initStreams());
  }

  Future<void> _initStreams() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = 'Initializing sensors...';
    });

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Enable location services to start pointer.';
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Location permission is required.';
      });
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen(_onPosition, onError: (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Unable to read location stream.';
      });
    });

    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) {
      _isCompassAvailable = false;
      if (mounted) {
        setState(() {
          _statusMessage = 'Compass sensor not available on this device.';
        });
      }
    } else {
      _compassSub = compassEvents.listen(_onCompass, onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isCompassAvailable = false;
          _statusMessage = 'Compass stream error.';
        });
      });
    }

    if (_targetLat == null || _targetLng == null) {
      _sosSub = FirebaseFirestore.instance
          .collection('sos')
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen(_onSosSnapshot, onError: (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _statusMessage = 'Unable to read SOS target updates.';
        });
      });
    }

    if (mounted) {
      setState(() {
        if (_statusMessage == 'Initializing sensors...') {
          _statusMessage = null;
        }
      });
    }
  }

  void _onPosition(Position position) {
    if (!mounted) {
      return;
    }

    final previous = _currentPosition;
    if (previous != null) {
      final jumpMeters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      if (jumpMeters > _gpsJumpIgnoreMeters) {
        return;
      }
    }

    _currentPosition = position;
    _scheduleUiComputation();

    if (_statusMessage != null && mounted) {
      setState(() {
        _statusMessage = null;
      });
    }
  }

  void _onCompass(CompassEvent event) {
    if (!mounted) {
      return;
    }

    final heading = event.heading;
    if (heading == null) {
      return;
    }

    _smoothedHeading = _headingFilter.add(normalizeDegrees(heading));
    _scheduleUiComputation();
  }

  void _onSosSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted) {
      return;
    }

    if (snapshot.docs.isEmpty) {
      setState(() {
        _targetLat = null;
        _targetLng = null;
        _targetDistanceMeters = null;
        _statusMessage = 'No active SOS target available.';
      });
      return;
    }

    double? bestLat;
    double? bestLng;
    double? bestDistance;

    for (final doc in snapshot.docs) {
      final location = doc.data()['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        continue;
      }

      if (_currentPosition == null) {
        bestLat = lat;
        bestLng = lng;
        break;
      }

      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );

      if (bestDistance == null || d < bestDistance) {
        bestDistance = d;
        bestLat = lat;
        bestLng = lng;
      }
    }

    if (bestLat == null || bestLng == null) {
      return;
    }

    _targetLat = bestLat;
    _targetLng = bestLng;
    _statusMessage = null;
    _scheduleUiComputation();
  }

  void _scheduleUiComputation() {
    final elapsed = DateTime.now().difference(_lastUiUpdate);
    final wait = _uiThrottle - elapsed;

    if (wait <= Duration.zero) {
      _pendingUiTimer?.cancel();
      _pendingUiTimer = null;
      _computeAndApplyUiValues();
      return;
    }

    if (_pendingUiTimer != null) {
      return;
    }

    _pendingUiTimer = Timer(wait, () {
      _pendingUiTimer = null;
      _computeAndApplyUiValues();
    });
  }

  void _computeAndApplyUiValues() {
    if (!mounted) {
      return;
    }

    _lastUiUpdate = DateTime.now();

    final pos = _currentPosition;
    final heading = _smoothedHeading;
    final tLat = _targetLat;
    final tLng = _targetLng;

    if (pos == null || heading == null || tLat == null || tLng == null) {
      setState(() {
        _targetDistanceMeters = null;
      });
      return;
    }

    final bearing = calculateBearingDegrees(
      startLat: pos.latitude,
      startLng: pos.longitude,
      endLat: tLat,
      endLng: tLng,
    );

    final distance = Geolocator.distanceBetween(
      pos.latitude,
      pos.longitude,
      tLat,
      tLng,
    );

    final rawPointerAngle = normalizeDegrees(bearing - heading);
    final nextPointerAngle = interpolateAnglesDegrees(
      from: _displayPointerAngle ?? rawPointerAngle,
      to: rawPointerAngle,
      factor: _pointerLerpFactor,
    );

    setState(() {
      _displayPointerAngle = nextPointerAngle;
      _targetDistanceMeters = distance;
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  Color _accuracyColor(double accuracy) {
    if (accuracy > 20) {
      return AppTheme.danger;
    }
    if (accuracy > 10) {
      return Colors.orange;
    }
    return AppTheme.primary;
  }

  Widget _buildCard(BuildContext context, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: isDark ? 0.72 : 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    _sosSub?.cancel();
    _pendingUiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final position = _currentPosition;
    final hasTarget = _targetLat != null && _targetLng != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Direction Pointer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0D111A), const Color(0xFF111827), const Color(0xFF191D2A)]
                : [const Color(0xFFF6F8FD), const Color(0xFFEAF2FF), const Color(0xFFF9F4F2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              if (_statusMessage != null)
                _buildCard(
                  context,
                  Row(
                    children: [
                      const Icon(LucideIcons.info, size: 18, color: AppTheme.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (position != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildCard(
                    context,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GPS accuracy: ${position.accuracy.toStringAsFixed(1)} m',
                          style: TextStyle(
                            color: _accuracyColor(position.accuracy),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (position.accuracy > 20)
                          const Text(
                            'Low GPS accuracy',
                            style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: _isCompassAvailable
                      ? _CompassDial(pointerAngle: _displayPointerAngle)
                      : _buildCard(
                          context,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.compass, color: AppTheme.danger),
                              const SizedBox(width: 12),
                              Text(
                                'Compass unavailable on this device.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              if (_targetDistanceMeters != null)
                _buildCard(
                  context,
                  Column(
                    children: [
                      const Text(
                        'Distance to SOS user',
                        style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDistance(_targetDistanceMeters!),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                      if (_targetDistanceMeters! < 2)
                        const Text(
                          'You are at the target location.',
                          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                )
              else
                _buildCard(
                  context,
                  Text(
                    hasTarget ? 'Computing distance...' : 'Waiting for active SOS target...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.pointerAngle});

  final double? pointerAngle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surface.withValues(alpha: isDark ? 0.62 : 0.97),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.18), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 24; i++)
            Transform.rotate(
              angle: (i * 15) * pi / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: i % 6 == 0 ? 16 : 8,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: i % 6 == 0 ? AppTheme.textMuted : AppTheme.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 18),
              child: Text(
                'N',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: (pointerAngle ?? 0) * pi / 180,
            child: const SizedBox(
              width: 94,
              height: 150,
              child: CustomPaint(painter: _PointerPainter()),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppTheme.danger, width: 3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final fill = Paint()..style = PaintingStyle.fill;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    final head = Path()
      ..moveTo(centerX, 0)
      ..lineTo(centerX + 24, 86)
      ..lineTo(centerX + 6, 130)
      ..lineTo(centerX - 12, 108)
      ..lineTo(centerX - 20, 88)
      ..close();

    canvas.drawShadow(head, const Color(0xAAE11D48), 10, true);

    fill.color = const Color(0xFFE11D48);
    canvas.drawPath(head, fill);
    canvas.drawPath(head, border);

    final tail = Path()
      ..moveTo(centerX - 8, 130)
      ..lineTo(centerX + 12, 144)
      ..lineTo(centerX - 2, 148)
      ..close();

    fill.color = Colors.white;
    canvas.drawPath(tail, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
