import 'package:flutter/material.dart';

/// Industrial brushed aluminum bracket clamp connecting modular Dieter Rams instruments.
class ModularRackBracket extends StatelessWidget {
  final bool isVertical;

  const ModularRackBracket({super.key, this.isVertical = true});

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      return Container(
        width: 24,
        height: 16,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF424752),
              Color(0xFF282C33),
              Color(0xFF1E2126),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFF4F5561), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(0, 1.5),
              blurRadius: 2.0,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF181A1D),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33FFFFFF),
                  offset: Offset(0, -0.5),
                  blurRadius: 0.5,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 16,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF424752),
              Color(0xFF282C33),
              Color(0xFF1E2126),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: const Color(0xFF4F5561), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              offset: Offset(1.5, 0),
              blurRadius: 2.0,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF181A1D),
            ),
          ),
        ),
      );
    }
  }
}
