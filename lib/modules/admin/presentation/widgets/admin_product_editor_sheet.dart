import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum _PackWeightUnit {
  grams,
  kg;

  String get dropdownLabel =>
      this == _PackWeightUnit.kg ? 'kilograms (kg)' : 'grams (g)';
}

/// Create or update a `products/{id}` document (admin rules).
///
/// **Pack sizes** — same idea as Blinkit: each row is a sellable SKU (200 g, 500 g, 1 kg…)
/// with **canonical `totalGrams`** (for coupons / logic), **MRP in ₹**, and stock.
Future<void> showAdminProductEditorSheet(
  BuildContext context, {
  required FirebaseFirestore db,
  String? documentId,
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _AdminProductEditorBody(
      db: db,
      documentId: documentId,
      initial: initial,
    ),
  );
}

class _PackVariantDraft {
  _PackVariantDraft({
    required this.id,
    required this.labelCtrl,
    required this.weightValueCtrl,
    required this.priceRupeeCtrl,
    required this.stockCtrl,
    required this.lowStockCtrl,
    required this.unit,
  });

  final String id;
  final TextEditingController labelCtrl;
  /// Numeric weight; paired with [unit] → stored as [totalGrams] in Firestore.
  final TextEditingController weightValueCtrl;
  final TextEditingController priceRupeeCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController lowStockCtrl;
  _PackWeightUnit unit;

  void dispose() {
    labelCtrl.dispose();
    weightValueCtrl.dispose();
    priceRupeeCtrl.dispose();
    stockCtrl.dispose();
    lowStockCtrl.dispose();
  }

  factory _PackVariantDraft.empty() {
    final id = 'v_${DateTime.now().microsecondsSinceEpoch}';
    return _PackVariantDraft(
      id: id,
      labelCtrl: TextEditingController(),
      weightValueCtrl: TextEditingController(),
      priceRupeeCtrl: TextEditingController(),
      stockCtrl: TextEditingController(text: '0'),
      lowStockCtrl: TextEditingController(text: '5'),
      unit: _PackWeightUnit.grams,
    );
  }

  factory _PackVariantDraft.fromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? 'v_${DateTime.now().microsecondsSinceEpoch}';
    final label = (m['label'] ?? m['name'] ?? '') as String;
    final tg = (m['totalGrams'] ?? m['total_grams']) as num?;
    final totalGrams = tg?.toInt() ?? 0;
    final minor = (m['priceMinor'] as num?)?.toInt() ?? 0;
    final rupees = minor > 0 ? (minor / 100).toStringAsFixed(minor % 100 == 0 ? 0 : 2) : '';

    final stored = (m['weightInputUnit'] as String?)?.toLowerCase();
    late _PackWeightUnit u;
    late String weightText;
    if (stored == 'kg') {
      u = _PackWeightUnit.kg;
      final kg = totalGrams / 1000.0;
      weightText = kg == kg.roundToDouble() ? '${kg.toInt()}' : _trimDecimal(kg);
    } else if (stored == 'g') {
      u = _PackWeightUnit.grams;
      weightText = '$totalGrams';
    } else {
      if (totalGrams > 0 && totalGrams % 1000 == 0) {
        u = _PackWeightUnit.kg;
        weightText = '${totalGrams ~/ 1000}';
      } else {
        u = _PackWeightUnit.grams;
        weightText = totalGrams > 0 ? '$totalGrams' : '';
      }
    }

