import 'package:flutter/material.dart';

class VinylTrack {
  final int index;
  final String catalogId;
  final String name;
  final String subtitle;
  final String description;
  final String labelColorHex;
  final String assetPath;
  final bool isPremium;

  const VinylTrack({
    required this.index,
    required this.catalogId,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.labelColorHex,
    required this.assetPath,
    this.isPremium = false,
  });

  Color get labelColor {
    final hex = labelColorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  static const List<VinylTrack> presets = [
    VinylTrack(
      index: 0,
      catalogId: 'TK-01',
      name: 'Lo-fi Rain',
      subtitle: 'Electric Piano & Rain',
      description:
          'Warm electric piano chord progression with gentle rain shower and vinyl dust crackle.',
      labelColorHex: '#C85A32',
      assetPath: 'assets/audio/vinyl_lofi_rain.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 1,
      catalogId: 'TK-02',
      name: 'Deep Brown Noise',
      subtitle: '1/f² Sleep & Focus',
      description:
          'Low-frequency brown noise blanket blocking external room distractions.',
      labelColorHex: '#4D5D4B',
      assetPath: 'assets/audio/vinyl_brown_noise.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 2,
      catalogId: 'TK-03',
      name: 'Library Atmosphere',
      subtitle: 'Room Tone & Solitude',
      description:
          'Reverberant wooden hall tone with gentle page turns and quiet solace.',
      labelColorHex: '#D99B59',
      assetPath: 'assets/audio/vinyl_library.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 3,
      catalogId: 'TK-04',
      name: 'Cafe Echo',
      subtitle: 'Porcelain & Murmur',
      description:
          'Distant coffeehouse clinks and cozy muffled murmur of morning routines.',
      labelColorHex: '#2E3238',
      assetPath: 'assets/audio/vinyl_cafe.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 4,
      catalogId: 'TK-05',
      name: 'Campfire Embers',
      subtitle: 'Pine Wood & Spark',
      description:
          'Warm pine log crackle and embers popping under a calm starlit night sky.',
      labelColorHex: '#E05A2B',
      assetPath: 'assets/audio/vinyl_campfire.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 5,
      catalogId: 'TK-06',
      name: 'Forest Canopy',
      subtitle: 'Mountain Pines & Wind',
      description:
          'Binaural pine breeze with rustling dry leaves and distant timber resonance.',
      labelColorHex: '#3B7A57',
      assetPath: 'assets/audio/vinyl_forest.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 6,
      catalogId: 'TK-07',
      name: 'Cosmic Drift',
      subtitle: 'Analog Synth Drone',
      description:
          'Deep meditative modular synth harmonics and warm low-frequency planetary hum.',
      labelColorHex: '#3A86FF',
      assetPath: 'assets/audio/vinyl_cosmic.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 7,
      catalogId: 'TK-08',
      name: 'Midnight Train',
      subtitle: 'Rhythmic Steel Rail',
      description:
          'Steady rhythmic steel-wheel rail cadence and distant nocturne locomotive rumble.',
      labelColorHex: '#6C757D',
      assetPath: 'assets/audio/vinyl_train.wav',
      isPremium: true,
    ),
  ];
}
