class AlarmChime {
  final String id;
  final String name;
  final String category;
  final String description;
  final String assetPath;
  final bool isPro;

  const AlarmChime({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.assetPath,
    this.isPro = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmChime && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AlarmChimes {
  static const AlarmChime braunBell = AlarmChime(
    id: 'braunBell',
    name: 'BRAUN DUAL-HAMMER',
    category: 'MECHANICAL',
    description: 'Authentic twin-bell mechanical clockwork chime',
    assetPath: 'assets/audio/alarm_braun_bell.wav',
    isPro: false,
  );

  static const AlarmChime deskBell = AlarmChime(
    id: 'deskBell',
    name: 'BRASS DESK BELL',
    category: 'HOROLOGICAL',
    description: 'Crisp high-frequency brass counter desk chime',
    assetPath: 'assets/audio/alarm_desk_bell.wav',
    isPro: false,
  );

  static const AlarmChime tibetanBowl = AlarmChime(
    id: 'tibetanBowl',
    name: 'TIBETAN SINGING BOWL',
    category: 'MEDITATIVE',
    description: 'Hand-hammered bronze singing bowl with rich overtones',
    assetPath: 'assets/audio/alarm_tibetan_bowl.wav',
    isPro: true,
  );

  static const AlarmChime zenGong = AlarmChime(
    id: 'zenGong',
    name: 'ZEN TEMPLE GONG',
    category: 'ORGANIC',
    description: 'Deep resonant Buddhist temple bell gong',
    assetPath: 'assets/audio/alarm_zen_gong.wav',
    isPro: true,
  );

  static const AlarmChime tubularChime = AlarmChime(
    id: 'tubularChime',
    name: 'TUBULAR CHIME',
    category: 'HOROLOGICAL',
    description: 'Solid brass tubular grandfather clock chime',
    assetPath: 'assets/audio/alarm_tubular_chime.wav',
    isPro: true,
  );

  static const List<AlarmChime> all = [
    braunBell,
    deskBell,
    tibetanBowl,
    zenGong,
    tubularChime,
  ];

  static AlarmChime findById(String? id) {
    if (id == null) return braunBell;
    for (final chime in all) {
      if (chime.id == id) return chime;
    }
    return braunBell;
  }
}
