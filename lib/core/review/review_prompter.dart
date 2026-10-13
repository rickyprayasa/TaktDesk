import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../app_visibility.dart';
import '../database/app_database.dart';
import '../focus/focus_lock_controller.dart';
import '../../features/timer/presentation/chrono_dial_controller.dart';

/// The Play in-app review sheet, behind an interface so tests can stand in for Play.
abstract class ReviewRequester {
  Future<bool> isAvailable();
  Future<void> requestReview();
}

class PlayReviewRequester implements ReviewRequester {
  const PlayReviewRequester();

  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> requestReview() => InAppReview.instance.requestReview();
}

final reviewRequesterProvider = Provider<ReviewRequester>((ref) => const PlayReviewRequester());

final reviewPrompterProvider = Provider<ReviewPrompter>((ref) {
  return ReviewPrompter(ref.watch(appDatabaseProvider), ref.watch(reviewRequesterProvider));
});

/// Asks for a Play rating once per install: after a focus session has run to its end, once the owner has completed
/// [minCompletedCycles] cycles, with the app on screen and not in lockdown (a pinned screen can't show Play's sheet).
/// Play decides whether the sheet really appears (quota); either way the app never asks again.
class ReviewPrompter {
  static const int minCompletedCycles = 10;

  final AppDatabase _db;
  final ReviewRequester _requester;

  /// Lets the finish chime and the phase change land before the sheet slides up.
  final Duration settle;
  bool _busy = false;

  ReviewPrompter(this._db, this._requester, {this.settle = const Duration(seconds: 3)});

  /// true when the review was requested.
  Future<bool> onFocusCompleted({required bool Function() lockedDown, bool Function()? visible}) async {
    final isVisible = visible ?? () => appIsVisible;
    if (_busy) return false;
    _busy = true;
    try {
      if (await _db.reviewAskedAt() != null) return false;
      // The session that just ended may still be on its way to the database: then it is the 11th that asks.
      if (await _db.completedCycleCount() < minCompletedCycles) return false;
      await Future<void>.delayed(settle);
      if (!isVisible() || lockedDown()) return false;
      if (!await _requester.isAvailable()) return false;
      await _db.markReviewAsked(clock.now());
      await _requester.requestReview();
      return true;
    } catch (e) {
      debugPrint('ZYKL: review prompt skipped: $e');
      return false;
    } finally {
      _busy = false;
    }
  }
}

/// Watched by the desk: listens for finished focus sessions for as long as the desk is up.
final reviewPromptSyncProvider = Provider.autoDispose<void>((ref) {
  final prompter = ref.watch(reviewPrompterProvider);
  final timer = ref.watch(chronoDialProvider.notifier);
  final subscription = timer.focusCompleted.listen((_) {
    prompter.onFocusCompleted(lockedDown: () => ref.read(focusLockProvider).isLocked);
  });
  ref.onDispose(subscription.cancel);
});
