import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nearbyServiceProvider = Provider((ref) => NearbyService());

class NearbyService {
  final List<ScanResult> _nearbyDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSub;

  Stream<int> streamNearbyDeviceCount() {
    // Start scanning for Sahayak devices (simulated filter here)
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4), androidUsesFineLocation: true);
    
    return FlutterBluePlus.scanResults.map((results) {
      // Filter for devices running Sahayak (e.g. by Name or UUID)
      // In a real scenario, we'd check ManufacturerData or specific UUIDs.
      return results.length;
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
  }
}
