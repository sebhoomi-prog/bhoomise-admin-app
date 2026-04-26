import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../models/api/admin_api_models.dart';
import '../../../../services/admin/admin_api_service.dart';
import '../../../../services/api/api_client.dart';
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

class GlobalSupplyPage extends StatefulWidget {
  const GlobalSupplyPage({super.key});

  @override
  State<GlobalSupplyPage> createState() => _GlobalSupplyPageState();
}

class _GlobalSupplyPageState extends State<GlobalSupplyPage> {
  late final AdminApiService _api;
  List<Store> _stores = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = AdminApiService(Get.find<ApiClient>());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = await _api.listStores();
      final products = await _api.listProducts();
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _products = products;
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

  int get _totalStock {
    var total = 0;
    for (final p in _products) {
      for (final v in p.variants) {
        total += v.stock;
      }
    }
    return total;
  }

  Product? get _lowStockProduct {
    Product? lowest;
    int lowestStock = 999999;
    for (final p in _products) {
      for (final v in p.variants) {
        if (v.stock < lowestStock && v.stock > 0) {
          lowestStock = v.stock;
          lowest = p;
        }
      }
    }
    return lowest;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _AdminStockTokens.bg,
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            ErrorStateWidget(
              message: _error!,
              onRetry: _loadData,
            )
          else if (_stores.isEmpty && _products.isEmpty)
            const EmptyStateWidget(
              title: 'No Data Available',
              message: 'Stock and inventory data will appear here once stores and products are added.',
              icon: Icons.inventory_2_outlined,
            )
          else
            AdminTapOutsideUnfocus(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
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
                          _TopStatsCard(
                            activeCenters: _stores.where((s) => s.active).length,
                            totalStock: _totalStock,
                          ),
                          const SizedBox(height: 12),
                          if (_lowStockProduct != null)
                            _HeroSkuCard(
                              title: _lowStockProduct!.name,
                              subtitle: 'Low stock alert',
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Store Breakdown',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _AdminStockTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_stores.isEmpty)
                            _EmptyHintCard(
                              text: 'No stores registered yet. Store breakdown appears when stores are added.',
                            )
                          else ...[
                            for (final store in _stores) ...[
                              _StoreCard(store: store),
                              const SizedBox(height: 10),
                            ],
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Products Summary',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _AdminStockTokens.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_products.isEmpty)
                            _EmptyHintCard(
                              text: 'No products in catalog yet.',
                            )
                          else
                            _SoftSummaryCard(
                              title: 'Total Products',
                              value: '${_products.length} SKUs',
                              subtitle: '${_products.where((p) => p.published).length} published',
                            ),
                        ]),
                      ),
                    ),
                  ],
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopStatsCard extends StatelessWidget {
  const _TopStatsCard({
    required this.activeCenters,
    required this.totalStock,
  });
  
  final int activeCenters;
  final int totalStock;

  @override
  Widget build(BuildContext context) {
    final stockKg = (totalStock / 1000).toStringAsFixed(1);
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
                'ACTIVE STORES',
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
              '$activeCenters ${activeCenters == 1 ? 'Store' : 'Stores'}',
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
            children: [
              if (activeCenters > 0)
                const _Pill(text: 'ACTIVE', bg: Color(0xFFD1FAE5), fg: Color(0xFF065F46))
              else
                const _Pill(text: 'NO STORES', bg: Color(0xFFFFE4E6), fg: Color(0xFF9F1239)),
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
                totalStock > 1000 ? '${stockKg}kg' : '$totalStock units',
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
              value: totalStock > 0 ? (totalStock / 10000).clamp(0.1, 1.0) : 0,
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AdminStockTokens.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: _AdminStockTokens.blue,
            child: Icon(Icons.storefront_rounded, size: 20, color: _AdminStockTokens.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _AdminStockTokens.ink,
                  ),
                ),
                if (store.city != null)
                  Text(
                    store.city!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _AdminStockTokens.body,
                    ),
                  ),
              ],
            ),
          ),
          _Pill(
            text: store.active ? 'ACTIVE' : 'INACTIVE',
            bg: store.active ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
            fg: store.active ? const Color(0xFF065F46) : const Color(0xFF9F1239),
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
