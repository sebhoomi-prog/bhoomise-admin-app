import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../services/api/api_client.dart';
import '../../data/admin_metrics_api_service.dart';
import '../../navigation/presentation/controllers/admin_shell_controller.dart';
import '../widgets/admin_keyboard.dart';

/// **Marketplace Pulse** — admin dashboard home with live data from API.
class AdminMarketplacePulsePage extends StatefulWidget {
  const AdminMarketplacePulsePage({super.key});

  @override
  State<AdminMarketplacePulsePage> createState() =>
      _AdminMarketplacePulsePageState();
}

class _AdminMarketplacePulsePageState extends State<AdminMarketplacePulsePage> {
  Map<String, dynamic>? _pulse;
  bool _loading = true;
  Object? _loadErr;
  late final AdminMetricsApiService _metricsService;

  @override
  void initState() {
    super.initState();
    _metricsService = AdminMetricsApiService(
      Get.find<ApiClient>(),
    );
    _reload(showBlockingSpinner: true);
  }

  Future<void> _reload({bool showBlockingSpinner = false}) async {
    if (showBlockingSpinner || _pulse == null) {
      setState(() {
        _loading = true;
        _loadErr = null;
      });
    }
    try {
      final d = await _loadMerged();
      if (!mounted) return;
      setState(() {
        _pulse = d;
        _loading = false;
        _loadErr = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErr = e;
        _loading = false;
      });
    }
  }

