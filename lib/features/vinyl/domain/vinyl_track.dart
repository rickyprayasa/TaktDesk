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

  static final List<VinylTrack> drawer1Presets = presets.sublist(0, 12);
  static final List<VinylTrack> drawer2Presets = presets.sublist(12, 24);

  static const List<VinylTrack> presets = [
    // -------------------------------------------------------------------------
    // DRAWER 01: NATURE & ACOUSTIC SOUNDSCAPES (12 TRACKS: TK-01 .. TK-12)
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
      subtitle: 'Crystalline Mountain Stream',
      description:
          'Constant crystalline mountain stream providing soothing natural acoustic masking.',
      labelColorHex: '#4A90E2',
      assetPath: 'assets/audio/vinyl_alpine_brook.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 7,
      catalogId: 'TK-08',
      name: 'Pacific Ocean Waves',
      subtitle: 'Tidal Surf & Foam',
      description:
          'Gentle ocean waves washing ashore, rhythmic tidal flow for serene study focus.',
      labelColorHex: '#2E5B88',
      assetPath: 'assets/audio/vinyl_ocean_waves.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 8,
      catalogId: 'TK-09',
      name: 'Misty Morning Meadow',
      subtitle: 'Morning Air & Dew',
      description:
          'Distant morning atmospheric calm with subtle dew drop air blanket.',
      labelColorHex: '#7E9F8E',
      assetPath: 'assets/audio/vinyl_morning_meadow.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 9,
      catalogId: 'TK-10',
      name: 'Pure Focus Velvet Noise',
      subtitle: 'Linear Flat Spectrum',
      description:
          'Flat, calibrated linear noise blanket for deep reading and code concentration.',
      labelColorHex: '#707070',
      assetPath: 'assets/audio/vinyl_pure_white_noise.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 10,
      catalogId: 'TK-11',
      name: 'Timber Acoustic Chamber',
      subtitle: 'Dry Wood Resonance',
      description:
          'Natural dry wood studio chamber resonance with minimal harmonic reflection.',
      labelColorHex: '#8C6747',
      assetPath: 'assets/audio/vinyl_timber_chamber.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 11,
      catalogId: 'TK-12',
      name: 'Zen Temple Singing Bowl',
      subtitle: '108 Hz Meditative Resonance',
      description:
          'Warm 108 Hz singing bowl fundamental tone with meditative breath cycle.',
      labelColorHex: '#C89B3C',
      assetPath: 'assets/audio/vinyl_zen_bowl.wav',
      isPremium: true,
    ),

    // -------------------------------------------------------------------------
    // DRAWER 02: PURE INSTRUMENTAL FOCUS MUSIC (12 TRACKS: TK-13 .. TK-24)
    // -------------------------------------------------------------------------
    VinylTrack(
      index: 12,
      catalogId: 'TK-13',
      name: 'Warm Tape & Felt Piano',
      subtitle: 'Analog Saturation & Chords',
      description:
          'Analog tape saturation with a slow, muted felt piano chord progression.',
      labelColorHex: '#D97736',
      assetPath: 'assets/audio/vinyl_warm_tape.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 13,
      catalogId: 'TK-14',
      name: 'Monastic Rhodes & Velvet',
      subtitle: 'Vintage Electric Piano E-Chords',
      description:
          'Warm Fender Rhodes 9th chords with gentle tremolo and tape saturation for deep focus.',
      labelColorHex: '#8B5E3C',
      assetPath: 'assets/audio/vinyl_rhodes_velvet.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 14,
      catalogId: 'TK-15',
      name: 'Tape Acoustic Guitar',
      subtitle: 'Muted Nylon Fingerpicking',
      description:
          'Intimate nylon guitar arpeggios with gentle tape flutter and resonant wooden body warmth.',
      labelColorHex: '#A86D3B',
      assetPath: 'assets/audio/vinyl_acoustic_guitar.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 15,
      catalogId: 'TK-16',
      name: 'Cosmic Ambient Drift',
      subtitle: 'Analog Synthesizer & Silk Pad',
      description:
          'Eno-inspired warm polyphonic analog synthesizer pads drifting across slow meditative cadences.',
      labelColorHex: '#4A6984',
      assetPath: 'assets/audio/vinyl_ambient_drift.wav',
      isPremium: false,
    ),
    VinylTrack(
      index: 16,
      catalogId: 'TK-17',
      name: 'Midnight Solitude Piano',
      subtitle: 'Muted Upright in D Minor',
      description:
          'Delicate felt upright piano hammers striking muted strings with soft sustain pedal resonance.',
      labelColorHex: '#5C5E62',
      assetPath: 'assets/audio/vinyl_felt_piano_solo.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 17,
      catalogId: 'TK-18',
      name: 'Modular Clockwork Arp',
      subtitle: 'Pentatonic Analog Pulse',
      description:
          'Hypnotic analog modular arpeggio gently ticking in 5-note pentatonic focus harmony.',
      labelColorHex: '#D4883A',
      assetPath: 'assets/audio/vinyl_modular_clockwork.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 18,
      catalogId: 'TK-19',
      name: 'Lo-fi Tape Jazz Guitar',
      subtitle: 'Warm Hollowbody Chords',
      description:
          'Warm hollowbody electric guitar playing nostalgic slow lo-fi progression with subtle tube drive.',
      labelColorHex: '#C27D38',
      assetPath: 'assets/audio/vinyl_tape_guitar.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 19,
      catalogId: 'TK-20',
      name: 'Aether Chamber Strings',
      subtitle: 'Muted Quartet Harmonics',
      description:
          'Gentle bowed cello and viola sustained harmonic chords blending into a serene focus bed.',
      labelColorHex: '#6C5B7B',
      assetPath: 'assets/audio/vinyl_chamber_strings.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 20,
      catalogId: 'TK-21',
      name: 'Vintage Wurlitzer 200A',
      subtitle: 'Warm Reed Vibrato & Chords',
      description:
          'Electro-mechanical reed piano with iconic vibrato, warm saturation, and gentle focus voicing.',
      labelColorHex: '#B86B35',
      assetPath: 'assets/audio/vinyl_wurlitzer_reeds.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 21,
      catalogId: 'TK-22',
      name: 'Moog Deep Focus Bass',
      subtitle: 'Monophonic Analog Sub Drone',
      description:
          'Soft, deep 32-foot analog synth harmonic drone with warm low-pass sweep for flow state.',
      labelColorHex: '#3D5A5B',
      assetPath: 'assets/audio/vinyl_moog_harmony.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 22,
      catalogId: 'TK-23',
      name: 'Kalimba & Crystal Chords',
      subtitle: 'Tuned Steel Tines in Eb',
      description:
          'Gentle thumb piano ringing in serene pentatonic intervals with warm wooden resonance decay.',
      labelColorHex: '#5E8271',
      assetPath: 'assets/audio/vinyl_kalimba_crystal.wav',
      isPremium: true,
    ),
    VinylTrack(
      index: 23,
      catalogId: 'TK-24',
      name: 'Nocturne in F Minor',
      subtitle: 'Calm Romantic Harmonics',
      description:
          'Slow, contemplative classical piano harmonics for late-night programming and deep concentration.',
      labelColorHex: '#7D6652',
      assetPath: 'assets/audio/vinyl_nocturne_harmonics.wav',
      isPremium: true,
    ),
  ];
}
