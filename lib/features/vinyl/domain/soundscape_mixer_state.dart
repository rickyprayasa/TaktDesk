class SoundscapeMixerState {
  final double primaryVolume;
  final double crackleVolume;
  final double binauralVolume;
  final bool isPrimaryMuted;
  final bool isCrackleMuted;
  final bool isBinauralMuted;

  const SoundscapeMixerState({
    this.primaryVolume = 0.80,
    this.crackleVolume = 0.35,
    this.binauralVolume = 0.25,
    this.isPrimaryMuted = false,
    this.isCrackleMuted = false,
    this.isBinauralMuted = false,
  });

  double get effectivePrimary => isPrimaryMuted ? 0.0 : primaryVolume;
  double get effectiveCrackle => isCrackleMuted ? 0.0 : crackleVolume;
  double get effectiveBinaural => isBinauralMuted ? 0.0 : binauralVolume;

  SoundscapeMixerState copyWith({
    double? primaryVolume,
    double? crackleVolume,
    double? binauralVolume,
    bool? isPrimaryMuted,
    bool? isCrackleMuted,
    bool? isBinauralMuted,
  }) {
    return SoundscapeMixerState(
      primaryVolume: primaryVolume ?? this.primaryVolume,
      crackleVolume: crackleVolume ?? this.crackleVolume,
      binauralVolume: binauralVolume ?? this.binauralVolume,
      isPrimaryMuted: isPrimaryMuted ?? this.isPrimaryMuted,
      isCrackleMuted: isCrackleMuted ?? this.isCrackleMuted,
      isBinauralMuted: isBinauralMuted ?? this.isBinauralMuted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundscapeMixerState &&
          runtimeType == other.runtimeType &&
          primaryVolume == other.primaryVolume &&
          crackleVolume == other.crackleVolume &&
          binauralVolume == other.binauralVolume &&
          isPrimaryMuted == other.isPrimaryMuted &&
          isCrackleMuted == other.isCrackleMuted &&
          isBinauralMuted == other.isBinauralMuted;

  @override
  int get hashCode =>
      primaryVolume.hashCode ^
      crackleVolume.hashCode ^
      binauralVolume.hashCode ^
      isPrimaryMuted.hashCode ^
      isCrackleMuted.hashCode ^
      isBinauralMuted.hashCode;
}
