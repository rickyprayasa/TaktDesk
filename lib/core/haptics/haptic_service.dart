import 'package:flutter/services.dart';

class HapticService {
  const HapticService._();

  static Future<void> dialTick() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> mechanicalPress() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> paperTorn() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> stampDone() async {
    await HapticFeedback.mediumImpact();
  }

  // Generic haptic aliases matching interface specification
  static Future<void> tick() async => dialTick();
  static Future<void> selectionClick() async => HapticFeedback.selectionClick();
  static Future<void> impactLight() async => HapticFeedback.lightImpact();
  static Future<void> impactHeavy() async => HapticFeedback.heavyImpact();
  static Future<void> heavyClick() async => HapticFeedback.heavyImpact();
  static Future<void> lightClick() async => HapticFeedback.lightImpact();
}
