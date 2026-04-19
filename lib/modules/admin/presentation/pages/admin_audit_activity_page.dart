import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../data/admin_metrics_firestore.dart';

/// Order pipeline snapshot + recent order documents (admin-readable).
class AdminAuditActivityPage extends StatefulWidget {
  const AdminAuditActivityPage({super.key});

  @override
  State<AdminAuditActivityPage> createState() => _AdminAuditActivityPageState();
}

class _AdminAuditActivityPageState extends State<AdminAuditActivityPage> {
  bool _loading = true;
  AdminMetricsSnapshot? _metrics;
  List<Map<String, dynamic>> _orderRows = [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final metrics = await AdminMetricsFirestore().fetch();
      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .limit(40)
          .get();
      final rows = <Map<String, dynamic>>[];
      for (final d in orders.docs) {
        final m = d.data();
        rows.add({
          'id': d.id,
          'status': m['status'] ?? '—',
          'storeId': m['storeId'] ?? '—',
          'customerId': m['customerId'] ?? '—',
        });
      }
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _orderRows = rows;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit · activity'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_metrics?.loadError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Metrics note: ${_metrics!.loadError}',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      Text(
                        'Pipeline snapshot',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _pill(
                            context,
                            'Orders (≤400)',
                            '${_metrics?.orderCount ?? 0}',
                          ),
                          _pill(
                            context,
                            'User profiles',
                            '${_metrics?.userProfilesSnapshotCount ?? 0}',
                          ),
                          _pill(
                            context,
                            'Pending listings',
                            '${_metrics?.pendingSubmissionCount ?? 0}',
                          ),
                          _pill(
                            context,
                            'Catalog SKUs',
                            '${_metrics?.productCount ?? 0}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Recent orders (40)',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_orderRows.isEmpty)
                        Text(
                          'No order documents in snapshot.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ..._orderRows.map(
                          (r) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                '${r['id']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                'status: ${r['status']} · store: ${r['storeId']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _pill(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
