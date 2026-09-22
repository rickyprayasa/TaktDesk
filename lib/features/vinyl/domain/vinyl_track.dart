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

  static final List<VinylTrack> drawer1Presets = presets.sublist(0, 10);
  static final List<VinylTrack> drawer2Presets = presets.sublist(10, 20);

  static const List<VinylTrack> presets = [
    // -------------------------------------------------------------------------
    // DRAWER 01: NATURE & ACOUSTIC SOUNDSCAPES (10 TRACKS: TK-01 .. TK-10)
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
    VinylTrack(
      index: 6,
      catalogId: 'TK-07',
      name: 'Alpine Mountain Brook',
      subtitle: 'Crystalline Snowmelt',
      description:
          'Pure mountain snowmelt brook trickling over smooth crystalline pebbles.',
      labelColorHex: '#3A7D8C',
      assetPath: 'assets/audio/vinyl_alpine_brook.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 7,
      catalogId: 'TK-08',
      name: 'Pacific Ocean Waves',
      subtitle: 'Coastal Tide & Foam',
      description:
          'Rhythmic coastal tide surges and gentle foaming whitewash receding over pebbles.',
      labelColorHex: '#2B5B84',
      assetPath: 'assets/audio/vinyl_ocean_waves.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 8,
      catalogId: 'TK-09',
      name: 'Misty Morning Meadow',
      subtitle: 'Dawn Breeze & Birdsong',
      description:
          'Early dawn forest canopy with soft morning breeze and quiet distant songbirds.',
      labelColorHex: '#52796F',
      assetPath: 'assets/audio/vinyl_morning_meadow.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 9,
      catalogId: 'TK-10',
      name: 'Timber Chamber Hall',
      subtitle: 'Acoustic Wood Ambience',
      description:
          'Warm acoustic wooden chamber resonance with subtle tactile hall presence.',
      labelColorHex: '#7F5539',
      assetPath: 'assets/audio/vinyl_timber_chamber.wav',
      isPremium: true,
    ),

    // -------------------------------------------------------------------------
    // DRAWER 02: PURE INSTRUMENTAL FOCUS MUSIC (10 TRACKS: TK-11 .. TK-20)
    // -------------------------------------------------------------------------
    VinylTrack(
      index: 10,
      catalogId: 'TK-11',
      name: 'Warm Tape & Felt Piano',
      subtitle: 'Analog Tape Saturation',
      description:
          'Authentic acoustic felt piano recorded through warm reel-to-reel analog tape saturation.',
      labelColorHex: '#D97736',
      assetPath: 'assets/audio/vinyl_warm_tape.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 11,
      catalogId: 'TK-12',
      name: 'Monastic Cello Solo',
      subtitle: 'J.S. Bach · Suite in G Major',
      description:
          'Rich acoustic cello prelude recorded in resonant hall solitude by master cellist John Michel.',
      labelColorHex: '#8B5E3C',
      assetPath: 'assets/audio/vinyl_rhodes_velvet.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 12,
      catalogId: 'TK-13',
      name: 'Tape Acoustic Guitar',
      subtitle: 'Tárrega · Recuerdos de la Alhambra',
      description:
          'Intimate nylon classical guitar arpeggios with natural wooden body warmth and delicate tape flutter.',
      labelColorHex: '#A86D3B',
      assetPath: 'assets/audio/vinyl_acoustic_guitar.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 13,
      catalogId: 'TK-14',
      name: 'Debussy Clair de Lune',
      subtitle: 'Impressionist Concert Grand',
      description:
          'Lyrical, spacious French impressionist acoustic grand piano performance for deep contemplative focus.',
      labelColorHex: '#4A6984',
      assetPath: 'assets/audio/vinyl_ambient_drift.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 14,
      catalogId: 'TK-15',
      name: 'Midnight Solitude Piano',
      subtitle: 'Erik Satie · Gnossienne No. 1',
      description:
          'Hypnotic acoustic upright piano hammers striking muted strings with slow, introspective minimalist cadences.',
      labelColorHex: '#5C5E62',
      assetPath: 'assets/audio/vinyl_felt_piano_solo.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 15,
      catalogId: 'TK-16',
      name: 'Zen Bronze Singing Bowl',
      subtitle: 'Tibetan Bowls & Bell Harmonics',
      description:
          'Resonant authentic Tibetan singing bowl vibrations and pure acoustic bronze temple bell harmonics.',
      labelColorHex: '#D4883A',
      assetPath: 'assets/audio/vinyl_modular_clockwork.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 16,
      catalogId: 'TK-17',
      name: 'Goldberg Variations Aria',
      subtitle: 'J.S. Bach · Bösendorfer',
      description:
          'Contemplative Goldberg Variations Aria performed on a Bösendorfer Imperial concert grand by Kimiko Ishizaka.',
      labelColorHex: '#9C6644',
      assetPath: 'assets/audio/vinyl_goldberg_aria.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 17,
      catalogId: 'TK-18',
      name: 'Chopin Nocturne Op. 9',
      subtitle: 'Frédéric Chopin · Eb Major',
      description:
          'Poetic, expressive Chopin Nocturne in E-flat major Op. 9 No. 2 performed on Steinway concert grand by Frank Levy.',
      labelColorHex: '#6B705C',
      assetPath: 'assets/audio/vinyl_chopin_nocturne.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 18,
      catalogId: 'TK-19',
      name: 'Spanish Romance Guitar',
      subtitle: 'Classical Nylon Solitude',
      description:
          'Timeless Spanish Romance anonymous classical nylon-string guitar melody with rich cedar body warmth.',
      labelColorHex: '#B07D62',
      assetPath: 'assets/audio/vinyl_spanish_romance.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 19,
      catalogId: 'TK-20',
      name: 'Chamber String Quartet',
      subtitle: 'Adagio String Ensemble',
      description:
          'Solemn acoustic chamber strings with intertwined violins, viola, and cello by the Musopen String Quartet.',
      labelColorHex: '#4A5568',
      assetPath: 'assets/audio/vinyl_chamber_quartet.wav',
      isPremium: true,
    ),
  ];
}