  void _openAdminShortcuts(BuildContext context) {
    adminDismissKeyboard();
    final shell = Get.isRegistered<AdminShellController>()
        ? Get.find<AdminShellController>()
        : null;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.science_outlined,
                    color: DesignTokens.figmaHeroCtaGreen),
                title: const Text('SPORE — vendor listing approvals'),
                onTap: () {
                  Navigator.pop(ctx);
                  shell?.setTab(1);
                },
              ),
              ListTile(
                leading: Icon(Icons.inventory_2_outlined,
                    color: DesignTokens.figmaHeroCtaGreen),
                title: const Text('Master catalog'),
                onTap: () {
                  Navigator.pop(ctx);
                  Get.toNamed(AppRoutes.adminMasterProducts);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.eco_rounded, color: DesignTokens.figmaHeroCtaGreen),
                title: const Text('GARDEN — coupons'),
                onTap: () {
                  Navigator.pop(ctx);
                  shell?.setTab(2);
                },
              ),
              ListTile(
                leading: Icon(Icons.person_rounded,
                    color: DesignTokens.figmaHeroCtaGreen),
                title: const Text('Admin profile'),
                onTap: () {
                  Navigator.pop(ctx);
                  shell?.setTab(3);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadMerged() async {
    final metrics = await _metricsService.fetch();
    final d = <String, dynamic>{
      'greeting': _greeting(),
      'brand': AppStrings.appName,
    };
    _applyLiveMetrics(d, metrics);
    return d;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _applyLiveMetrics(
    Map<String, dynamic> d,
    AdminMetricsSnapshot x,
  ) {
    d['total_revenue'] = {
      'label': 'ORDERS (SNAPSHOT)',
      'value': '${x.orderCount}',
      'trend':
          '${x.pendingSubmissionCount} vendor submission(s) awaiting review',
    };
    final skuGoal = (x.productCount + 25).clamp(25, 9999);
    d['total_users'] = {
      'label': 'CATALOG SKUS',
      'value': '${x.productCount}',
      'goal': skuGoal,
      'goal_caption':
          'Published ${x.publishedProductCount} · Drafts ${x.draftProductCount}',
    };
    d['total_vendors'] = {
      'label': 'PENDING REVIEWS',
      'value': '${x.pendingSubmissionCount}',
      'extra_count':
          x.pendingSubmissionCount > 99 ? '99+' : '${x.pendingSubmissionCount}',
      'avatar_urls': <String>[],
    };
    final rows = _orderStatusRows(x.ordersByStatus);
    d['active_orders'] = {
      'title': 'Order status (snapshot)',
      'badge': '${x.orderCount} TOTAL',
      'rows': rows,
    };
    d['curator_choice'] = {
      ...(d['curator_choice'] as Map<String, dynamic>? ?? {}),
      'headline': x.pendingSubmissionCount > 0
          ? 'Review ${x.pendingSubmissionCount} pending submission(s)'
          : 'No pending vendor listings',
    };
    final actWas = d['activity'] as Map<String, dynamic>? ?? {};
    final oldItems = (actWas['items'] as List<dynamic>? ?? []);
    d['activity'] = {
      'title': actWas['title'] ?? 'Recent Activity',
      'footer': actWas['footer'] ?? 'View all activity',
      'items': [
        {
          'title': 'Listing queue',
          'body':
              '${x.pendingSubmissionCount} submission(s) in SPORE · ${x.productCount} catalog SKU(s).',
          'time': 'LIVE',
          'dot': 'accent',
        },
        if (oldItems.length > 1) oldItems[1],
        if (oldItems.length > 2) oldItems[2],
      ],
    };
    d['quality'] = {
      'title': 'Catalog & ops',
      'value': '${x.productCount} SKUs',
      'body': x.loadError ??
          '${x.publishedProductCount} published · ${x.orderCount} order doc(s) in snapshot · '
              '${x.pendingSubmissionCount} pending review(s).',
    };
    d['_metrics_error'] = x.loadError;
  }

  List<Map<String, dynamic>> _orderStatusRows(Map<String, int> byStatus) {
    if (byStatus.isEmpty) {
      return [
        {
          'title': 'No orders yet',
          'subtitle': 'Customer / supply orders appear here when created.',
          'pct': 0,
          'icon_bg': 'mint',
          'icon': 'truck',
        },
      ];
    }
    final entries = byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    return entries.take(2).map((e) {
      final pct = total == 0
          ? 0
          : ((e.value / total) * 100).round().clamp(0, 100);
      final key = e.key.toLowerCase();
      final isPrep = key.contains('prep') ||
          key.contains('pending') ||
          key.contains('pack');
      return {
        'title': _titleCase(e.key.replaceAll('_', ' ')),
        'subtitle': '${e.value} order(s)',
        'pct': pct,
        'icon_bg': isPrep ? 'amber' : 'mint',
        'icon': isPrep ? 'package' : 'truck',
      };
    }).toList();
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const barH = 80.0;
    final contentTop = top + barH + 8;
    final scheme = Theme.of(context).colorScheme;

    if (_loading && _pulse == null) {
      return const ColoredBox(
        color: Color(0xFFF8F9FA),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadErr != null && _pulse == null) {
      return ColoredBox(
        color: const Color(0xFFF8F9FA),
        child: ErrorStateWidget(
          message: '$_loadErr',
          onRetry: () => _reload(showBlockingSpinner: true),
        ),
      );
    }

    final d = _pulse!;
    final metricsErr = d['_metrics_error'] as String?;
    final showMetricsErr = metricsErr != null && metricsErr.isNotEmpty;

    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          RefreshIndicator(
            color: DesignTokens.figmaHeroCtaGreen,
            onRefresh: () => _reload(showBlockingSpinner: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    contentTop,
                    24,
                    120,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showMetricsErr)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Live metrics unavailable ($metricsErr). '
                                  'Layout still loads; check admin Firestore rules and network.',
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        Text(
                          (d['eyebrow'] as String? ?? '').toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 16 / 11,
                            letterSpacing: 1.1,
                            color: DesignTokens.figmaHeroCtaGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['title'] as String? ?? 'Marketplace Pulse',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 40 / 36,
                            letterSpacing: -1.8,
                            color: DesignTokens.figmaSectionInk,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d['subtitle'] as String? ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 24 / 16,
                            color: const Color(0xFF555F6F),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _RevenueCard(data: d),
                        const SizedBox(height: 16),
                        _UsersCard(
                          block: d['total_users'] as Map<String, dynamic>? ?? {},
                        ),
                        const SizedBox(height: 16),
                        _VendorsCard(
                          block:
                              d['total_vendors'] as Map<String, dynamic>? ?? {},
                        ),
                        const SizedBox(height: 32),
                        _ActiveOrdersCard(
                          block:
                              d['active_orders'] as Map<String, dynamic>? ?? {},
                        ),
                        const SizedBox(height: 32),
                        _CuratorChoiceCard(
                          block:
                              d['curator_choice'] as Map<String, dynamic>? ?? {},
                          onLaunchReviewer: () {
                            adminDismissKeyboard();
                            if (Get.isRegistered<AdminShellController>()) {
                              Get.find<AdminShellController>().setTab(1);
                            } else {
                              Get.snackbar(
                                'SPORE',
                                'Open the admin hub from your profile, then use the SPORE tab.',
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        _RecentActivityCard(
                          block: d['activity'] as Map<String, dynamic>? ?? {},
                          onOpenSporeQueue: () {
                            adminDismissKeyboard();
                            if (Get.isRegistered<AdminShellController>()) {
                              Get.find<AdminShellController>().setTab(1);
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        _QualityCard(
                          block: d['quality'] as Map<String, dynamic>? ?? {},
                        ),
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
            child: _AdminPulseAppBar(
              topPadding: top,
              title: d['brand_title'] as String? ?? AppStrings.appName,
              onGridTap: () => _openAdminShortcuts(context),
              onBellTap: () => _openAdminShortcuts(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPulseAppBar extends StatelessWidget {
  const _AdminPulseAppBar({
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onGridTap,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
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
                    color: DesignTokens.figmaPinIconGreen,
                    size: 22,
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

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rev = data['total_revenue'] as Map<String, dynamic>? ?? {};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Icon(
              Icons.eco_rounded,
              size: 120,
              color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 18, color: DesignTokens.figmaHeroCtaGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (rev['label'] as String? ?? '').toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 16 / 11,
                        letterSpacing: 1.1,
                        color: const Color(0xFF555F6F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                rev['value'] as String? ?? '',
                style: GoogleFonts.manrope(
                  fontSize: 60,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -3,
                  color: DesignTokens.figmaSectionInk,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.trending_up_rounded,
                        size: 14, color: DesignTokens.figmaHeroCtaGreen),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rev['trend'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                        color: DesignTokens.figmaHeroCtaGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersCard extends StatelessWidget {
  const _UsersCard({required this.block});

  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final val = int.tryParse(
          (block['value'] as String? ?? '0').replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0;
    final goal = (block['goal'] as num?)?.toInt() ?? 1500;
    final fill = (val / goal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined,
                  size: 18, color: const Color(0xFF555F6F)),
              const SizedBox(width: 8),
              Text(
                (block['label'] as String? ?? '').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 16 / 11,
                  letterSpacing: 1.1,
                  color: const Color(0xFF555F6F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block['value'] as String? ?? '',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 40 / 36,
              letterSpacing: -0.9,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFD9E3F6)),
                  FractionallySizedBox(
                    widthFactor: fill,
                    child: Container(color: DesignTokens.figmaHeroCtaGreen),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            block['goal_caption'] as String? ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 15 / 10,
              color: const Color(0xFF555F6F),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorsCard extends StatelessWidget {
  const _VendorsCard({required this.block});

  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final urls = (block['avatar_urls'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_outlined,
                  size: 18, color: const Color(0xFF555F6F)),
              const SizedBox(width: 8),
              Text(
                (block['label'] as String? ?? '').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: const Color(0xFF555F6F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block['value'] as String? ?? '',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 40 / 36,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            width: 32 + 20.0 * (urls.length) + 4 + 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < urls.length; i++)
                  Positioned(
                    left: i * 20.0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: const Color(0xFFE2E8F0),
                        image: DecorationImage(
                          image: NetworkImage(urls[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: urls.length * 20.0 + 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignTokens.figmaHeroCtaGreen,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      block['extra_count'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrdersCard extends StatelessWidget {
  const _ActiveOrdersCard({required this.block});

  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    final rows = (block['rows'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  block['title'] as String? ?? 'Active Orders Status',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 28 / 20,
                    letterSpacing: -0.5,
                    color: DesignTokens.figmaSectionInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    (block['badge'] as String? ?? '').toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      color: DesignTokens.figmaHeroCtaGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OrderStatusRow(row: r),
              )),
        ],
      ),
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  const _OrderStatusRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final pct = (row['pct'] as num?)?.toInt() ?? 0;
    final iconKey = row['icon'] as String? ?? 'truck';
    final bg = row['icon_bg'] as String? ?? 'mint';
    final isMint = bg == 'mint';
    final iconData = switch (iconKey) {
      'truck' => Icons.local_shipping_outlined,
      'package' => Icons.inventory_2_outlined,
      _ => Icons.receipt_long_outlined,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isMint
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEFCE8),
              borderRadius: BorderRadius.circular(32),
            ),
            alignment: Alignment.center,
            child: Icon(
              iconData,
              color: isMint
                  ? DesignTokens.figmaHeroCtaGreen
                  : const Color(0xFFA16207),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.figmaSectionInk,
                  ),
                ),
                Text(
                  row['subtitle'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 16 / 12,
                    color: const Color(0xFF555F6F),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$pct%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isMint
                  ? DesignTokens.figmaHeroCtaGreen
                  : const Color(0xFFA16207),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratorChoiceCard extends StatelessWidget {
  const _CuratorChoiceCard({
    required this.block,
    required this.onLaunchReviewer,
  });

  final Map<String, dynamic> block;
  final VoidCallback onLaunchReviewer;

  @override
  Widget build(BuildContext context) {
    final url = block['image_url'] as String? ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 256,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: DesignTokens.figmaCategoryCard),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x33000000),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (block['eyebrow'] as String? ?? '').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: DesignTokens.figmaAccentLime,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    block['headline'] as String? ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 32 / 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: onLaunchReviewer,
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.figmaHeroCtaGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      child: Text(
                        block['cta'] as String? ?? 'Open SPORE queue',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.block,
    this.onOpenSporeQueue,
  });

  final Map<String, dynamic> block;
  final VoidCallback? onOpenSporeQueue;

  Color _dot(String? kind) {
    switch (kind) {
      case 'accent':
        return DesignTokens.figmaHeroCtaGreenAlt;
      case 'muted':
        return const Color(0xFF555F6F);
      default:
        return DesignTokens.figmaHeroCtaGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (block['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block['title'] as String? ?? 'Recent Activity',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 28 / 20,
              letterSpacing: -0.5,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Positioned(
                right: 5,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  color: const Color(0xFFE6EEFF),
                ),
              ),
              Column(
                children: List.generate(items.length, (i) {
                  final it = items[i];
                  final actions = (it['actions'] as List<dynamic>? ?? [])
                      .map((e) => e as Map<String, dynamic>)
                      .toList();
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < items.length - 1 ? 32 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it['title'] as String? ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 20 / 14,
                                  color: DesignTokens.figmaSectionInk,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                it['body'] as String? ?? '',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  color: const Color(0xFF555F6F),
                                ),
                              ),
                              if (actions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: actions.map((a) {
                                    final primary =
                                        a['style'] == 'primary';
                                    return Material(
                                      color: primary
                                          ? DesignTokens.figmaHeroCtaGreen
                                              .withValues(alpha: 0.1)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(9999),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          a['label'] as String? ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: primary
                                                ? DesignTokens
                                                    .figmaHeroCtaGreen
                                                : const Color(0xFF555F6F),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                (it['time'] as String? ?? '').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  height: 15 / 10,
                                  letterSpacing: -0.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _dot(it['dot'] as String?),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                adminDismissKeyboard();
                if (onOpenSporeQueue != null) {
                  onOpenSporeQueue!();
                } else {
                  Get.snackbar(
                    'Activity',
                    'Open SPORE from the shortcuts menu (grid icon).',
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF555F6F),
                side: const BorderSide(color: Color(0xFFBDCABA)),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
              ),
              child: Text(
                block['footer'] as String? ?? 'View all activity',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.block});

  final Map<String, dynamic> block;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.figmaHeroCtaGreen,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Opacity(
              opacity: 0.2,
              child: Icon(
                Icons.verified_rounded,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block['title'] as String? ?? 'Quality Score',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 28 / 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                block['value'] as String? ?? '',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 40 / 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                block['body'] as String? ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 20 / 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
