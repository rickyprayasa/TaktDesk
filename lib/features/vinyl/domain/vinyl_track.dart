import 'package:flutter/material.dart';

class VinylTrack {
  final int index;
  final String name;
  final String labelColorHex;

  const VinylTrack({
    required this.index,
    required this.name,
    required this.labelColorHex,
  });

  Color get labelColor {
    final hex = labelColorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  static const List<VinylTrack> presets = [
    VinylTrack(index: 0, name: 'Lo-fi Rain', labelColorHex: '#C85A32'),
    VinylTrack(index: 1, name: 'Deep Brown Noise', labelColorHex: '#4D5D4B'),
    VinylTrack(index: 2, name: 'Library Atmosphere', labelColorHex: '#D99B59'),
    VinylTrack(index: 3, name: 'Cafe Echo', labelColorHex: '#2E3238'),
  ];
}
