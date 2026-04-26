import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../services/api/api_client.dart';
import '../../data/admin_metrics_api_service.dart';

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
      final client = Get.find<ApiClient>();
      final service = AdminMetricsApiService(client);
      final m = await service.fetch();
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
            'API Backend',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Bhoomise PHP API',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This screen displays operational metrics fetched from the REST API.',
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
