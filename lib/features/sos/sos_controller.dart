import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahayak/services/firestore_service.dart';
import 'package:sahayak/services/location_service.dart';

final sosControllerProvider = StateNotifierProvider<SosController, SosState>((ref) {
  return SosController(
    db: FirestoreService(),
    location: LocationService(),
  );
});

class SosState {
  final bool isActive;
  final bool isStarting;
  final String? sosId;
  final String? error;

  const SosState({
    required this.isActive,
    required this.isStarting,
    required this.sosId,
    required this.error,
  });

  factory SosState.idle() => const SosState(isActive: false, isStarting: false, sosId: null, error: null);

  SosState copyWith({
    bool? isActive,
    bool? isStarting,
    String? sosId,
    String? error,
  }) {
    return SosState(
      isActive: isActive ?? this.isActive,
      isStarting: isStarting ?? this.isStarting,
      sosId: sosId ?? this.sosId,
      error: error,
    );
  }
}

class SosController extends StateNotifier<SosState> {
  SosController({
    required FirestoreService db,
    required LocationService location,
  })  : _db = db,
        _location = location,
        super(SosState.idle());

  final FirestoreService _db;
  final LocationService _location;
  StreamSubscription<Position>? _sub;

  Future<void> start() async {
    if (state.isActive || state.isStarting) return;
    state = state.copyWith(isStarting: true, error: null);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Not authenticated');

      final pos = await _location.currentHighAccuracy();
      final doc = await _db.createSos(userId: user.uid, lat: pos.latitude, lng: pos.longitude);

      _sub?.cancel();
      _sub = _location
          .positionStream(distanceFilterMeters: 5)
          .listen((p) => _db.updateSosLocation(sosId: doc.id, lat: p.latitude, lng: p.longitude));

      state = state.copyWith(isStarting: false, isActive: true, sosId: doc.id, error: null);
    } catch (e) {
      state = state.copyWith(isStarting: false, isActive: false, sosId: null, error: e.toString());
    }
  }

  Future<void> stop() async {
    final id = state.sosId;
    if (id == null) {
      state = SosState.idle();
      return;
    }

    try {
      await _sub?.cancel();
      _sub = null;
      await _db.resolveSos(sosId: id);
    } finally {
      state = SosState.idle();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