    return _PackVariantDraft(
      id: id,
      labelCtrl: TextEditingController(text: label),
      weightValueCtrl: TextEditingController(text: weightText),
      priceRupeeCtrl: TextEditingController(text: rupees),
      stockCtrl: TextEditingController(
        text: '${(m['stock'] as num?)?.toInt() ?? 0}',
      ),
      lowStockCtrl: TextEditingController(
        text: '${(m['lowStockThreshold'] as num?)?.toInt() ?? 5}',
      ),
      unit: u,
    );
  }

  static String _trimDecimal(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.round()}';
    final s = kg.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '');
    return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
  }

  /// Canonical grams for Firestore / cart / coupons.
  int? weightToTotalGrams() {
    final raw = weightValueCtrl.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw.replaceAll(',', ''));
    if (v == null || v <= 0) return null;
    if (unit == _PackWeightUnit.kg) {
      return (v * 1000).round();
    }
    if (v != v.roundToDouble()) return null;
    return v.round();
  }

  Map<String, dynamic> toFirestoreMap() {
    final grams = weightToTotalGrams() ?? 0;
    final minor = _parseRupeesToMinor(priceRupeeCtrl.text.trim()) ?? 0;
    return {
      'id': id,
      'label': labelCtrl.text.trim(),
      'totalGrams': grams,
      'weightInputUnit': unit == _PackWeightUnit.kg ? 'kg' : 'g',
      'priceMinor': minor,
      'stock': int.tryParse(stockCtrl.text.trim()) ?? 0,
      'lowStockThreshold': int.tryParse(lowStockCtrl.text.trim()) ?? 5,
    };
  }

  static int? _parseRupeesToMinor(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'[₹,\s]'), '');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }
}

/// Quick-add presets (Blinkit-style ladder).
const _kPackPresets = <Map<String, Object>>[
  {'label': '200 g', 'grams': 200},
  {'label': '500 g', 'grams': 500},
  {'label': '1 kg', 'grams': 1000},
  {'label': '2 kg', 'grams': 2000},
  {'label': '10 kg', 'grams': 10000},
];

class _AdminProductEditorBody extends StatefulWidget {
  const _AdminProductEditorBody({
    required this.db,
    this.documentId,
    this.initial,
  });

  final FirebaseFirestore db;
  final String? documentId;
  final Map<String, dynamic>? initial;

  @override
  State<_AdminProductEditorBody> createState() =>
      _AdminProductEditorBodyState();
}

