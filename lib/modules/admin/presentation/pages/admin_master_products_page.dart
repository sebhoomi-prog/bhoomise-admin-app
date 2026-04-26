import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../models/api/admin_api_models.dart';
import '../../../../services/admin/admin_api_service.dart';
import '../../../../services/api/api_client.dart';
import '../widgets/admin_keyboard.dart';
import '../widgets/admin_product_editor_sheet.dart';

/// **Master Products** — live `products` catalog: stats, search/filter, create & edit.
class AdminMasterProductsPage extends StatefulWidget {
  const AdminMasterProductsPage({super.key});

  @override
  State<AdminMasterProductsPage> createState() =>
      _AdminMasterProductsPageState();
}

class _AdminMasterProductsPageState extends State<AdminMasterProductsPage> {
  int _chipIndex = 0;
  final _searchCtrl = TextEditingController();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  late final AdminApiService _api;

  void _onSearchChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _api = AdminApiService(Get.find<ApiClient>());
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _api.listProducts();
      if (!mounted) return;
      setState(() {
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

  static const _searchFill = Color(0xFFD9E3F6);
  static const _track = Color(0xFFE6EEFF);
  static const _muted = Color(0xFF555F6F);
  static const _avatarBg = Color(0xFFD9E3F6);

  Map<String, dynamic> _statsFromProducts(List<Product> products) {
    var pub = 0;
    var draft = 0;
    for (final p in products) {
      if (p.published) {
        pub++;
      } else {
        draft++;
      }
    }
    final total = '${products.length}';
    final pubS = pub.toString().padLeft(2, '0');
    final draftS = draft.toString().padLeft(2, '0');
    return {
      'total_catalog': {
        'label': 'TOTAL CATALOG',
        'value': total,
        'sublabel': 'SKU documents',
      },
      'active_listings': {
        'label': 'PUBLISHED',
        'value': pubS,
      },
      'archived': {
        'label': 'DRAFT / UNPUBLISHED',
        'value': draftS,
      },
    };
  }

  List<Product> _filterProducts(List<Product> products) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = products;
    if (q.isNotEmpty) {
      list = products.where((p) {
        final n = p.name.toLowerCase();
        final desc = (p.description ?? '').toLowerCase();
        return n.contains(q) || desc.contains(q);
      }).toList();
    }
    if (_chipIndex == 1) {
      return list.where((p) => p.published).toList();
    }
    if (_chipIndex == 2) {
      return list.where((p) => !p.published).toList();
    }
    return list;
  }

  Map<String, dynamic> _productToCardMap(Product product) {
    var maxStock = 0;
    var maxPrice = 0;
    for (final v in product.variants) {
      if (v.stock > maxStock) maxStock = v.stock;
      if (v.priceMinor > maxPrice) maxPrice = v.priceMinor;
    }
    final desc = product.description ?? '';
    final latin = desc.length > 90 ? '${desc.substring(0, 87)}…' : desc;
    return {
      'name': product.name,
      'latin': latin.isEmpty ? '—' : latin,
      'image_url': product.imageUrl ?? '',
      'pack_sku_line':
          '${product.variants.length} pack size${product.variants.length == 1 ? '' : 's'} in catalog',
      'badge': product.published ? 'PUBLISHED' : 'DRAFT',
      'badge_tone': product.published ? 'brand' : 'muted',
      'stock_progress': (maxStock / 120.0).clamp(0.0, 1.0),
      'max_price_label': 'MAX: ${formatInrMinor(maxPrice)}',
      'stock_label': maxStock <= 10 ? 'LOW STOCK' : 'IN STOCK',
      'editor_initial': product.name.isNotEmpty ? product.name.substring(0, 1).toUpperCase() : '?',
      'active_ago': product.id.length > 8 ? product.id.substring(product.id.length - 8) : product.id,
    };
  }

  List<Widget> _buildProductRows(
    BuildContext context,
    List<Product> products,
  ) {
    if (products.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            'No products match this filter.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: _muted,
            ),
          ),
        ),
      ];
    }
    final out = <Widget>[];
    for (var i = 0; i < products.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 32));
      final product = products[i];
      out.add(
        _SpeciesProductCard(
          data: _productToCardMap(product),
          onEdit: () {
            adminDismissKeyboard();
            showAdminProductEditorSheet(
              context,
              api: _api,
              productId: product.id,
              initial: product,
              onSaved: _loadProducts,
            );
          },
        ),
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const barH = 80.0;
    final contentTop = top + barH + 8;

    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Builder(
            builder: (context) {
              if (_error != null) {
                return ErrorStateWidget(
                  message: _error!,
                  onRetry: _loadProducts,
                );
              }
              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = _statsFromProducts(_products);
              final filtered = _filterProducts(_products);

              return RefreshIndicator(
                onRefresh: _loadProducts,
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
                              'PRODUCT CATALOG',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 16 / 11,
                                letterSpacing: 2.2,
                                color: DesignTokens.figmaHeroCtaGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Master Products',
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
                              'Manage your product catalog and SKU variants.',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                height: 28 / 18,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _AddSpeciesCta(
                              label: 'Add product',
                              onTap: () {
                                adminDismissKeyboard();
                                showAdminProductEditorSheet(
                                  context,
                                  api: _api,
                                  onSaved: _loadProducts,
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          _StatsBento(stats: stats),
                          const SizedBox(height: 32),
                          _SearchRow(
                            controller: _searchCtrl,
                            hint: 'Search products…',
                          ),
                          const SizedBox(height: 16),
                          _CatalogFilterChips(
                            selectedIndex: _chipIndex,
                            onSelect: (i) => setState(() => _chipIndex = i),
                          ),
                          const SizedBox(height: 24),
                          _UploadSpeciesCard(
                            data: {
                              'title': 'Catalog source',
                              'body':
                                  'SKU rows are managed via REST API. '
                                  'Vendor uploads arrive via SPORE (listing_submissions) before publish.',
                              'link': 'Tips',
                            },
                            onHelp: () {
                              Get.snackbar(
                                'Catalog',
                                'Edit products here or approve vendor listings from the admin SPORE tab.',
                                duration: const Duration(seconds: 4),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          if (_products.isEmpty)
                            const EmptyStateWidget(
                              title: 'No Products Yet',
                              message: 'Add your first product to start building your catalog.',
                              icon: Icons.inventory_2_outlined,
                            )
                          else
                            ..._buildProductRows(context, filtered),
                        ],
                      ),
                    ),
                  ),
                ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MasterProductsAppBar(
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
}

/// All / published / draft filters for the live catalog list.
class _CatalogFilterChips extends StatelessWidget {
  const _CatalogFilterChips({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _labels = ['All SKUs', 'Published', 'Draft'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final sel = i == selectedIndex;
          return Material(
            color: sel
                ? DesignTokens.figmaHeroCtaGreen
                : DesignTokens.figmaCategoryCard,
            borderRadius: BorderRadius.circular(9999),
            child: InkWell(
              onTap: () => onSelect(i),
              borderRadius: BorderRadius.circular(9999),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  _labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 20 / 14,
                    color: sel ? Colors.white : _AdminMasterProductsPageState._muted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MasterProductsAppBar extends StatelessWidget {
  const _MasterProductsAppBar({
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
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: DesignTokens.figmaPinIconGreen,
                      size: 24,
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

class _AddSpeciesCta extends StatelessWidget {
  const _AddSpeciesCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.2, -0.5),
          end: Alignment(1, 0.4),
          colors: [Color(0xFF006B2C), Color(0xFF00873A)],
        ),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 24 / 16,
                    color: Colors.white,
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

class _StatsBento extends StatelessWidget {
  const _StatsBento({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final total = stats['total_catalog'] as Map<String, dynamic>? ?? {};
    final active = stats['active_listings'] as Map<String, dynamic>? ?? {};
    final arch = stats['archived'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _StatCardLight(
          label: total['label'] as String? ?? '',
          value: total['value'] as String? ?? '',
          sublabel: total['sublabel'] as String? ?? '',
        ),
        const SizedBox(height: 16),
        _StatCardFill(
          fill: _AdminMasterProductsPageState._searchFill,
          label: active['label'] as String? ?? '',
          value: active['value'] as String? ?? '',
          valueGreen: false,
        ),
        const SizedBox(height: 16),
        _StatCardFill(
          fill: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.05),
          border: Border.all(
            color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.2),
          ),
          label: arch['label'] as String? ?? '',
          value: arch['value'] as String? ?? '',
          labelGreen: true,
          valueGreen: true,
        ),
      ],
    );
  }
}

class _StatCardLight extends StatelessWidget {
  const _StatCardLight({
    required this.label,
    required this.value,
    required this.sublabel,
  });

  final String label;
  final String value;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              letterSpacing: 1.2,
              color: _AdminMasterProductsPageState._muted,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sublabel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                  color: DesignTokens.figmaHeroCtaGreen,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: DesignTokens.figmaSectionInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCardFill extends StatelessWidget {
  const _StatCardFill({
    required this.fill,
    required this.label,
    required this.value,
    this.border,
    this.labelGreen = false,
    this.valueGreen = false,
  });

  final Color fill;
  final String label;
  final String value;
  final BoxBorder? border;
  final bool labelGreen;
  final bool valueGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(32),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              letterSpacing: 1.2,
              color: labelGreen
                  ? DesignTokens.figmaHeroCtaGreen
                  : _AdminMasterProductsPageState._muted,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 40 / 36,
              color: valueGreen
                  ? DesignTokens.figmaHeroCtaGreen
                  : DesignTokens.figmaSectionInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 19 / 16,
          color: DesignTokens.figmaSectionInk,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: _AdminMasterProductsPageState._searchFill,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF6B7280),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9999),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.fromLTRB(48, 18, 48, 18),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.search_rounded,
              color: _AdminMasterProductsPageState._muted,
              size: 20,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ),
    );
  }
}

class _SpeciesProductCard extends StatelessWidget {
  const _SpeciesProductCard({
    required this.data,
    required this.onEdit,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = (data['stock_progress'] as num?)?.toDouble() ?? 0.5;
    final tone = data['badge_tone'] as String? ?? 'brand';
    final badgeColor = tone == 'brand'
        ? DesignTokens.figmaHeroCtaGreen
        : DesignTokens.figmaStoreMeta;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x0DBDCABA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 256,
                child: ColoredBox(
                  color: _AdminMasterProductsPageState._track,
                  child: (data['image_url'] as String?)?.isNotEmpty == true
                      ? Image.network(
                          data['image_url'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Positioned(
                top: 13,
                left: 13,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        (data['badge'] as String? ?? '').toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 15 / 10,
                          letterSpacing: 1,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              height: 32 / 24,
                              color: DesignTokens.figmaSectionInk,
                            ),
                          ),
                          Text(
                            data['latin'] as String? ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 16 / 12,
                              color: _AdminMasterProductsPageState._muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: _AdminMasterProductsPageState._muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: _AdminMasterProductsPageState._track),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: p.clamp(0.0, 1.0),
                            child: ColoredBox(
                              color: DesignTokens.figmaHeroCtaGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (data['pack_sku_line'] as String? ?? '').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 14 / 10,
                    letterSpacing: 0.4,
                    color: DesignTokens.figmaPinIconGreen,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (data['max_price_label'] as String? ?? '')
                            .toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 16 / 11,
                          letterSpacing: 0.55,
                          color: _AdminMasterProductsPageState._muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (data['stock_label'] as String? ?? '').toUpperCase(),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 16 / 11,
                          letterSpacing: 0.55,
                          color: _AdminMasterProductsPageState._muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0x1ABDCABA)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEE9FC),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        data['editor_initial'] as String? ?? '?',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.figmaSectionInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      data['active_ago'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 16 / 12,
                        color: _AdminMasterProductsPageState._muted,
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

class _UploadSpeciesCard extends StatelessWidget {
  const _UploadSpeciesCard({
    required this.data,
    this.onHelp,
  });

  final Map<String, dynamic> data;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFBDCABA),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFDEE9FC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.upload_file_rounded,
              color: DesignTokens.figmaHeroCtaGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['title'] as String? ?? 'Upload New Species',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 28 / 20,
              color: DesignTokens.figmaSectionInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['body'] as String? ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 20 / 14,
              color: _AdminMasterProductsPageState._muted,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              adminDismissKeyboard();
              onHelp?.call();
            },
            child: Text(
              data['link'] as String? ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
                color: DesignTokens.figmaHeroCtaGreen,
                decoration: TextDecoration.underline,
                decorationColor: DesignTokens.figmaHeroCtaGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
