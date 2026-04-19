import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../firebase_options.dart';
import '../../data/admin_metrics_firestore.dart';

/// Environment summary and live metric refresh (no downtime controls — informational).
class AdminPlatformConsolePage extends StatefulWidget {
  const AdminPlatformConsolePage({super.key});

  @override
  State<AdminPlatformConsolePage> createState() =>
      _AdminPlatformConsolePageState();
}

class _AdminPlatformConsolePageState extends State<AdminPlatformConsolePage> {
  bool _busy = false;
  AdminMetricsSnapshot? _snap;
  Object? _err;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final m = await AdminMetricsFirestore().fetch();
      if (!mounted) return;
      setState(() {
        _snap = m;
        _busy = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final opts = DefaultFirebaseOptions.currentPlatform;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Firebase project',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            opts.projectId,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Firebase Console for indexes, quotas, and App Check. '
            'This screen only reads operational snapshots.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          Text(
            'Live snapshot',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (_err != null)
            Text('$_err', style: TextStyle(color: scheme.error))
          else if (_snap != null) ...[
            _line('Orders (sample)', '${_snap!.orderCount}'),
            _line('User profiles (sample)', '${_snap!.userProfilesSnapshotCount}'),
            _line('Listing queue pending', '${_snap!.pendingSubmissionCount}'),
            _line('Products (sample)', '${_snap!.productCount}'),
            if (_snap!.loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Partial: ${_snap!.loadError}',
                  style: TextStyle(color: scheme.tertiary, fontSize: 12),
                ),
              ),
          ],
          const SizedBox(height: 32),
          Text(
            'Maintenance',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scheduled downtime and database maintenance are managed in Firebase / GCP — '
            'not from this app. Use this page to verify connectivity and snapshot counts.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  Widget _line(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DesignTokens.figmaLabelMuted,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: DesignTokens.figmaSectionInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
