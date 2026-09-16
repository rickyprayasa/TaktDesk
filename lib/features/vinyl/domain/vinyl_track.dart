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

  static final List<VinylTrack> drawer1Presets = presets.sublist(0, 6);
  static final List<VinylTrack> drawer2Presets = presets.sublist(6, 12);

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
      name: 'Kyoto Bamboo Stream',
      subtitle: 'Water & Moss Stone',
      description:
          'Gentle trickling stream, soft hollow bamboo resonance, and moss stone ripples.',
      labelColorHex: '#4A6B53',
      assetPath: 'assets/audio/vinyl_kyoto_bamboo.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 4,
      catalogId: 'TK-05',
      name: 'Campfire Embers',
      subtitle: 'Pine Wood & Hearth',
      description:
          'Low hearth glow and gentle pine embers crackle without loud pops.',
      labelColorHex: '#E05A2B',
      assetPath: 'assets/audio/vinyl_campfire.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 5,
      catalogId: 'TK-06',
      name: 'Nordic Pine Whispers',
      subtitle: 'High Altitude Breeze',
      description:
          'Ultra-soft mountain pine breeze filtered through high-altitude timber.',
      labelColorHex: '#3B7A57',
      assetPath: 'assets/audio/vinyl_nordic_pines.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 6,
      catalogId: 'TK-07',
      name: 'Alpine Mountain Brook',
      subtitle: 'Crystalline Mountain Stream',
      description:
          'Constant crystalline mountain stream providing soothing natural acoustic masking.',
      labelColorHex: '#4A90E2',
      assetPath: 'assets/audio/vinyl_alpine_brook.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 7,
      catalogId: 'TK-08',
      name: 'Warm Tape & Felt Piano',
      subtitle: 'Analog Saturation & Chords',
      description:
          'Analog tape saturation with a slow, muted felt piano chord progression.',
      labelColorHex: '#D97736',
      assetPath: 'assets/audio/vinyl_warm_tape.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 8,
      catalogId: 'TK-09',
      name: 'Pacific Ocean Waves',
      subtitle: 'Tidal Surf & Foam',
      description:
          'Gentle ocean waves washing ashore, rhythmic tidal flow for serene study focus.',
      labelColorHex: '#2E5B88',
      assetPath: 'assets/audio/vinyl_ocean_waves.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 9,
      catalogId: 'TK-10',
      name: 'Misty Morning Meadow',
      subtitle: 'Morning Air & Dew',
      description:
          'Distant morning atmospheric calm with subtle dew drop air blanket.',
      labelColorHex: '#7E9F8E',
      assetPath: 'assets/audio/vinyl_morning_meadow.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 10,
      catalogId: 'TK-11',
      name: 'Pure Focus White Noise',
      subtitle: 'Linear Flat Spectrum',
      description:
          'Flat, calibrated linear noise blanket for deep reading and code concentration.',
      labelColorHex: '#707070',
      assetPath: 'assets/audio/vinyl_pure_white_noise.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 11,
      catalogId: 'TK-12',
      name: 'Timber Acoustic Chamber',
      subtitle: 'Dry Wood Resonance',
      description:
          'Natural dry wood studio chamber resonance with minimal harmonic reflection.',
      labelColorHex: '#8C6747',
      assetPath: 'assets/audio/vinyl_timber_chamber.wav',
      isPremium: true,
    ),
  ];
}
