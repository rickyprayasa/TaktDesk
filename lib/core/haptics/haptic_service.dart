import 'package:flutter/services.dart';

class HapticService {
  const HapticService._();

  static bool enabled = true;

  static Future<void> dialTick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> mechanicalPress() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> paperTorn() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> stampDone() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  // Generic haptic aliases matching interface specification
  static Future<void> tick() async => dialTick();
  static Future<void> selectionClick() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> impactLight() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> impactHeavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> heavyClick() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> lightClick() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }
}
