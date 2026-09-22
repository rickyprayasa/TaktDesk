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
    // -------------------------------------------------------------------------
    // DRAWER 01: NATURE & ACOUSTIC SOUNDSCAPES (6 TRACKS: TK-01 .. TK-06)
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // DRAWER 02: PURE INSTRUMENTAL FOCUS MUSIC (6 TRACKS: TK-07 .. TK-12)
    // -------------------------------------------------------------------------
    VinylTrack(
      index: 6,
      catalogId: 'TK-07',
      name: 'Warm Tape & Felt Piano',
      subtitle: 'Analog Tape Saturation',
      description:
          'Authentic acoustic felt piano recorded through warm reel-to-reel analog tape saturation.',
      labelColorHex: '#D97736',
      assetPath: 'assets/audio/vinyl_warm_tape.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 7,
      catalogId: 'TK-08',
      name: 'Monastic Cello Solo',
      subtitle: 'J.S. Bach · Suite in G Major',
      description:
          'Rich acoustic cello prelude recorded in resonant hall solitude by master cellist John Michel.',
      labelColorHex: '#8B5E3C',
      assetPath: 'assets/audio/vinyl_rhodes_velvet.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 8,
      catalogId: 'TK-09',
      name: 'Tape Acoustic Guitar',
      subtitle: 'Tárrega · Recuerdos de la Alhambra',
      description:
          'Intimate nylon classical guitar arpeggios with natural wooden body warmth and delicate tape flutter.',
      labelColorHex: '#A86D3B',
      assetPath: 'assets/audio/vinyl_acoustic_guitar.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 9,
      catalogId: 'TK-10',
      name: 'Debussy Clair de Lune',
      subtitle: 'Impressionist Concert Grand',
      description:
          'Lyrical, spacious French impressionist acoustic grand piano performance for deep contemplative focus.',
      labelColorHex: '#4A6984',
      assetPath: 'assets/audio/vinyl_ambient_drift.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 10,
      catalogId: 'TK-11',
      name: 'Midnight Solitude Piano',
      subtitle: 'Erik Satie · Gnossienne No. 1',
      description:
          'Hypnotic acoustic upright piano hammers striking muted strings with slow, introspective minimalist cadences.',
      labelColorHex: '#5C5E62',
      assetPath: 'assets/audio/vinyl_felt_piano_solo.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 11,
      catalogId: 'TK-12',
      name: 'Zen Bronze Singing Bowl',
      subtitle: 'Tibetan Bowls & Bell Harmonics',
      description:
          'Resonant authentic Tibetan singing bowl vibrations and pure acoustic bronze temple bell harmonics.',
      labelColorHex: '#D4883A',
      assetPath: 'assets/audio/vinyl_modular_clockwork.wav',
      isPremium: true,
    ),
  ];
}
