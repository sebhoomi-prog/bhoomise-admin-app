import 'dart:ui' show ImageFilter;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/notifications/in_app_notifications.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../data/admin_metrics_firestore.dart';
import '../../navigation/presentation/controllers/admin_shell_controller.dart';

const Color _kGreen = Color(0xFF006B2C);
const Color _kGreenAlt = Color(0xFF00873A);
const Color _kInk = Color(0xFF121C2A);
const Color _kMeta = Color(0xFF5D5D4E);
const Color _kBodyMuted = Color(0xFF3E4A3D);
const Color _kMetricsBg = Color(0xFFEFF4FF);
const Color _kChevron = Color(0xFFBDCABA);
const String _kAvatarUrl =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&fit=crop&w=400&q=80';

/// Admin shell **Profile** tab — Figma admin profile (hero, bento metrics, orchestration).
class AdminProfileTabPage extends StatefulWidget {
  const AdminProfileTabPage({super.key});

  @override
  State<AdminProfileTabPage> createState() => _AdminProfileTabPageState();
}

class _AdminProfileTabPageState extends State<AdminProfileTabPage> {
  AdminMetricsSnapshot? _metrics;
  DateTime? _metricsAt;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final m = await AdminMetricsFirestore().fetch();
    if (!mounted) return;
    setState(() {
      _metrics = m;
      _metricsAt = DateTime.now();
    });
  }

  void _openSettingsSheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_outline_rounded, color: scheme.primary),
              title: const Text('Edit profile'),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(AppRoutes.profileEdit);
              },
            ),
            ListTile(
              leading: Icon(Icons.groups_outlined, color: scheme.primary),
              title: const Text('User directory'),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(AppRoutes.adminUsersDirectory);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics_outlined, color: scheme.primary),
              title: const Text('Audit · activity'),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(AppRoutes.adminAuditActivity);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard_customize_outlined,
                  color: scheme.primary),
              title: const Text('Customer home tiles'),
              onTap: () {
                Navigator.pop(ctx);
                Get.toNamed(AppRoutes.adminCustomerHome);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    const headerH = 64.0;
    final scrollTop = topInset + headerH + 32;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      backgroundColor: DesignTokens.figmaHeaderFrostTint,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, scrollTop, 24, bottomPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AdminHeroSection(avatarUrl: _kAvatarUrl),
                  const SizedBox(height: 40),
                  _AdminBentoMetrics(
                    metrics: _metrics,
                    metricsAt: _metricsAt,
                    onRefresh: _loadMetrics,
                  ),
                  const SizedBox(height: 24),
                  const _AdminQuickActions(),
                  const SizedBox(height: 24),
                  const _AdminAlertsFeed(),
                  const SizedBox(height: 40),
                  _CoreOrchestrationList(metrics: _metrics),
                  const SizedBox(height: 40),
                  _LogoutSecureSection(
                    onLogout: () => Get.find<AuthController>().signOutUser(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _AdminProfileHeader(
              topInset: topInset,
              height: headerH,
              onSettings: _openSettingsSheet,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProfileHeader extends StatelessWidget {
  const _AdminProfileHeader({
    required this.topInset,
    required this.height,
    required this.onSettings,
  });

  final double topInset;
  final double height;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF).withValues(alpha: 0.7),
          ),
          child: SizedBox(
            height: height - 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.navProfile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        height: 32 / 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: _kGreen,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSettings,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: _kGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeroSection extends StatelessWidget {
  const _AdminHeroSection({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -4,
                  right: -4,
                  top: -4,
                  bottom: -4,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Opacity(
                      opacity: 0.25,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_kGreen, _kGreenAlt],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 25,
                        offset: const Offset(0, 20),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: _kMetricsBg,
                        child: Icon(
                          Icons.person_rounded,
                          size: 56,
                          color: _kGreen.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 29,
                    height: 29,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kGreen,
                      border: Border.all(
                        color: DesignTokens.figmaHeaderFrostTint,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'SYSTEM ADMINISTRATOR',
          style: GoogleFonts.inter(
            fontSize: 10,
            height: 15 / 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: _kMeta,
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          String name = 'Jordan Thorne';
          return Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 36,
              height: 40 / 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
              color: _kInk,
            ),
          );
        }),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _kMetricsBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0x26BDCABA),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: _kGreen),
              const SizedBox(width: 8),
              Text(
                'SECURITY LEVEL: LEVEL 5',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _kBodyMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminQuickActions extends StatelessWidget {
  const _AdminQuickActions();

  void _tab(int i) {
    if (Get.isRegistered<AdminShellController>()) {
      Get.find<AdminShellController>().setTab(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'QUICK ACTIONS',
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 15 / 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: _kMeta,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: Text(
                'SPORE · reviews',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              avatar: Icon(Icons.science_outlined, size: 18, color: _kGreen),
              backgroundColor: Colors.white,
              side: BorderSide(color: _kChevron.withValues(alpha: 0.5)),
              onPressed: () => _tab(1),
            ),
            ActionChip(
              label: Text(
                'MARKET',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              avatar:
                  Icon(Icons.storefront_outlined, size: 18, color: _kGreen),
              backgroundColor: Colors.white,
              side: BorderSide(color: _kChevron.withValues(alpha: 0.5)),
              onPressed: () => _tab(0),
            ),
            ActionChip(
              label: Text(
                'Users',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              avatar: Icon(Icons.groups_outlined, size: 18, color: _kGreen),
              backgroundColor: Colors.white,
              side: BorderSide(color: _kChevron.withValues(alpha: 0.5)),
              onPressed: () => Get.toNamed(AppRoutes.adminUsersDirectory),
            ),
            ActionChip(
              label: Text(
                'Customer home',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              avatar: Icon(Icons.dashboard_customize_outlined,
                  size: 18, color: _kGreen),
              backgroundColor: Colors.white,
              side: BorderSide(color: _kChevron.withValues(alpha: 0.5)),
              onPressed: () => Get.toNamed(AppRoutes.adminCustomerHome),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminAlertsFeed extends StatelessWidget {
  const _AdminAlertsFeed();

  String _timeShort(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate().toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final inbox = InAppNotifications();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'ALERTS · VENDOR SUBMISSIONS',
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 15 / 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: _kMeta,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: inbox.watchAdminFeed(limit: 12),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text(
                'Could not load alerts (${snap.error})',
                style: GoogleFonts.inter(fontSize: 13, color: _kBodyMuted),
              );
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _kChevron.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'No pending signals — new vendor listings appear here.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 20 / 13,
                    color: _kBodyMuted,
                  ),
                ),
              );
            }
            final docs = snap.data!.docs;
            return Column(
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          if (Get.isRegistered<AdminShellController>()) {
                            Get.find<AdminShellController>().setTab(1);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: _kMetricsBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  size: 20,
                                  color: _kGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.data()['title'] as String? ?? 'Notice',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _kInk,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.data()['body'] as String? ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        color: _kBodyMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _timeShort(
                                  d.data()['createdAt'] as Timestamp?,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kMeta,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AdminBentoMetrics extends StatelessWidget {
  const _AdminBentoMetrics({
    required this.metrics,
    required this.metricsAt,
    required this.onRefresh,
  });

  final AdminMetricsSnapshot? metrics;
  final DateTime? metricsAt;
  final VoidCallback onRefresh;

  String _healthLabel() {
    final m = metrics;
    if (m == null) return '…';
    if (m.loadError != null && m.loadError!.isNotEmpty) return 'CHECK';
    return 'OK';
  }

  String _healthValue() {
    final m = metrics;
    if (m == null) return '—';
    if (m.loadError != null && m.loadError!.isNotEmpty) return 'Retry';
    return 'Live';
  }

  String _syncSubtitle() {
    final t = metricsAt;
    if (t == null) return 'Tap refresh in settings menu';
    final locale = t.toLocal();
    final h = locale.hour.toString().padLeft(2, '0');
    final min = locale.minute.toString().padLeft(2, '0');
    return '$h:$min today';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 171,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kMetricsBg,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 18, color: _kGreen),
                        Text(
                          _healthLabel(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            height: 15 / 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Firestore snapshot',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: _kBodyMuted,
                      ),
                    ),
                    Text(
                      _healthValue(),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        height: 32 / 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: _kInk,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kGreen, _kGreenAlt],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.history_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.95)),
                            Flexible(
                              child: Text(
                                'METRICS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  height: 15 / 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'Last refreshed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          _syncSubtitle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            height: 28 / 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.45,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -16,
                    bottom: -16,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 68,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoreOrchestrationList extends StatelessWidget {
  const _CoreOrchestrationList({required this.metrics});

  final AdminMetricsSnapshot? metrics;

  String _usersSubtitle() {
    final m = metrics;
    if (m == null) {
      return 'Load metrics to see profile counts (Firestore users/).';
    }
    return '${m.userProfilesSnapshotCount} profiles in sample · '
        '${m.partnerVendorStoreCount} partner/vendor · '
        '${m.customerRoleCount} customer / other';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'CORE ORCHESTRATION',
            style: GoogleFonts.inter(
              fontSize: 10,
              height: 15 / 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: _kMeta,
            ),
          ),
        ),
        _OrchestrationRow(
          icon: Icons.groups_outlined,
          title: 'Manage all users',
          subtitle: _usersSubtitle(),
          onTap: () => Get.toNamed(AppRoutes.adminUsersDirectory),
        ),
        const SizedBox(height: 8),
        _OrchestrationRow(
          icon: Icons.dashboard_customize_outlined,
          title: 'Customer home categories',
          subtitle: 'Edit home screen tiles & images (Firestore)',
          onTap: () => Get.toNamed(AppRoutes.adminCustomerHome),
        ),
        const SizedBox(height: 8),
        _OrchestrationRow(
          icon: Icons.inventory_2_outlined,
          title: 'Master catalog (products)',
          subtitle: 'Browse SKUs, publish state',
          onTap: () => Get.toNamed(AppRoutes.adminMasterProducts),
        ),
        const SizedBox(height: 8),
        _OrchestrationRow(
          icon: Icons.security_rounded,
          title: 'Security · access',
          subtitle: 'Who is admin, signed-in operator, profile',
          onTap: () => Get.toNamed(AppRoutes.adminSecurityCenter),
        ),
        const SizedBox(height: 8),
        _OrchestrationRow(
          icon: Icons.receipt_long_outlined,
          title: 'Audit · activity',
          subtitle: 'Orders pipeline & recent order documents',
          onTap: () => Get.toNamed(AppRoutes.adminAuditActivity),
        ),
        const SizedBox(height: 8),
        _OrchestrationRow(
          icon: Icons.build_circle_outlined,
          title: 'Platform console',
          subtitle: 'Firebase project ID & live snapshot counts',
          onTap: () => Get.toNamed(AppRoutes.adminPlatformConsole),
        ),
      ],
    );
  }
}

class _OrchestrationRow extends StatelessWidget {
  const _OrchestrationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _kMetricsBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: _kGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w400,
                        color: _kBodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _kChevron, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutSecureSection extends StatelessWidget {
  const _LogoutSecureSection({
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [_kGreen, _kGreenAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onLogout,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Logout Securely',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          final phone =
              Get.find<AuthController>().currentUser.value?.phoneNumber;
          final line = (phone != null && phone.isNotEmpty)
              ? 'Signed in · $phone'
              : 'Signed in · refresh token managed by Firebase';
          return Text(
            line,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 16 / 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: _kMeta.withValues(alpha: 0.75),
            ),
          );
        }),
      ],
    );
  }
}

