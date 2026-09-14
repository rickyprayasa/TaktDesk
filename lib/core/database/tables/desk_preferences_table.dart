import 'package:drift/drift.dart';

class DeskPreferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get soundVolume => real().withDefault(const Constant(0.8))();
  BoolColumn get parallaxEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get activeAmbientTrackIndex => integer().withDefault(const Constant(0))();
  BoolColumn get foleyEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get hapticsEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get selectedEdition => text().withDefault(const Constant('braunClassic'))();
  BoolColumn get isProSimulated => boolean().withDefault(const Constant(true))();
  RealColumn get primaryVolume => real().withDefault(const Constant(0.80))();
  RealColumn get crackleVolume => real().withDefault(const Constant(0.35))();
  RealColumn get binauralVolume => real().withDefault(const Constant(0.25))();
  BoolColumn get primaryMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get crackleMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get binauralMuted => boolean().withDefault(const Constant(false))();
}
