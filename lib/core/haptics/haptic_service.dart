import 'package:flutter/services.dart';
import '../app_visibility.dart';

class HapticService {
  const HapticService._();

  static bool enabled = true;

  static Future<void> dialTick() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> mechanicalPress() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> paperTorn() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> stampDone() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.mediumImpact();
  }

  // Generic haptic aliases matching interface specification
  static Future<void> tick() async => dialTick();
  static Future<void> selectionClick() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> impactLight() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> impactHeavy() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> heavyClick() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> lightClick() async {
    if (!enabled || !appIsVisible) return;
    await HapticFeedback.lightImpact();
  }
}
