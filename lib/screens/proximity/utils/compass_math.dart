import 'dart:math';

double normalizeDegrees(double degrees) {
  final normalized = degrees % 360;
  return normalized < 0 ? normalized + 360 : normalized;
}

double shortestAngleDeltaDegrees(double from, double to) {
  final raw = normalizeDegrees(to) - normalizeDegrees(from);
  if (raw > 180) {
    return raw - 360;
  }
  if (raw < -180) {
    return raw + 360;
  }
  return raw;
}

double interpolateAnglesDegrees({
  required double from,
  required double to,
  required double factor,
}) {
  final clampedFactor = factor.clamp(0.0, 1.0);
  final delta = shortestAngleDeltaDegrees(from, to);
  return normalizeDegrees(from + delta * clampedFactor);
}

double calculateBearingDegrees({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) {
  final phi1 = startLat * pi / 180;
  final phi2 = endLat * pi / 180;
  final deltaLambda = (endLng - startLng) * pi / 180;

  final y = sin(deltaLambda) * cos(phi2);
  final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);

  final theta = atan2(y, x) * 180 / pi;
  return normalizeDegrees(theta);
}
