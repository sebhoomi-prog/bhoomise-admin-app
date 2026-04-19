import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/admin_listing_submissions_service.dart';

/// Treats legacy / inconsistent Firestore values as still awaiting review.
bool _submissionIsPending(Map<String, dynamic> m) {
  final raw = m['approvalStatus'];
  if (raw == null) return true;
  if (raw is! String) return true;
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return true;
  return s == 'pending';
}

String _statusChipLabel(Map<String, dynamic> m) {
  final raw = m['approvalStatus'];
  if (raw == null || (raw is String && raw.trim().isEmpty)) return 'pending';
  if (raw is String) return raw.trim().toLowerCase();
  return 'pending';
}

String _formatFirestoreTime(dynamic value) {
  if (value is Timestamp) {
    final d = value.toDate().toLocal();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd · $hh:$min';
  }
  return '—';
}

/// Admin **SPORE** — approve or reject vendor mushroom uploads (`listing_submissions`).
class AdminVendorListingApprovalsPage extends StatefulWidget {
  const AdminVendorListingApprovalsPage({super.key});

  @override
  State<AdminVendorListingApprovalsPage> createState() =>
      _AdminVendorListingApprovalsPageState();
}

class _AdminVendorListingApprovalsPageState
    extends State<AdminVendorListingApprovalsPage> {
  final _svc = AdminListingSubmissionsService();
  String? _busyId;

  Future<void> _approve(String id) async {
    setState(() => _busyId = id);
    try {
      await _svc.approve(id);
      if (!mounted) return;
      Get.snackbar('Approved', 'Listing published to catalog and store inventory.');
    } on Object catch (e) {
      Get.snackbar('Approve failed', '$e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _rejectDialog(String id) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject listing?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject')),
        ],
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busyId = id);
    try {
      await _svc.reject(submissionId: id, reason: reason);
      if (!mounted) return;
      Get.snackbar('Rejected', 'Vendor will see status on their listings.');
    } on Object catch (e) {
      Get.snackbar('Reject failed', '$e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const headerH = 72.0;
    final bodyTop = topInset + headerH + 24;

    return Scaffold(
      backgroundColor: DesignTokens.figmaHeaderFrostTint,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  bodyTop,
                  24,
                  120 + MediaQuery.paddingOf(context).bottom,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VENDOR UPLOADS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: DesignTokens.figmaStoreMeta,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Approve mushroom listings',
                        style: GoogleFonts.manrope(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 36 / 30,
                          color: DesignTokens.figmaSectionInk,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pending submissions appear here. Approving publishes to the customer catalog and links inventory to the vendor store.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 22 / 15,
                          color: const Color(0xFF3E4A3D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              Get.toNamed(AppRoutes.adminMasterProducts),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Master catalog (browse all SKUs)'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _svc.watchAll(),
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return Text(
                              'Could not load listing submissions: ${snap.error}',
                              style: const TextStyle(color: Colors.red),
                            );
                          }
                          if (!snap.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final docs = snap.data!.docs;
                          if (docs.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Text(
                                'No listing submissions yet.',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: DesignTokens.figmaLabelMuted,
                                ),
                              ),
                            );
                          }
                          final pending = docs
                              .where((d) => _submissionIsPending(d.data()))
                              .toList();
                          final reviewed = docs
                              .where((d) => !_submissionIsPending(d.data()))
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending (${pending.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: DesignTokens.figmaStoreMeta,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (pending.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'No pending listings right now.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: DesignTokens.figmaLabelMuted,
                                    ),
                                  ),
                                )
                              else
                                ...pending.map((d) {
                                  final m = d.data();
                                  final rupees =
                                      ((m['priceMinor'] as num?)?.toInt() ?? 0) /
                                          100;
                                  final stock =
                                      (m['stock'] as num?)?.toInt() ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _SubmissionCard(
                                      id: d.id,
                                      title: m['title'] as String? ?? '—',
                                      varietyLabel:
                                          m['varietyLabel'] as String? ?? '',
                                      storeId: m['storeId'] as String? ?? '—',
                                      submittedByUid:
                                          m['submittedByUid'] as String? ?? '',
                                      description:
                                          m['description'] as String? ?? '',
                                      imageUrl: m['imageUrl'] as String? ?? '',
                                      submittedAtLabel: _formatFirestoreTime(
                                        m['submittedAt'],
                                      ),
                                      priceLabel: '₹${rupees.round()}',
                                      stock: stock,
                                      status: _statusChipLabel(m),
                                      rejectionReason:
                                          m['rejectionReason'] as String? ?? '',
                                      busy: _busyId == d.id,
                                      onApprove: () => _approve(d.id),
                                      onReject: () => _rejectDialog(d.id),
                                    ),
                                  );
                                }),
                              if (reviewed.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reviewed (${reviewed.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: DesignTokens.figmaStoreMeta,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...reviewed.map((d) {
                                  final m = d.data();
                                  final rupees =
                                      ((m['priceMinor'] as num?)?.toInt() ?? 0) /
                                          100;
                                  final stock =
                                      (m['stock'] as num?)?.toInt() ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _SubmissionCard(
                                      id: d.id,
                                      title: m['title'] as String? ?? '—',
                                      varietyLabel:
                                          m['varietyLabel'] as String? ?? '',
                                      storeId: m['storeId'] as String? ?? '—',
                                      submittedByUid:
                                          m['submittedByUid'] as String? ?? '',
                                      description:
                                          m['description'] as String? ?? '',
                                      imageUrl: m['imageUrl'] as String? ?? '',
                                      submittedAtLabel: _formatFirestoreTime(
                                        m['submittedAt'],
                                      ),
                                      priceLabel: '₹${rupees.round()}',
                                      stock: stock,
                                      status: _statusChipLabel(m),
                                      rejectionReason:
                                          m['rejectionReason'] as String? ?? '',
                                      busy: false,
                                      onApprove: null,
                                      onReject: null,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ApprovalsTopBar(
              height: headerH,
              topPadding: topInset,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalsTopBar extends StatelessWidget {
  const _ApprovalsTopBar({
    required this.height,
    required this.topPadding,
  });

  final double height;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: DesignTokens.figmaHeaderFrostTint.withValues(alpha: 0.92),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          left: 24,
          right: 24,
          bottom: 12,
        ),
        child: SizedBox(
          height: height - 12,
          child: Row(
            children: [
              Icon(Icons.science_outlined,
                  color: DesignTokens.figmaHeroCtaGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Listing approvals',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.figmaDeliverGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.id,
    required this.title,
    required this.varietyLabel,
    required this.storeId,
    required this.submittedByUid,
    required this.description,
    required this.imageUrl,
    required this.submittedAtLabel,
    required this.priceLabel,
    required this.stock,
    required this.status,
    required this.rejectionReason,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final String id;
  final String title;
  final String varietyLabel;
  final String storeId;
  final String submittedByUid;
  final String description;
  final String imageUrl;
  final String submittedAtLabel;
  final String priceLabel;
  final int stock;
  final String status;
  final String rejectionReason;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final showActions = onApprove != null && onReject != null;
    final imageOk = imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1ABDCABA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageOk) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  imageUrl.trim(),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return ColoredBox(
                      color: const Color(0xFFEFF4FF),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.figmaHeroCtaGreen,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    (progress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: const Color(0xFFF3F4F6),
                    child: Icon(
                      Icons.hide_image_outlined,
                      color: DesignTokens.figmaLabelMuted,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          if (varietyLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Variety: ${varietyLabel.trim()}',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                color: DesignTokens.figmaStoreMeta,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SelectableText(
            'Submission ID: $id',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: DesignTokens.figmaStoreMeta,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Store: $storeId'
            '${submittedByUid.isNotEmpty ? ' · Vendor UID: $submittedByUid' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: DesignTokens.figmaStoreMeta,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitted: $submittedAtLabel',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: DesignTokens.figmaStoreMeta,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description.trim().isEmpty ? '—' : description,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 20 / 14,
              color: const Color(0xFF3E4A3D),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                priceLabel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.figmaHeroCtaGreen,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Stock: $stock',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DesignTokens.figmaSectionInk,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? const Color(0xFFEFF4FF)
                      : status == 'approved'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: status == 'pending'
                        ? DesignTokens.figmaDeliverGreen
                        : status == 'approved'
                            ? const Color(0xFF166534)
                            : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          if (status == 'rejected' && rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: ${rejectionReason.trim()}',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 18 / 13,
                color: const Color(0xFF991B1B),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.figmaHeroCtaGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, DesignTokens.buttonMinHeight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve & publish'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, DesignTokens.buttonMinHeight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
