class VuMeterState {
  final double leftLevel; // 0.0 (-20dB) to 1.0 (+3dB)
  final double rightLevel; // 0.0 (-20dB) to 1.0 (+3dB)
  final bool isFastBallistics; // false = standard VU (300ms integration), true = peak (50ms)
  final bool peakLeft; // true if leftLevel > 0.88 (+1.5dB)
  final bool peakRight; // true if rightLevel > 0.88 (+1.5dB)

  const VuMeterState({
    this.leftLevel = 0.0,
    this.rightLevel = 0.0,
    this.isFastBallistics = false,
    this.peakLeft = false,
    this.peakRight = false,
  });

  VuMeterState copyWith({
    double? leftLevel,
    double? rightLevel,
    bool? isFastBallistics,
    bool? peakLeft,
    bool? peakRight,
  }) {
    return VuMeterState(
      leftLevel: leftLevel ?? this.leftLevel,
      rightLevel: rightLevel ?? this.rightLevel,
      isFastBallistics: isFastBallistics ?? this.isFastBallistics,
      peakLeft: peakLeft ?? this.peakLeft,
      peakRight: peakRight ?? this.peakRight,
    );
  }
}
