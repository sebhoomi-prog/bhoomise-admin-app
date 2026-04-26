import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../services/admin/admin_api_service.dart';
import '../../../../services/api/api_client.dart';

/// Lists users via REST API (admin read).
class AdminUsersDirectoryPage extends StatefulWidget {
  const AdminUsersDirectoryPage({super.key});

  @override
  State<AdminUsersDirectoryPage> createState() =>
      _AdminUsersDirectoryPageState();
}

class _AdminUsersDirectoryPageState extends State<AdminUsersDirectoryPage> {
  bool _loading = true;
  Object? _error;
  List<_UserRow> _rows = const [];
  int _partners = 0;
  int _customers = 0;

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
      final api = AdminApiService(Get.find<ApiClient>());
      final users = await api.listUsers();
      var p = 0;
      var c = 0;
      final rows = <_UserRow>[];
      for (final u in users) {
        final role = u.role?.trim() ?? '';
        final rl = role.toLowerCase();
        if (rl == 'partner' || rl == 'vendor' || rl == 'store' || rl == 'admin') {
          p++;
        } else {
          c++;
        }
        rows.add(
          _UserRow(
            uid: '${u.id}',
            displayName: u.name,
            role: role.isEmpty ? '—' : role,
            phoneHint: u.phone,
          ),
        );
      }
      rows.sort((a, b) => a.uid.compareTo(b.uid));
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _partners = p;
        _customers = c;
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
        title: const Text('User directory'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Could not load users',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_error',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Text(
                        'User profiles loaded from REST API.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(
                              label: 'In batch',
                              value: '${_rows.length}',
                              scheme: scheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatChip(
                              label: 'Partner / vendor',
                              value: '$_partners',
                              scheme: scheme,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatChip(
                              label: 'Customer / other',
                              value: '$_customers',
                              scheme: scheme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._rows.map(
                        (u) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: scheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusLg),
                              side: BorderSide(
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          u.displayName ?? 'No display name',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.primaryContainer
                                              .withValues(alpha: 0.5),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          u.role,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'UID · ${u.uid}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (u.phoneHint != null &&
                                      u.phoneHint!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        u.phoneHint!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _UserRow {
  const _UserRow({
    required this.uid,
    required this.displayName,
    required this.role,
    this.phoneHint,
  });

  final String uid;
  final String? displayName;
  final String role;
  final String? phoneHint;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.scheme,
  });

  final String label;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
