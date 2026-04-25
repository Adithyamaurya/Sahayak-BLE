import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> areMandatoryGranted() async {
    final location = await Permission.locationWhenInUse.status;
    final notifications = await Permission.notification.status;
    return location.isGranted && notifications.isGranted;
  }

  static Future<PermissionResult> requestAll() async {
    final location = await Permission.locationWhenInUse.request();
    final notifications = await Permission.notification.request();

    // Optional BLE permissions (Android 12+). iOS will ignore unsupported ones.
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();

    return PermissionResult(
      location: location,
      notifications: notifications,
      bluetoothScan: bluetoothScan,
      bluetoothConnect: bluetoothConnect,
    );
  }
}

class PermissionResult {
  final PermissionStatus location;
  final PermissionStatus notifications;
  final PermissionStatus bluetoothScan;
  final PermissionStatus bluetoothConnect;

  const PermissionResult({
    required this.location,
    required this.notifications,
    required this.bluetoothScan,
    required this.bluetoothConnect,
  });
}

