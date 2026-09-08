import 'package:flutter/material.dart';
import 'takt_colors.dart';

class TaktTypography {
  const TaktTypography._();

  static const TextStyle controlLabel = TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: FontWeight.w600,
    fontSize: 12.0,
    letterSpacing: 1.2,
    color: TaktColors.warmBone,
  );

  static const TextStyle receiptHeader = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontSize: 13.0,
    letterSpacing: 1.5,
    color: TaktColors.thermalCarbon,
  );

  static const TextStyle receiptBody = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w400,
    fontSize: 12.0,
    color: TaktColors.thermalCarbon,
    height: 1.4,
  );

  static const TextStyle timerCounter = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    fontSize: 24.0,
    letterSpacing: 2.0,
    color: TaktColors.warmBone,
  );
}