class _AdminProductEditorBodyState extends State<_AdminProductEditorBody> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _image;
  late bool _published;
  bool _saving = false;

  final List<_PackVariantDraft> _packs = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?['name'] as String? ?? '');
    _desc = TextEditingController(text: i?['description'] as String? ?? '');
    _image = TextEditingController(text: i?['image_url'] as String? ?? '');
    _published = i?['published'] as bool? ?? true;

    final raw = i?['variants'] as List<dynamic>? ?? [];
    if (raw.isEmpty) {
      _packs.add(_PackVariantDraft.empty());
    } else {
      for (final e in raw) {
        _packs.add(_PackVariantDraft.fromMap(Map<String, dynamic>.from(e as Map)));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _image.dispose();
    for (final p in _packs) {
      p.dispose();
    }
    super.dispose();
  }

  void _addPack() => setState(() => _packs.add(_PackVariantDraft.empty()));

  void _applyPreset(Map<String, Object> preset) {
    final d = _PackVariantDraft.empty();
    d.labelCtrl.text = preset['label'] as String;
    final grams = preset['grams'] as int;
    if (grams >= 1000 && grams % 1000 == 0) {
      d.unit = _PackWeightUnit.kg;
      d.weightValueCtrl.text = '${grams ~/ 1000}';
    } else {
      d.unit = _PackWeightUnit.grams;
      d.weightValueCtrl.text = '$grams';
    }
    setState(() => _packs.add(d));
  }

  void _removePack(int index) {
    if (_packs.length <= 1) {
      Get.snackbar('Keep one pack', 'Every product needs at least one pack size.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() {
      _packs[index].dispose();
      _packs.removeAt(index);
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Name required', 'Enter a product name.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    for (var i = 0; i < _packs.length; i++) {
      final p = _packs[i];
      final label = p.labelCtrl.text.trim();
      final grams = p.weightToTotalGrams();
      if (label.isEmpty || grams == null || grams <= 0) {
        Get.snackbar(
          'Pack ${i + 1}',
          'Each pack needs a label (e.g. 500 g or 1 kg) and a positive weight '
          '(use grams or kg from the unit menu). Whole numbers only for grams.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final priceMinor = _parseRupeeField(p.priceRupeeCtrl.text);
      if (priceMinor == null || priceMinor < 0) {
        Get.snackbar(
          'Pack ${i + 1}',
          'Enter a valid price in ₹ for each pack.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final variants = _packs.map((p) => p.toFirestoreMap()).toList();
      final col = widget.db.collection('products');
      final payload = <String, dynamic>{
        'name': name,
        'description': _desc.text.trim(),
        'image_url': _image.text.trim(),
        'published': _published,
        'variants': variants,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.documentId == null) {
        final ref = col.doc();
        await ref.set({
          ...payload,
          'id': ref.id,
        });
      } else {
        await col.doc(widget.documentId).set(payload, SetOptions(merge: true));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      Get.snackbar('Saved', 'Catalog & pack sizes updated.',
          snackPosition: SnackPosition.BOTTOM);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static int? _parseRupeeField(String raw) {
    final t = raw.trim().replaceAll(RegExp(r'[₹,\s]'), '');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isNew = widget.documentId == null;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isNew ? 'Add catalog product' : 'Edit catalog product',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Customers pick a pack on the product screen (like Blinkit). '
                'Add every weight you sell — 200 g, 500 g, 1 kg, bulk 10 kg, etc.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _image,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://…',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              SwitchListTile(
                title: const Text('Published in catalog'),
                value: _published,
                onChanged: _saving ? null : (v) => setState(() => _published = v),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Icon(Icons.scale_rounded, size: 22, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Pack sizes & pricing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Canonical weight is stored as grams for coupons; choose kg when '
                'that is easier (e.g. 2 kg → 2000 g). Labels should match what '
                'customers see.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in _kPackPresets)
                      ActionChip(
                        label: Text('${preset['label']}'),
                        onPressed: _saving ? null : () => _applyPreset(preset),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _addPack,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add custom pack row'),
              ),
              const SizedBox(height: 16),
              ...List.generate(_packs.length, (index) {
                final p = _packs[index];
                return _PackSizeCard(
                  index: index,
                  draft: p,
                  onRemove: () => _removePack(index),
                  onDraftChanged: () => setState(() {}),
                  enabled: !_saving,
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isNew ? 'Create product' : 'Save product & packs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackSizeCard extends StatelessWidget {
  const _PackSizeCard({
    required this.index,
    required this.draft,
    required this.onRemove,
    required this.onDraftChanged,
    required this.enabled,
  });

  final int index;
  final _PackVariantDraft draft;
  final VoidCallback onRemove;
  final VoidCallback onDraftChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kg = draft.unit == _PackWeightUnit.kg;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pack ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Remove pack',
                    onPressed: enabled ? onRemove : null,
                    icon: Icon(Icons.delete_outline_rounded,
                        color: scheme.error),
                  ),
                ],
              ),
              TextField(
                controller: draft.labelCtrl,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'Label (shown to customer)',
                  hintText: 'e.g. 500 g or 1 kg',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.weightValueCtrl,
                      enabled: enabled,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: kg,
                      ),
                      inputFormatters: kg
                          ? [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ]
                          : [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        hintText: kg ? '1 or 1.5' : '250',
                        helperText:
                            kg ? 'Decimals allowed for kg' : 'Whole grams',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => onDraftChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 158,
                    child: DropdownButtonFormField<_PackWeightUnit>(
                      key: ValueKey('${draft.id}_${draft.unit}'),
                      initialValue: draft.unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: _PackWeightUnit.values
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(
                                u.dropdownLabel,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: enabled
                          ? (u) {
                              if (u != null) {
                                draft.unit = u;
                                onDraftChanged();
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: draft.priceRupeeCtrl,
                enabled: enabled,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'MRP (₹)',
                  hintText: '199',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: draft.stockCtrl,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: draft.lowStockCtrl,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Low-stock alert',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
