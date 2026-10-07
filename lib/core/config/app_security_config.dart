import 'package:flutter/foundation.dart';

/// Centralized security and environment configuration for ZYKL.
///
/// Ensures developer simulation toggles and automatic PRO clearances
/// are strictly stripped and disabled in Production Google Play Store builds,
/// while remaining conveniently available in local debug and internal test builds.
abstract class AppSecurityConfig {
  /// Whether PRO features are automatically simulated/unlocked for testing.
  ///
  /// Enabled automatically in [kDebugMode] or when built with:
  /// `--dart-define=ENABLE_PRO_SIMULATION=true`
  ///
  /// In standard Production Release builds, this evaluates to `false`.
  static const bool isProSimulationEnabled = bool.fromEnvironment(
    'ENABLE_PRO_SIMULATION',
    defaultValue: kDebugMode,
  );

  /// Whether developer preview switches and override tools are exposed in the UI.
  ///
  /// In standard Production Release builds, this evaluates to `false`,
  /// completely stripping developer controls from the Settings widget tree.
  ///
  /// Promo footage capture (`film_capture/`, `--dart-define=FILM_HIDE_DEV_TOOLS=true`)
  /// runs in debug mode but must look like the store build.
  static const bool showDeveloperTools = !bool.fromEnvironment('FILM_HIDE_DEV_TOOLS') &&
      (kDebugMode ||
          bool.fromEnvironment(
            'ENABLE_PRO_SIMULATION',
            defaultValue: false,
          ));
}
