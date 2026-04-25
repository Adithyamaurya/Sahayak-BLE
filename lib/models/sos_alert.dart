class SosAlert {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String status; // active / resolved

  const SosAlert({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.status,
  });
}

