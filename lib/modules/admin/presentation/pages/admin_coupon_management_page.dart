import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../models/api/admin_api_models.dart';
import '../../../../services/admin/admin_api_service.dart';
import '../../../../services/api/api_client.dart';
import '../widgets/admin_keyboard.dart';

String _formatUsDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$m/$day/${d.year}';
}

/// Figma **Coupon Management** — config form, active promotions, batch validity gauge.
class AdminCouponManagementPage extends StatefulWidget {
  const AdminCouponManagementPage({super.key});

  @override
  State<AdminCouponManagementPage> createState() =>
      _AdminCouponManagementPageState();
}

class _AdminCouponManagementPageState extends State<AdminCouponManagementPage> {
  late final TextEditingController _codeCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _usageCtrl;
  late final TextEditingController _eligiblePackGramsCtrl;
  late final TextEditingController _minPackGramsCtrl;
  DateTime? _expiry;
  
  List<Coupon> _coupons = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  
  AdminApiService? _api;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController();
    _discountCtrl = TextEditingController(text: '20');
    _usageCtrl = TextEditingController();
    _eligiblePackGramsCtrl = TextEditingController();
    _minPackGramsCtrl = TextEditingController();
    _expiry = DateTime.now().add(const Duration(days: 90));
    _initApi();
  }
  
  void _initApi() {
    try {
      final apiClient = Get.find<ApiClient>();
      _api = AdminApiService(apiClient);
      _loadCoupons();
    } catch (e) {
      setState(() {
        _error = 'API not configured. Please login first.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _usageCtrl.dispose();
    _eligiblePackGramsCtrl.dispose();
    _minPackGramsCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _loadCoupons() async {
    if (_api == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final coupons = await _api!.listCoupons();
      if (!mounted) return;
      setState(() {
        _coupons = coupons;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load coupons: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveCoupon() async {
    if (_api == null) return;
    adminDismissKeyboard();
    
    final code = _codeCtrl.text.trim();
    final pct = int.tryParse(_discountCtrl.text.trim()) ?? 0;
    final usageRaw = _usageCtrl.text.trim();
    final usage = usageRaw.isEmpty ? null : int.tryParse(usageRaw);
    
    if (code.isEmpty || pct <= 0 || pct > 100) {
      Get.snackbar(
        'Check fields',
        'Enter a code name and discount between 1 and 100%.',
      );
      return;
    }
    
    List<int>? eligibleGrams;
    final egRaw = _eligiblePackGramsCtrl.text.trim();
    if (egRaw.isNotEmpty) {
      eligibleGrams = egRaw
          .split(RegExp(r'[,;\s]+'))
          .map(int.tryParse)
          .whereType<int>()
          .where((g) => g > 0)
          .toSet()
          .toList()
        ..sort();
      if (eligibleGrams.isEmpty) eligibleGrams = null;
    }
    final minG = int.tryParse(_minPackGramsCtrl.text.trim());
    final minPack = minG != null && minG > 0 ? minG : null;

    setState(() => _saving = true);
    
    try {
      final coupon = Coupon(
        code: code.toUpperCase(),
        percentOff: pct,
        active: true,
        maxRedemptions: usage != null && usage > 0 ? usage : null,
        eligiblePackGrams: eligibleGrams ?? [],
        minPackGramsAnyLine: minPack,
        expiresAt: _expiry,
      );
      
      await _api!.upsertCoupon(code.toUpperCase(), coupon);
      
      if (!mounted) return;
      Get.snackbar('Saved', 'Coupon ${code.toUpperCase()} saved successfully.');
      await _loadCoupons();
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      Get.snackbar('Save failed', '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  
  void _clearForm() {
    setState(() {
      _codeCtrl.clear();
      _discountCtrl.text = '20';
      _usageCtrl.clear();
      _eligiblePackGramsCtrl.clear();
      _minPackGramsCtrl.clear();
      _expiry = DateTime.now().add(const Duration(days: 90));
    });
  }

  void _startNewCoupon() {
    adminDismissKeyboard();
    _clearForm();
    Get.snackbar(
      'New coupon',
      'Fill the form and tap Generate Spore Code to save.',
    );
  }

  void _prefillCouponForm(Coupon coupon) {
    adminDismissKeyboard();
    setState(() {
      _codeCtrl.text = coupon.code;
      _discountCtrl.text = '${coupon.percentOff}';
      _usageCtrl.text = coupon.maxRedemptions?.toString() ?? '';
      _eligiblePackGramsCtrl.text = coupon.eligiblePackGrams.join(', ');
      _minPackGramsCtrl.text = coupon.minPackGramsAnyLine?.toString() ?? '';
      _expiry = coupon.expiresAt;
    });
    Get.snackbar(
      'Loaded',
      'Adjust fields and tap Generate Spore Code to update.',
    );
  }

  Future<void> _confirmDeleteCoupon(String code) async {
    if (_api == null) return;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    adminDismissKeyboard();
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('Remove $trimmed permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    
    try {
      await _api!.deleteCoupon(trimmed);
      if (!mounted) return;
      Get.snackbar('Removed', '$trimmed deleted successfully.');
      await _loadCoupons();
    } catch (e) {
      Get.snackbar('Delete failed', '$e');
    }
  }

  void _onFilterPromotions() {
    adminDismissKeyboard();
    Get.snackbar(
      'Filter',
      'Coupons are fetched from API.',
    );
  }

  void _onSearchPromotions() {
    adminDismissKeyboard();
    Get.snackbar(
      'Search',
      'Enter a code in Coupon Config above, then save.',
    );
  }

  static const _inputFill = Color(0xFFD9E3F6);
  static const _inkMuted = Color(0xFF555F6F);
  static const _placeholder = Color(0xFF6B7280);

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
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24, contentTop, 24, 120),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKETING & GROWTH',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 16 / 12,
                          letterSpacing: 1.2,
                          color: DesignTokens.figmaHeroCtaGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coupon\nManagement',
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
                        'Curate exclusive offers for your fungal enthusiasts and community mycologists.',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          height: 28 / 18,
                          color: _inkMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CreateCouponCta(
                        label: 'Create New Coupon',
                        onTap: _startNewCoupon,
                      ),
                      const SizedBox(height: 48),
                      _CouponConfigCard(
                        sectionTitle: 'Coupon Config',
                        codeLabel: 'CODE NAME',
                        codePlaceholder: 'FORAGE15',
                        codeController: _codeCtrl,
                        discountLabel: 'DISCOUNT %',
                        discountController: _discountCtrl,
                        usageLabel: 'USAGE LIMIT',
                        usagePlaceholder: 'No limit',
                        usageController: _usageCtrl,
                        expiryLabel: 'EXPIRY DATE',
                        expiry: _expiry,
                        onPickExpiry: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expiry ?? now,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setState(() => _expiry = picked);
                          }
                        },
                        generateLabel: _saving ? 'Saving...' : 'Generate Spore Code',
                        onGenerate: _saving ? null : () => _saveCoupon(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PACK RULES (OPTIONAL)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: DesignTokens.figmaHeroCtaGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _eligiblePackGramsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Eligible pack sizes (grams)',
                            hintText: '500, 1000, 2000, 10000 — blank = any pack',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _minPackGramsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Minimum pack in bag (grams)',
                            hintText: 'e.g. 1000 for at least one 1 kg line',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _PromotionsHeader(
                        title: 'ACTIVE PROMOTIONS (${_coupons.length})',
                        onFilter: _onFilterPromotions,
                        onSearch: _onSearchPromotions,
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        Center(
                          child: Column(
                            children: [
                              Text(_error!, style: TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadCoupons,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._couponCards(),
                      const SizedBox(height: 32),
                      _BatchGaugeCard(
                        activeCoupons: _coupons.where((c) => c.active).length,
                        totalCoupons: _coupons.length,
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
            child: _CouponAppBar(
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
                  'Alerts will appear here.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _couponCards() {
    final out = <Widget>[];
    for (var i = 0; i < _coupons.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 16));
      final coupon = _coupons[i];
      out.add(
        _ActiveCouponCardApi(
          coupon: coupon,
          onEdit: () => _prefillCouponForm(coupon),
          onDelete: () => _confirmDeleteCoupon(coupon.code),
        ),
      );
    }
    if (out.isEmpty) {
      out.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No coupons yet. Create your first coupon above!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return out;
  }
}

class _CouponAppBar extends StatelessWidget {
  const _CouponAppBar({
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
                      color: DesignTokens.figmaPinIconGreen,
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

class _CreateCouponCta extends StatelessWidget {
  const _CreateCouponCta({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.85, -1),
          end: Alignment(1, 0.35),
          colors: [Color(0xFF006B2C), Color(0xFF00873A)],
        ),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
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
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
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

class _CouponConfigCard extends StatelessWidget {
  const _CouponConfigCard({
    required this.sectionTitle,
    required this.codeLabel,
    required this.codePlaceholder,
    required this.codeController,
    required this.discountLabel,
    required this.discountController,
    required this.usageLabel,
    required this.usagePlaceholder,
    required this.usageController,
    required this.expiryLabel,
    required this.expiry,
    required this.onPickExpiry,
    required this.generateLabel,
    this.onGenerate,
  });

  final String sectionTitle;
  final String codeLabel;
  final String codePlaceholder;
  final TextEditingController codeController;
  final String discountLabel;
  final TextEditingController discountController;
  final String usageLabel;
  final String usagePlaceholder;
  final TextEditingController usageController;
  final String expiryLabel;
  final DateTime? expiry;
  final VoidCallback onPickExpiry;
  final String generateLabel;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        expiry != null ? _formatUsDate(expiry!) : 'mm/dd/yyyy';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: DesignTokens.figmaHeroCtaGreen,
              ),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: DesignTokens.figmaSectionInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _LabeledField(
            label: codeLabel,
            child: _PillTextField(
              controller: codeController,
              hint: codePlaceholder,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledField(
                  label: discountLabel,
                  child: _PillTextField(
                    controller: discountController,
                    hint: '20',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _LabeledField(
                  label: expiryLabel,
                  child: Material(
                    color: _AdminCouponManagementPageState._inputFill,
                    borderRadius: BorderRadius.circular(9999),
                    child: InkWell(
                      onTap: onPickExpiry,
                      borderRadius: BorderRadius.circular(9999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 20 / 14,
                                  color: expiry != null
                                      ? DesignTokens.figmaSectionInk
                                      : _CouponConfigCard._hint,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: DesignTokens.figmaHeroCtaGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _LabeledField(
            label: usageLabel,
            child: _PillTextField(
              controller: usageController,
              hint: usagePlaceholder,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: _AdminCouponManagementPageState._inputFill,
              borderRadius: BorderRadius.circular(9999),
              child: InkWell(
                onTap: onGenerate,
                borderRadius: BorderRadius.circular(9999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      generateLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 24 / 16,
                        color: DesignTokens.figmaSectionInk,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _hint = Color(0xFF6B7280);
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 16 / 12,
            letterSpacing: 1.2,
            color: _AdminCouponManagementPageState._inkMuted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PillTextField extends StatelessWidget {
  const _PillTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.inter(
        fontSize: 16,
        height: 19 / 16,
        color: DesignTokens.figmaSectionInk,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: _AdminCouponManagementPageState._inputFill,
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: _AdminCouponManagementPageState._placeholder,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 18,
        ),
      ),
    );
  }
}

/// Make private state fields accessible to child widgets for style constants.
class _PromotionsHeader extends StatelessWidget {
  const _PromotionsHeader({
    required this.title,
    required this.onFilter,
    required this.onSearch,
  });

  final String title;
  final VoidCallback onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
                letterSpacing: 2.8,
                color: _AdminCouponManagementPageState._inkMuted,
              ),
            ),
          ),
          _RoundIconButton(icon: Icons.tune_rounded, onPressed: onFilter),
          const SizedBox(width: 8),
          _RoundIconButton(icon: Icons.search_rounded, onPressed: onSearch),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: DesignTokens.figmaHeroCtaGreen,
          ),
        ),
      ),
    );
  }
}

class _ActiveCouponCardApi extends StatelessWidget {
  const _ActiveCouponCardApi({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expiryStr = coupon.expiresAt != null 
        ? _formatUsDate(coupon.expiresAt!) 
        : 'No expiry';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DesignTokens.figmaHeroCtaGreenAlt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  size: 28,
                  color: DesignTokens.figmaHeroCtaGreen,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.code,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 28 / 20,
                            letterSpacing: -0.5,
                            color: DesignTokens.figmaSectionInk,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: coupon.active 
                                ? DesignTokens.figmaHeroCtaGreen.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            coupon.active ? 'Active' : 'Inactive',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: coupon.active 
                                  ? DesignTokens.figmaHeroCtaGreen 
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      coupon.maxRedemptions != null 
                          ? 'Max ${coupon.maxRedemptions} uses • ${coupon.usageCount} used'
                          : 'Unlimited uses • ${coupon.usageCount} used',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 20 / 14,
                        color: _AdminCouponManagementPageState._inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${coupon.percentOff}%',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 32 / 24,
                          color: DesignTokens.figmaHeroCtaGreen,
                        ),
                      ),
                      Text(
                        'REDUCTION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 15 / 10,
                          letterSpacing: 1,
                          color: _AdminCouponManagementPageState._inkMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expiryStr,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 24 / 16,
                          color: DesignTokens.figmaSectionInk,
                        ),
                      ),
                      Text(
                        'EXPIRES',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 15 / 10,
                          letterSpacing: 1,
                          color: _AdminCouponManagementPageState._inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: _AdminCouponManagementPageState._inkMuted,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFBA1A1A),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchGaugeCard extends StatelessWidget {
  const _BatchGaugeCard({
    required this.activeCoupons,
    required this.totalCoupons,
  });

  final int activeCoupons;
  final int totalCoupons;

  @override
  Widget build(BuildContext context) {
    final p = totalCoupons > 0 ? activeCoupons / totalCoupons : 0.0;
    final title = 'Coupon Campaign Status';
    final badge = '$activeCoupons / $totalCoupons active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: DesignTokens.figmaCategoryCard,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 28 / 18,
                    color: DesignTokens.figmaSectionInk,
                  ),
                ),
              ),
              Text(
                badge,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                  color: DesignTokens.figmaHeroCtaGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFF62DF7D),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: p.clamp(0.0, 1.0),
                      child: Container(
                        color: DesignTokens.figmaHeroCtaGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE COUPONS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 15 / 10,
                  letterSpacing: 1,
                  color: _AdminCouponManagementPageState._inkMuted,
                ),
              ),
              Text(
                'TOTAL COUPONS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 15 / 10,
                  letterSpacing: 1,
                  color: _AdminCouponManagementPageState._inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
