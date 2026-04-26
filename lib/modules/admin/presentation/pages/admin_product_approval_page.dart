import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/api/admin_api_models.dart';
import '../../../../services/admin/admin_api_service.dart';
import '../../../../services/api/api_client.dart';
import '../widgets/admin_keyboard.dart';

/// **Product Approval** — curate vendor submissions from API.
class AdminProductApprovalPage extends StatefulWidget {
  const AdminProductApprovalPage({super.key});

  @override
  State<AdminProductApprovalPage> createState() =>
      _AdminProductApprovalPageState();
}

class _AdminProductApprovalPageState extends State<AdminProductApprovalPage> {
  bool _archiveSelected = false;
  List<ListingSubmission> _submissions = [];
  bool _loading = true;
  String? _error;
  late final AdminApiService _api;

  @override
  void initState() {
    super.initState();
    _api = AdminApiService(Get.find<ApiClient>());
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final submissions = await _api.listSubmissions();
      if (!mounted) return;
      setState(() {
        _submissions = submissions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<ListingSubmission> get _pendingSubmissions =>
      _submissions.where((s) {
        final status = s.approvalStatus?.toLowerCase() ?? '';
        return status.isEmpty || status == 'pending';
      }).toList();

  List<ListingSubmission> get _archivedSubmissions =>
      _submissions.where((s) {
        final status = s.approvalStatus?.toLowerCase() ?? '';
        return status == 'approved' || status == 'rejected';
      }).toList();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const barH = 80.0;
    final contentTop = top + barH + 8;

    if (_loading) {
      return const ColoredBox(
        color: Color(0xFFF8F9FA),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: const Color(0xFFF8F9FA),
        child: ErrorStateWidget(
          message: _error!,
          onRetry: _loadSubmissions,
        ),
      );
    }

    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RefreshIndicator(
            onRefresh: _loadSubmissions,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, contentTop, 24, 120),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VENDOR SUBMISSIONS',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 16 / 12,
                            letterSpacing: 2.4,
                            color: DesignTokens.figmaHeroCtaGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Product Approval',
                          style: GoogleFonts.manrope(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -1.2,
                            color: DesignTokens.figmaSectionInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review and approve vendor product submissions.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 26 / 16,
                            color: const Color(0xFF555F6F),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _FilterPill(
                          archiveLabel: 'Archived',
                          pendingLabel: 'Pending',
                          pendingCount: _pendingSubmissions.length,
                          archiveSelected: _archiveSelected,
                          onArchive: () =>
                              setState(() => _archiveSelected = true),
                          onPending: () =>
                              setState(() => _archiveSelected = false),
                        ),
                        const SizedBox(height: 48),
                        if (_submissions.isEmpty)
                          const EmptyStateWidget(
                            title: 'No Submissions',
                            message: 'Vendor product submissions will appear here for review.',
                            icon: Icons.assignment_outlined,
                          )
                        else if (_archiveSelected) ...[
                          if (_archivedSubmissions.isEmpty)
                            _EmptyQueueCard(
                              title: 'No Archived Submissions',
                              subtitle: 'Approved and rejected submissions will appear here.',
                            )
                          else
                            ..._buildSubmissionCards(_archivedSubmissions),
                        ] else ...[
                          if (_pendingSubmissions.isEmpty)
                            _EmptyQueueCard(
                              title: 'Queue Clear',
                              subtitle: 'No pending submissions to review.',
                            )
                          else
                            ..._buildSubmissionCards(_pendingSubmissions),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ProductApprovalAppBar(
              topPadding: top,
              title: AppStrings.appName,
              onGridTap: () {
                adminDismissKeyboard();
                Get.snackbar(
                  'Shortcuts',
                  'Use bottom navigation to switch admin sections.',
                );
              },
              onBellTap: () {
                adminDismissKeyboard();
                Get.snackbar(
                  'Notifications',
                  'Alerts will appear here when connected to backend.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubmissionCards(List<ListingSubmission> submissions) {
    final out = <Widget>[];
    for (var i = 0; i < submissions.length; i++) {
      final s = submissions[i];
      if (i > 0) out.add(const SizedBox(height: 16));
      out.add(_SubmissionCard(
        submission: s,
        onApprove: () => _approveSubmission(s),
        onReject: () => _rejectSubmission(s),
      ));
    }
    return out;
  }

  Future<void> _approveSubmission(ListingSubmission s) async {
    try {
      await _api.updateSubmission(s.id!, approvalStatus: 'approved');
      Get.snackbar('Approved', 'Submission has been approved.');
      _loadSubmissions();
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve: $e');
    }
  }

  Future<void> _rejectSubmission(ListingSubmission s) async {
    try {
      await _api.updateSubmission(s.id!, approvalStatus: 'rejected');
      Get.snackbar('Rejected', 'Submission has been rejected.');
      _loadSubmissions();
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject: $e');
    }
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.submission,
    required this.onApprove,
    required this.onReject,
  });

  final ListingSubmission submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = submission.approvalStatus?.toLowerCase() ?? 'pending';
    final isPending = status.isEmpty || status == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: DesignTokens.figmaHeroCtaGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.title,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.figmaSectionInk,
                      ),
                    ),
                    Text(
                      'Stock: ${submission.stock ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF555F6F),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFFF7ED)
                      : status == 'approved'
                          ? const Color(0xFFD1FAE5)
                          : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isPending
                        ? const Color(0xFFEA580C)
                        : status == 'approved'
                            ? const Color(0xFF065F46)
                            : const Color(0xFF9F1239),
                  ),
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.figmaHeroCtaGreen,
                    ),
                    child: const Text('Approve'),
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

class _EmptyQueueCard extends StatelessWidget {
  const _EmptyQueueCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF555F6F),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductApprovalAppBar extends StatelessWidget {
  const _ProductApprovalAppBar({
    required this.topPadding,
    required this.title,
    required this.onGridTap,
    required this.onBellTap,
  });

  final double topPadding;
  final String title;
  final VoidCallback onGridTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: topPadding,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed: onGridTap,
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: DesignTokens.figmaPinIconGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 32 / 24,
                        letterSpacing: -0.6,
                        color: DesignTokens.figmaDeliverGreen,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onBellTap,
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: DesignTokens.figmaLabelMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.archiveLabel,
    required this.pendingLabel,
    required this.pendingCount,
    required this.archiveSelected,
    required this.onArchive,
    required this.onPending,
  });

  final String archiveLabel;
  final String pendingLabel;
  final int pendingCount;
  final bool archiveSelected;
  final VoidCallback onArchive;
  final VoidCallback onPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color(0x26BDCABA),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              selected: archiveSelected,
              selectedFill: archiveSelected
                  ? const Color(0xFFE2E8F0)
                  : Colors.transparent,
              onTap: onArchive,
              child: Text(
                archiveLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  color: const Color(0xFF555F6F),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SegButton(
              selected: !archiveSelected,
              selectedFill: DesignTokens.figmaHeroCtaGreen,
              onTap: onPending,
              shadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              child: Text(
                '$pendingLabel ($pendingCount)',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                  color: !archiveSelected ? Colors.white : const Color(0xFF555F6F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.selected,
    required this.selectedFill,
    required this.onTap,
    required this.child,
    this.shadow,
  });

  final bool selected;
  final Color selectedFill;
  final VoidCallback onTap;
  final Widget child;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedFill : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9999),
            boxShadow: selected ? shadow : null,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final url = data['image_url'] as String? ?? '';
    final tags = (data['tags'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 256,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url.isNotEmpty)
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: DesignTokens.figmaCategoryCard,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  )
                else
                  Container(color: DesignTokens.figmaCategoryCard),
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (data['badge'] as String? ?? 'FEATURED')
                                  .toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 15 / 10,
                                letterSpacing: 1,
                                color: DesignTokens.figmaSectionInk,
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
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] as String? ?? '',
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              height: 36 / 30,
                              color: DesignTokens.figmaSectionInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (data['vendor_verified'] == true) ...[
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: DesignTokens.figmaHeroCtaGreen,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  data['vendor'] as String? ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 20 / 14,
                                    color: const Color(0xFF555F6F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          data['price'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 32 / 24,
                            color: DesignTokens.figmaHeroCtaGreen,
                          ),
                        ),
                        Text(
                          data['per_unit'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 15 / 10,
                            letterSpacing: -0.5,
                            color: const Color(0xFF555F6F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data['description'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 23 / 14,
                    color: const Color(0xCC3E4A3D),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.figmaCategoryCard,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            t.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 15 / 10,
                              letterSpacing: 0.5,
                              color: const Color(0xFF555F6F),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF006B2C),
                              Color(0xFF00873A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: () {
                              adminDismissKeyboard();
                              Get.snackbar(
                                'Approve',
                                'Queue is demo data; wire vendor approvals to Firestore when ready.',
                              );
                            },
                            borderRadius: BorderRadius.circular(9999),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  data['approve_label'] as String? ??
                                      'Approve Item',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 20 / 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        adminDismissKeyboard();
                        Get.snackbar(
                          'Reject',
                          'Queue is demo data; persist rejections when backend is connected.',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA1A1A),
                        side: BorderSide(
                          color: const Color(0x4DBDCABA),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Text(
                        data['reject_label'] as String? ?? 'Reject',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewerNoteCard extends StatelessWidget {
  const _ReviewerNoteCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] as String? ?? 'Reviewer Note',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: DesignTokens.figmaHeroCtaGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['body'] as String? ?? '',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 19 / 14,
              color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = (data['rows'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0x1ABDCABA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] as String? ?? 'Pipeline Status',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 24 / 16,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _PipelineRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final p = (row['progress'] as num?)?.toDouble() ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                row['label'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 20 / 14,
                  color: const Color(0xFF555F6F),
                ),
              ),
            ),
            Text(
              row['count'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
                color: DesignTokens.figmaSectionInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(9999),
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFFD9E3F6)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: p.clamp(0.0, 1.0),
                  child: Container(color: DesignTokens.figmaHeroCtaGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryQueueTile extends StatelessWidget {
  const _SecondaryQueueTile({required this.data});

  final Map<String, dynamic> data;

  Color _tone(String? t) {
    switch (t) {
      case 'warning':
        return const Color(0xFFD97706);
      case 'brand':
        return DesignTokens.figmaHeroCtaGreen;
      case 'success':
      default:
        return const Color(0xFF16A34A);
    }
  }

  IconData _toneIcon(String? t) {
    switch (t) {
      case 'warning':
        return Icons.whatshot_rounded;
      case 'brand':
        return Icons.eco_rounded;
      case 'success':
      default:
        return Icons.verified_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone(data['status_tone'] as String?);
    final toneIcon = _toneIcon(data['status_tone'] as String?);
    final thumb = data['thumb_url'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: thumb.isNotEmpty
                      ? Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: DesignTokens.figmaCategoryCard,
                          ),
                        )
                      : Container(color: DesignTokens.figmaCategoryCard),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String? ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 28 / 18,
                        color: DesignTokens.figmaSectionInk,
                      ),
                    ),
                    Text(
                      data['vendor'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 20 / 14,
                        color: const Color(0xFF555F6F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(toneIcon, size: 14, color: tone),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (data['status_badge'] as String? ?? '')
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 15 / 10,
                              letterSpacing: 1,
                              color: tone,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton(
                onPressed: () {
                  adminDismissKeyboard();
                  Get.snackbar(
                    'Approve',
                    'Secondary queue is mock; connect listings API to save.',
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDEE9FC),
                  foregroundColor: DesignTokens.figmaSectionInk,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: Text(
                  'Approve',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  adminDismissKeyboard();
                  Get.snackbar(
                    'Dismiss',
                    'Removed from view locally; persist when backend is wired.',
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  maximumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: const Color(0x33BDCABA),
                  ),
                  shape: const CircleBorder(),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
