class FocusLockState {
  final bool isLocked;
  final bool isHolding;
  final double unlockProgress; // 0.0 to 1.0
  final DateTime? sessionStartTime;

  const FocusLockState({
    this.isLocked = false,
    this.isHolding = false,
    this.unlockProgress = 0.0,
    this.sessionStartTime,
  });

  FocusLockState copyWith({
    bool? isLocked,
    bool? isHolding,
    double? unlockProgress,
    DateTime? sessionStartTime,
    bool clearStartTime = false,
  }) {
    return FocusLockState(
      isLocked: isLocked ?? this.isLocked,
      isHolding: isHolding ?? this.isHolding,
      unlockProgress: unlockProgress ?? this.unlockProgress,
      sessionStartTime: clearStartTime ? null : (sessionStartTime ?? this.sessionStartTime),
    );
  }
}
