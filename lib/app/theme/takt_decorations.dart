import 'package:flutter/material.dart';
import 'takt_colors.dart';

class TaktDecorations {
  const TaktDecorations._();

  static final BoxDecoration instrumentChassis = BoxDecoration(
    color: TaktColors.basaltSlate,
    borderRadius: BorderRadius.circular(12.0),
    border: Border.all(color: TaktColors.slateBorder, width: 1.5),
    boxShadow: const [
      BoxShadow(
        color: Color(0x80000000),
        offset: Offset(0, 8),
        blurRadius: 16.0,
      ),
    ],
  );

  static final BoxDecoration paperReceipt = BoxDecoration(
    color: TaktColors.warmBone,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      topRight: Radius.circular(4.0),
    ),
    border: Border.all(color: TaktColors.paperBorder, width: 1.0),
    boxShadow: const [
      BoxShadow(
        color: TaktColors.paperShadow,
        offset: Offset(0, 6),
        blurRadius: 10.0,
      ),
    ],
  );
}
