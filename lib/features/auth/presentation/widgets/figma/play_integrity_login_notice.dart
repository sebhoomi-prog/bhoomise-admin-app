import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/figma_typography.dart';

/// Disclosure for Firebase Phone Auth on Android (Play Integrity API — Firebase Console requirement).
class PlayIntegrityLoginNotice extends StatefulWidget {
  const PlayIntegrityLoginNotice({
    super.key,
    required this.muted,
    required this.linkColor,
  });

  final Color muted;
  final Color linkColor;

  @override
  State<PlayIntegrityLoginNotice> createState() =>
      _PlayIntegrityLoginNoticeState();
}

class _PlayIntegrityLoginNoticeState extends State<PlayIntegrityLoginNotice> {
  late final TapGestureRecognizer _openDocs;

  @override
  void initState() {
    super.initState();
    _openDocs = TapGestureRecognizer()..onTap = _launchOverview;
  }

  Future<void> _launchOverview() async {
    final uri = AppStrings.playIntegrityOverviewUri;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _openDocs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
        FigmaTypography.legalBody(widget.muted).copyWith(fontSize: 11, height: 1.4);
    final linkStyle = FigmaTypography.legalLink(widget.linkColor).copyWith(
      fontSize: 11,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: AppStrings.playIntegrityNoticeLead),
            TextSpan(
              text: AppStrings.playIntegrityNoticeLink,
              style: linkStyle,
              recognizer: _openDocs,
            ),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
