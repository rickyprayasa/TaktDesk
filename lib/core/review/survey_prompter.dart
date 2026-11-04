import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_visibility.dart';
import '../database/app_database.dart';
import '../focus/focus_lock_controller.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/timer/presentation/chrono_dial_controller.dart';

/// Which one-time survey to show: why someone bought Studio PRO, or why they stay on the free desk.
enum SurveyKind { pro, free }

final surveyPrompterProvider = Provider<SurveyPrompter>((ref) {
  final prompter = SurveyPrompter(ref.watch(appDatabaseProvider));
  ref.onDispose(prompter.dispose);
  return prompter;
});

/// Decides when the desk shows the short survey (answers go out by email, see FocusSurveyDialog). Each survey is
/// shown at most once per install, after a focus session has run to its end, with the app on screen and not in
/// lockdown:
/// - PRO: on the [proCyclesWithPro]th cycle completed since PRO switched on, so the answer comes from someone who
///   used it.
/// - Free: once the owner has completed [freeMinCycles] cycles without PRO.
/// A free user who buys later gets the PRO survey too. Never on the day Play's review sheet was requested.
class SurveyPrompter {
  static const int proCyclesWithPro = 3;
  static const int freeMinCycles = 15;

  final AppDatabase _db;

  /// Longer than ReviewPrompter's, so a review requested for the same session is already on record.
  final Duration settle;
  final _prompts = StreamController<SurveyKind>.broadcast();
  bool _busy = false;

  SurveyPrompter(this._db, {this.settle = const Duration(seconds: 4)});

  /// The desk shows the dialog for each event.
  Stream<SurveyKind> get prompts => _prompts.stream;

  /// The survey that was prompted, or null.
  Future<SurveyKind?> onFocusCompleted({
    required bool isPro,
    required bool Function() lockedDown,
    bool Function()? visible,
  }) async {
    final isVisible = visible ?? () => appIsVisible;
    if (_busy) return null;
    _busy = true;
    try {
      final kind = await _due(isPro);
      if (kind == null) return null;
      await Future<void>.delayed(settle);
      if (!isVisible() || lockedDown()) return null;
      final now = clock.now();
      final review = await _db.reviewAskedAt();
      if (review != null && now.difference(review) < const Duration(days: 1)) return null;
      if (kind == SurveyKind.pro) {
        await _db.markProSurveyAsked(now);
      } else {
        await _db.markFreeSurveyAsked(now);
      }
      if (!_prompts.isClosed) _prompts.add(kind);
      return kind;
    } catch (e) {
      debugPrint('ZYKL: survey prompt skipped: $e');
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<SurveyKind?> _due(bool isPro) async {
    if (isPro) {
      if (await _db.proSurveyAskedAt() != null) return null;
      final since = await _db.proSeenAt();
      if (since == null) {
        // Normally marked when PRO switched on (surveyPromptSyncProvider); from here on, sessions count.
        await _db.markProSeen(clock.now());
        return null;
      }
      return await _db.completedCycleCountSince(since) >= proCyclesWithPro ? SurveyKind.pro : null;
    }
    if (await _db.freeSurveyAskedAt() != null) return null;
    return await _db.completedCycleCount() >= freeMinCycles ? SurveyKind.free : null;
  }

  void dispose() => _prompts.close();
}

/// Watched by the desk: listens for finished focus sessions for as long as the desk is up.
final surveyPromptSyncProvider = Provider.autoDispose<void>((ref) {
  final prompter = ref.watch(surveyPrompterProvider);
  final db = ref.watch(appDatabaseProvider);
  // Sessions that start after PRO switched on (a purchase, or Play's restore at launch) count towards its survey.
  ref.listen<bool>(deskPreferencesControllerProvider.select((p) => p.isProSimulated), (_, isPro) {
    if (isPro) db.markProSeen(clock.now());
  }, fireImmediately: true);
  final timer = ref.watch(chronoDialProvider.notifier);
  final subscription = timer.focusCompleted.listen((_) {
    prompter.onFocusCompleted(
      isPro: ref.read(deskPreferencesControllerProvider).isProSimulated,
      lockedDown: () => ref.read(focusLockProvider).isLocked,
    );
  });
  ref.onDispose(subscription.cancel);
});
