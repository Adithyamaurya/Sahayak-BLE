import 'package:sahayak/screens/proximity/utils/compass_math.dart';

class AngleLowPassFilter {
  AngleLowPassFilter({required this.alpha}) : assert(alpha > 0 && alpha <= 1);

  final double alpha;
  double? _value;

  double add(double inputDegrees) {
    final input = normalizeDegrees(inputDegrees);
    final previous = _value;

    if (previous == null) {
      _value = input;
      return input;
    }

    final delta = shortestAngleDeltaDegrees(previous, input);
    _value = normalizeDegrees(previous + delta * alpha);
    return _value!;
  }

  void reset() {
    _value = null;
  }
}
