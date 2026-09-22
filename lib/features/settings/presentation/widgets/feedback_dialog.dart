import 'package:flutter/material.dart';
import '../../../../app/theme/takt_colors.dart';
import '../../../../app/theme/widgets/rsquare_hardware_plaque.dart';
import '../../../../core/haptics/haptic_service.dart';
import '../../../../core/services/url_service.dart';

/// Shows the Industrial Feedback Dispatch Dialog.
/// Allows the user to select the feedback category (Bug, Feature, Suggestion, Other)
/// and dispatches pre-filled email to support@zykl.app via Gmail / Email client
/// with automatic device telemetry diagnostics.
Future<void> showFeedbackDispatchDialog(
  BuildContext context, {
  bool isDark = true,
}) async {
  final primaryColor = isDark ? TaktColors.warmBone : const Color(0xFF141618);
  final secondaryColor = isDark ? const Color(0xFF9E9B93) : const Color(0xFF5A5D64);
  final bgColor = isDark ? TaktColors.basaltSlate : const Color(0xFFEDEAE2);
  final borderColor = isDark ? TaktColors.slateBorder : TaktColors.lightChassisBorder;
  final itemBgColor = isDark ? const Color(0xFF1E2126) : const Color(0xFFDFDBD0);

  const categories = [
    _FeedbackCategory(
      title: 'LAPORAN BUG',
      subtitle: 'Laporkan kendala visual, audio, atau malfungsi timer',
      icon: Icons.bug_report_outlined,
      iconColor: Color(0xFFEF4444),
      subjectPrefix: '[ZYKL Bug Report]',
      bodyHint: 'Jelaskan kendala/bug yang Anda alami:\n'
          '1. Apa yang terjadi:\n'
          '2. Langkah-langkah untuk memicu kendala:\n'
          '3. Ekspektasi tampilan/fungsi yang seharusnya:\n\n',
    ),
    _FeedbackCategory(
      title: 'PERMINTAAN FITUR',
      subtitle: 'Usulkan dial baru, mode fokus, atau hardware instrumen',
      icon: Icons.lightbulb_outline,
      iconColor: TaktColors.filamentAmber,
      subjectPrefix: '[ZYKL Feature Request]',
      bodyHint: 'Jelaskan fitur atau instrumen yang ingin ditambahkan:\n'
          '- Nama / Konsep Fitur:\n'
          '- Mengapa fitur ini berguna bagi sesi fokus Anda:\n\n',
    ),
    _FeedbackCategory(
      title: 'SARAN & MASUKAN',
      subtitle: 'Kritik, saran desain, atau pengalaman menggunakan ZYKL',
      icon: Icons.rate_review_outlined,
      iconColor: Color(0xFF10B981),
      subjectPrefix: '[ZYKL Suggestion]',
      bodyHint: 'Tuliskan saran, kritik, atau masukan untuk pengembangan ZYKL:\n\n',
    ),
    _FeedbackCategory(
      title: 'LAINNYA',
      subtitle: 'Pertanyaan umum, kolaborasi, atau pesan lainnya',
      icon: Icons.help_outline,
      iconColor: Color(0xFF60A5FA),
      subjectPrefix: '[ZYKL Inquiry]',
      bodyHint: 'Tuliskan pesan Anda kepada tim pengembang:\n\n',
    ),
  ];

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FEEDBACK DISPATCH',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SERVICE TRANSMISSION TERMINAL',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RsquareHardwarePlaque(size: 22, isDark: isDark, showRivets: false),
              const SizedBox(width: 5),
              const Text(
                'RSQUARE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: TaktColors.filamentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih kategori transmisi di bawah untuk membuka Gmail dengan subject & telemetri otomatis:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  color: secondaryColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              for (final cat in categories) ...[
                InkWell(
                  onTap: () async {
                    HapticService.selectionClick();
                    Navigator.of(dialogCtx).pop();
                    await _dispatchCategoryEmail(cat);
                  },
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: itemBgColor,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.iconColor.withValues(alpha: 0.12),
                            border: Border.all(
                              color: cat.iconColor.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(cat.icon, size: 16, color: cat.iconColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat.title,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cat.subtitle,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 8.5,
                                  color: secondaryColor,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios, size: 11, color: secondaryColor),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Transmisi terkirim ke support@zykl.app',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    color: secondaryColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(
            '[ TUTUP ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: secondaryColor,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _dispatchCategoryEmail(_FeedbackCategory cat) async {
  final deviceInfo = await UrlService.getDeviceInfo();

  final manufacturer = deviceInfo['manufacturer'] ?? 'Android';
  final model = deviceInfo['model'] ?? 'Device';
  final brand = deviceInfo['brand'] ?? '';
  final osVersion = deviceInfo['osVersion'] ?? '';
  final sdkInt = deviceInfo['sdkInt'] ?? '';
  final versionName = deviceInfo['versionName'] ?? '1.0.0';
  final versionCode = deviceInfo['versionCode'] ?? '104';

  final subject = '${cat.subjectPrefix} - $model';

  final body = StringBuffer()
    ..writeln('--- TULIS DETAIL LAPORAN ANDA DI SINI ---')
    ..write(cat.bodyHint)
    ..writeln('--------------------------------------------')
    ..writeln('// SYSTEM DIAGNOSTICS TELEMETRY')
    ..writeln('App: ZYKL Monastic Focus Instrument')
    ..writeln('Version: $versionName (Build $versionCode)')
    ..writeln('Package: com.zykl.app')
    ..writeln('Device: $manufacturer $model ($brand)')
    ..writeln('Android OS: Android $osVersion (API $sdkInt)')
    ..writeln('Timestamp: ${DateTime.now().toLocal().toString()}')
    ..writeln('--------------------------------------------');

  await UrlService.sendFeedbackEmail(
    type: cat.title,
    subject: subject,
    body: body.toString(),
  );
}

class _FeedbackCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String subjectPrefix;
  final String bodyHint;

  const _FeedbackCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.subjectPrefix,
    required this.bodyHint,
  });
}
