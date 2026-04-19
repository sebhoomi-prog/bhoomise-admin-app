import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/admin_coupons_firestore.dart';
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
  Map<String, dynamic>? _data;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _discountCtrl;
  late final TextEditingController _usageCtrl;
  late final TextEditingController _eligiblePackGramsCtrl;
  late final TextEditingController _minPackGramsCtrl;
  DateTime? _expiry;
  late final AdminCouponsFirestore _couponsFs;

  @override
  void initState() {
    super.initState();
    _couponsFs = AdminCouponsFirestore();
    _codeCtrl = TextEditingController();
    _discountCtrl = TextEditingController(text: '20');
    _usageCtrl = TextEditingController();
    _eligiblePackGramsCtrl = TextEditingController();
    _minPackGramsCtrl = TextEditingController();
    _load();
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

  Future<void> _publishCouponToFirestore() async {
    adminDismissKeyboard();
    final code = _codeCtrl.text.trim();
    final pct = int.tryParse(_discountCtrl.text.trim()) ?? 0;
    final usageRaw = _usageCtrl.text.trim();
    final usage =
        usageRaw.isEmpty ? null : int.tryParse(usageRaw);
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

    try {
      await _couponsFs.upsertCoupon(
        code: code,
        percentOff: pct,
        maxRedemptions:
            usage != null && usage > 0 ? usage : null,
        eligiblePackGrams: eligibleGrams,
        minPackGramsAnyLine: minPack,
      );
      if (!mounted) return;
      final upper = code.toUpperCase();
      final coups = _data!['coupons'] as List;
      Map<String, dynamic>? prev;
      var prevIdx = -1;
      for (var i = 0; i < coups.length; i++) {
        final mm = coups[i] as Map<String, dynamic>;
        if ((mm['code'] as String?)?.toUpperCase() == upper) {
          prev = Map<String, dynamic>.from(mm);
          prevIdx = i;
          break;
        }
      }
      final entry = <String, dynamic>{
        'code': upper,
        'subtitle': prev?['subtitle'] ?? 'Promotion',
        'reduction_pct': pct,
        'expiry_display': _expiry != null
            ? _formatUsDate(_expiry!)
            : (prev?['expiry_display'] as String? ?? ''),
        'thumb_kind': prev?['thumb_kind'] ?? 'icon',
        'icon': prev?['icon'] ?? 'park',
      };
      if (prev?['image_url'] != null) {
        entry['image_url'] = prev!['image_url'];
      }
      if (prevIdx >= 0) {
        coups[prevIdx] = entry;
      } else {
        coups.add(entry);
      }
      final promos =
          Map<String, dynamic>.from(_data!['promotions'] as Map? ?? {});
      promos['count'] = coups.length;
      _data!['promotions'] = promos;
      setState(() {});
      Get.snackbar('Saved', 'Coupon $upper stored in Firestore.');
    } catch (e) {
      Get.snackbar('Save failed', '$e');
    }
  }

  void _startNewCoupon() {
    adminDismissKeyboard();
    final now = DateTime.now();
    setState(() {
      _codeCtrl.clear();
      _discountCtrl.text = '20';
      _usageCtrl.clear();
      _eligiblePackGramsCtrl.clear();
      _minPackGramsCtrl.clear();
      _expiry = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 90));
    });
    Get.snackbar(
      'New coupon',
      'Fill the form and tap Generate Spore Code to save.',
    );
  }

  void _prefillCouponForm(Map<String, dynamic> m) {
    adminDismissKeyboard();
    setState(() {
      _codeCtrl.text = m['code'] as String? ?? '';
      _discountCtrl.text = '${m['reduction_pct'] ?? 20}';
    });
    Get.snackbar(
      'Loaded',
      'Adjust fields and tap Generate Spore Code to update Firestore.',
    );
  }

  Future<void> _confirmDeleteCoupon(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    adminDismissKeyboard();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('Remove $trimmed from Firestore?'),
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
      await _couponsFs.deleteCoupon(trimmed);
      if (!mounted) return;
      final upper = trimmed.toUpperCase();
      final coups = _data!['coupons'] as List;
      coups.removeWhere((e) {
        final mm = e as Map<String, dynamic>;
        return (mm['code'] as String?)?.toUpperCase() == upper;
      });
      final promos =
          Map<String, dynamic>.from(_data!['promotions'] as Map? ?? {});
      promos['count'] = coups.length;
      _data!['promotions'] = promos;
      setState(() {});
      Get.snackbar('Removed', '$upper deleted from Firestore.');
    } catch (e) {
      Get.snackbar('Delete failed', '$e');
    }
  }

  void _onFilterPromotions() {
    adminDismissKeyboard();
    Get.snackbar(
      'Filter',
      'List is driven by mock layout; coupons are saved under Firestore `coupons/`.',
    );
  }

  void _onSearchPromotions() {
    adminDismissKeyboard();
    Get.snackbar(
      'Search',
      'Enter a code in Coupon Config above, then save with Generate Spore Code.',
    );
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(
      'assets/mock_api/admin/coupon_management.json',
    );
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final d = m['data'] as Map<String, dynamic>? ?? {};
    final form = d['form'] as Map<String, dynamic>? ?? {};
    final code = form['code_name'] as Map<String, dynamic>? ?? {};
    final disc = form['discount_pct'] as Map<String, dynamic>? ?? {};
    final usage = form['usage_limit'] as Map<String, dynamic>? ?? {};
    if (!mounted) return;
    setState(() {
      _data = d;
      _codeCtrl.text = code['value'] as String? ?? '';
      _discountCtrl.text = disc['value'] as String? ?? '20';
      _usageCtrl.text = usage['value'] as String? ?? '';
      _expiry = DateTime(2025, 6, 15);
    });
  }

  static const _inputFill = Color(0xFFD9E3F6);
  static const _inkMuted = Color(0xFF555F6F);
  static const _placeholder = Color(0xFF6B7280);
  static const _avatarRing = Color(0xFFE6EEFF);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const barH = 80.0;
    final contentTop = top + barH + 8;
    final d = _data;

    if (d == null) {
      return const ColoredBox(
        color: Color(0xFFF8F9FA),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final form = d['form'] as Map<String, dynamic>? ?? {};
    final codeName = form['code_name'] as Map<String, dynamic>? ?? {};
    final discField = form['discount_pct'] as Map<String, dynamic>? ?? {};
    final usageField = form['usage_limit'] as Map<String, dynamic>? ?? {};
    final promos = d['promotions'] as Map<String, dynamic>? ?? {};
    final coupons = d['coupons'] as List<dynamic>? ?? [];
    final gauge = d['batch_gauge'] as Map<String, dynamic>? ?? {};

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
                        (d['eyebrow'] as String? ?? '').toUpperCase(),
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
                        d['title'] as String? ?? 'Coupon Management',
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
                        d['description'] as String? ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          height: 28 / 18,
                          color: _inkMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _CreateCouponCta(
                        label: d['create_cta'] as String? ?? 'Create New Coupon',
                        onTap: _startNewCoupon,
                      ),
                      const SizedBox(height: 48),
                      _CouponConfigCard(
                        sectionTitle:
                            form['section_title'] as String? ?? 'Coupon Config',
                        codeLabel:
                            (codeName['label'] as String? ?? 'CODE NAME')
                                .toUpperCase(),
                        codePlaceholder:
                            codeName['placeholder'] as String? ?? '',
                        codeController: _codeCtrl,
                        discountLabel:
                            (discField['label'] as String? ?? 'DISCOUNT %')
                                .toUpperCase(),
                        discountController: _discountCtrl,
                        usageLabel:
                            (usageField['label'] as String? ?? 'USAGE LIMIT')
                                .toUpperCase(),
                        usagePlaceholder:
                            usageField['placeholder'] as String? ?? '',
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
                        generateLabel:
                            form['generate_label'] as String? ??
                                'Generate Spore Code',
                        onGenerate: _publishCouponToFirestore,
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
                      TextField(
                        controller: _eligiblePackGramsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Eligible pack sizes (grams)',
                          hintText: '500, 1000, 2000, 10000 — blank = any pack',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minPackGramsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Minimum pack in bag (grams)',
                          hintText: 'e.g. 1000 for at least one 1 kg line',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 48),
                      _PromotionsHeader(
                        title:
                            '${promos['title'] ?? 'ACTIVE PROMOTIONS'} (${promos['count'] ?? 4})',
                        onFilter: _onFilterPromotions,
                        onSearch: _onSearchPromotions,
                      ),
                      const SizedBox(height: 16),
                      ..._couponCards(coupons),
                      const SizedBox(height: 32),
                      _BatchGaugeCard(data: gauge),
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
              title: d['brand_title'] as String? ?? AppStrings.appName,
              avatarUrl: d['avatar_url'] as String?,
              avatarRing: _avatarRing,
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

  List<Widget> _couponCards(List<dynamic> raw) {
    final out = <Widget>[];
    for (var i = 0; i < raw.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 16));
      final m = raw[i] as Map<String, dynamic>? ?? {};
      final code = m['code'] as String? ?? '';
      out.add(
        _ActiveCouponCard(
          data: m,
          onEdit: () => _prefillCouponForm(m),
          onDelete: () => _confirmDeleteCoupon(code),
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
    this.avatarUrl,
    this.avatarRing = const Color(0xFFE6EEFF),
    required this.onGridTap,
    required this.onBellTap,
  });

  final double topPadding;
  final String title;
  final String? avatarUrl;
  final Color avatarRing;
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: avatarRing,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? Image.network(
                            avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: DesignTokens.figmaLabelMuted,
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: DesignTokens.figmaLabelMuted,
                          ),
                  ),
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
    required this.onGenerate,
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
  final VoidCallback onGenerate;

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

class _ActiveCouponCard extends StatelessWidget {
  const _ActiveCouponCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pct = data['reduction_pct'] as int? ?? 0;
    final kind = data['thumb_kind'] as String? ?? 'icon';
    final iconName = data['icon'] as String?;

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
              _CouponThumb(kind: kind, iconName: iconName, data: data),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['code'] as String? ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 28 / 20,
                        letterSpacing: -0.5,
                        color: DesignTokens.figmaSectionInk,
                      ),
                    ),
                    Text(
                      data['subtitle'] as String? ?? '',
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
                        '$pct%',
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
                        data['expiry_display'] as String? ?? '',
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

class _CouponThumb extends StatelessWidget {
  const _CouponThumb({
    required this.kind,
    required this.iconName,
    required this.data,
  });

  final String kind;
  final String? iconName;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    const r = 6.0;
    if (kind == 'image') {
      final url = data['image_url'] as String? ?? '';
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Container(
          width: 64,
          height: 64,
          color: const Color(0x4DD6E0F3),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported_outlined),
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    final icon = iconName == 'park'
        ? Icons.park_rounded
        : Icons.local_florist_rounded;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: DesignTokens.figmaHeroCtaGreenAlt.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(r),
      ),
      child: Icon(
        icon,
        size: 28,
        color: DesignTokens.figmaHeroCtaGreen,
      ),
    );
  }
}

class _BatchGaugeCard extends StatelessWidget {
  const _BatchGaugeCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final p = (data['progress'] as num?)?.toDouble() ?? 0.67;
    final title = data['title'] as String? ?? '';
    final badge = data['badge'] as String? ?? '';

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
                (data['left_caption'] as String? ?? '').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 15 / 10,
                  letterSpacing: 1,
                  color: _AdminCouponManagementPageState._inkMuted,
                ),
              ),
              Text(
                (data['right_caption'] as String? ?? '').toUpperCase(),
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
