import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../widgets/admin_keyboard.dart';

abstract final class _AdminStockTokens {
  static const bg = Color(0xFFF6F8FC);
  static const card = Colors.white;
  static const ink = Color(0xFF121C2A);
  static const body = Color(0xFF3E4A3D);
  static const muted = Color(0xFF71717A);
  static const green = DesignTokens.figmaHeroCtaGreen;
  static const greenAlt = DesignTokens.figmaHeroCtaGreenAlt;
  static const blue = Color(0xFFEFF4FF);
  static const line = Color(0xFFE5E7EB);
}

class GlobalSupplyPage extends StatelessWidget {
  const GlobalSupplyPage({super.key});

  Future<Map<String, dynamic>> _load() async {
    final raw = await rootBundle.loadString(
      'assets/mock_api/admin/global_supply_dashboard.json',
    );
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m['data'] as Map<String, dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _AdminStockTokens.bg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          final partners = (d['partners'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();

          return Stack(
            children: [
              AdminTapOutsideUnfocus(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        top + 76,
                        20,
                        MediaQuery.paddingOf(context).bottom + 120,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            'REAL-TIME OVERVIEW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: _AdminStockTokens.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Global Stock\nMonitoring',
                            style: GoogleFonts.manrope(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              height: 44 / 42,
                              letterSpacing: -1,
                              color: _AdminStockTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Centralized inventory status across all regional '
                            'fulfilment centers. Stock levels are updated every '
                            '5 minutes to ensure harvest freshness.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 18 / 13,
                              color: _AdminStockTokens.body,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _TopStatsCard(data: d),
                          const SizedBox(height: 12),
                          _HeroSkuCard(
                            title: 'Lion\'s Mane (500g)',
                            subtitle: 'Predicted shortage: 48h',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Vendor Breakdown',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _AdminStockTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (partners.isEmpty)
                            _EmptyHintCard(
                              text:
                                  'No partner signals yet. Vendor breakdown appears when admin data sync completes.',
                            )
                          else ...[
                            _VendorCard(partner: partners.first),
                            const SizedBox(height: 10),
                            for (var i = 1; i < partners.length; i++) ...[
                              _VendorMiniCard(partner: partners[i]),
                              const SizedBox(height: 10),
                            ],
                          ],
                          _SoftSummaryCard(
                            title: 'Fast Delivery',
                            value: '92 Units Total',
                            subtitle: '10+ km range',
                          ),
                          const SizedBox(height: 10),
                          _SoftSummaryCard(
                            title: 'Good Summary',
                            value: '48 Units Total',
                            subtitle: 'Low risk zones',
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _FrostHeader(
                  topPadding: top,
                  onSignOut: () => Get.find<AuthController>().signOutUser(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FrostHeader extends StatelessWidget {
  const _FrostHeader({
    required this.topPadding,
    required this.onSignOut,
  });

  final double topPadding;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.72),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    adminDismissKeyboard();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin menu coming soon.')),
                    );
                  },
                  icon: const Icon(Icons.menu_rounded, color: _AdminStockTokens.green),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Marketplace',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _AdminStockTokens.green,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Engine',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _AdminStockTokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  color: _AdminStockTokens.muted,
                  tooltip: 'Sign out',
                ),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.person_rounded, size: 18, color: _AdminStockTokens.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopStatsCard extends StatelessWidget {
  const _TopStatsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final activeCenters =
        (data['network_health_value'] as String?)?.replaceAll(RegExp('[^0-9]'), '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminStockTokens.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: _AdminStockTokens.green, size: 18),
              const SizedBox(width: 8),
              Text(
                'ACTIVE WAREHOUSES',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: _AdminStockTokens.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${activeCenters?.isEmpty ?? true ? 12 : activeCenters} Centers',
              style: GoogleFonts.manrope(
                fontSize: 34,
                height: 38 / 34,
                fontWeight: FontWeight.w800,
                color: _AdminStockTokens.ink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _Pill(text: 'UP 11%', bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46)),
              SizedBox(width: 8),
              _Pill(text: 'CRITICAL 2', bg: Color(0xFFFFE4E6), fg: Color(0xFF9F1239)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _AdminStockTokens.line),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL LIVE STOCK',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _AdminStockTokens.muted,
                ),
              ),
              Text(
                '1,402kg',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _AdminStockTokens.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.74,
              minHeight: 8,
              backgroundColor: _AdminStockTokens.blue,
              color: _AdminStockTokens.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkuCard extends StatelessWidget {
  const _HeroSkuCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AdminStockTokens.green, _AdminStockTokens.greenAlt],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC6F6D5), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AT RISK SKU',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
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

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.partner});
  final Map<String, dynamic> partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminStockTokens.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: _AdminStockTokens.blue,
                child: Icon(Icons.storefront_rounded, size: 16, color: _AdminStockTokens.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  partner['name'] as String? ?? 'Vendor',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _AdminStockTokens.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'HIGH RISK',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFFBA1A1A),
            ),
          ),
          const SizedBox(height: 6),
          _metricRow('Shiitake', '420', 0.87),
          const SizedBox(height: 4),
          _metricRow('King Oyster', 'Low (120)', 0.32, danger: true),
          const SizedBox(height: 4),
          _metricRow('Lion\'s Mane', '410', 0.82),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String val, double progress, {bool danger = false}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AdminStockTokens.body,
                ),
              ),
            ),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: danger ? const Color(0xFFBA1A1A) : _AdminStockTokens.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: _AdminStockTokens.blue,
            color: danger ? const Color(0xFFDC2626) : _AdminStockTokens.green,
          ),
        ),
      ],
    );
  }
}

class _VendorMiniCard extends StatelessWidget {
  const _VendorMiniCard({required this.partner});
  final Map<String, dynamic> partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AdminStockTokens.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              partner['name'] as String? ?? 'Partner',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AdminStockTokens.ink,
              ),
            ),
          ),
          _Pill(
            text: (partner['badge'] as String? ?? 'Status').toUpperCase(),
            bg: const Color(0xFFFFE4E6),
            fg: const Color(0xFF9F1239),
          ),
        ],
      ),
    );
  }
}

class _SoftSummaryCard extends StatelessWidget {
  const _SoftSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminStockTokens.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _AdminStockTokens.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _AdminStockTokens.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _AdminStockTokens.body,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_shipping_outlined, color: _AdminStockTokens.green),
        ],
      ),
    );
  }
}

class _EmptyHintCard extends StatelessWidget {
  const _EmptyHintCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminStockTokens.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: _AdminStockTokens.body,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.bg,
    required this.fg,
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}
