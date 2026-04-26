import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/api/admin_api_models.dart';
import '../../../../services/admin/admin_api_service.dart';

enum _PackWeightUnit {
  grams,
  kg;

  String get dropdownLabel =>
      this == _PackWeightUnit.kg ? 'kilograms (kg)' : 'grams (g)';
}

/// Create or update a product via API.
///
/// **Pack sizes** — same idea as Blinkit: each row is a sellable SKU (200 g, 500 g, 1 kg…)
/// with **canonical `totalGrams`** (for coupons / logic), **MRP in ₹**, and stock.
Future<void> showAdminProductEditorSheet(
  BuildContext context, {
  required AdminApiService api,
  String? productId,
  Product? initial,
  VoidCallback? onSaved,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (ctx) => _AdminProductEditorBody(
      api: api,
      productId: productId,
      initial: initial,
      onSaved: onSaved,
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

  factory _PackVariantDraft.fromVariant(ProductVariant v) {
    final totalGrams = v.totalGrams;
    final minor = v.priceMinor;
    final rupees = minor > 0 ? (minor / 100).toStringAsFixed(minor % 100 == 0 ? 0 : 2) : '';

    late _PackWeightUnit u;
    late String weightText;
    if (totalGrams > 0 && totalGrams % 1000 == 0) {
      u = _PackWeightUnit.kg;
      weightText = '${totalGrams ~/ 1000}';
    } else {
      u = _PackWeightUnit.grams;
      weightText = totalGrams > 0 ? '$totalGrams' : '';
    }

    return _PackVariantDraft(
      id: v.id,
      labelCtrl: TextEditingController(text: v.label),
      weightValueCtrl: TextEditingController(text: weightText),
      priceRupeeCtrl: TextEditingController(text: rupees),
      stockCtrl: TextEditingController(text: '${v.stock}'),
      lowStockCtrl: TextEditingController(text: '${v.lowStockThreshold}'),
      unit: u,
    );
  }

  static String _trimDecimal(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.round()}';
    final s = kg.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '');
    return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
  }

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

  ProductVariant toVariant() {
    final grams = weightToTotalGrams() ?? 0;
    final minor = _parseRupeesToMinor(priceRupeeCtrl.text.trim()) ?? 0;
    return ProductVariant(
      id: id,
      label: labelCtrl.text.trim(),
      totalGrams: grams,
      priceMinor: minor,
      stock: int.tryParse(stockCtrl.text.trim()) ?? 0,
      lowStockThreshold: int.tryParse(lowStockCtrl.text.trim()) ?? 5,
    );
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
    required this.api,
    this.productId,
    this.initial,
    this.onSaved,
  });

  final AdminApiService api;
  final String? productId;
  final Product? initial;
  final VoidCallback? onSaved;

  @override
  State<_AdminProductEditorBody> createState() =>
      _AdminProductEditorBodyState();
}

class _AdminProductEditorBodyState extends State<_AdminProductEditorBody> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late String _imageUrl;
  late bool _published;
  bool _saving = false;
  bool _uploadingImage = false;
  
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  final List<_PackVariantDraft> _packs = [];
  final Set<int> _selectedPresetGrams = {};
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _desc = TextEditingController(text: i?.description ?? '');
    _imageUrl = i?.imageUrl ?? '';
    _published = i?.published ?? true;

    final variants = i?.variants ?? [];
    if (variants.isEmpty) {
      _packs.add(_PackVariantDraft.empty());
    } else {
      for (final v in variants) {
        final pack = _PackVariantDraft.fromVariant(v);
        _packs.add(pack);
        final grams = pack.weightToTotalGrams();
        if (grams != null) {
          _selectedPresetGrams.add(grams);
        }
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    for (final p in _packs) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageBytes != null || _imageUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
                title: Text('Remove Image', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImageBytes = null;
                    _selectedImageName = null;
                    _imageUrl = '';
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _prepareImageUrl() async {
    if (_selectedImageBytes == null) return _imageUrl.isNotEmpty ? _imageUrl : null;
    
    if (kDebugMode) debugPrint('Image upload not implemented - using placeholder');
    return _imageUrl.isNotEmpty ? _imageUrl : null;
  }

  void _addPack() => setState(() => _packs.add(_PackVariantDraft.empty()));

  void _applyPreset(Map<String, Object> preset) {
    final grams = preset['grams'] as int;
    
    if (_selectedPresetGrams.contains(grams)) {
      final index = _packs.indexWhere((p) => p.weightToTotalGrams() == grams);
      if (index != -1) {
        _removePack(index);
      }
      setState(() => _selectedPresetGrams.remove(grams));
      return;
    }
    
    final d = _PackVariantDraft.empty();
    d.labelCtrl.text = preset['label'] as String;
    if (grams >= 1000 && grams % 1000 == 0) {
      d.unit = _PackWeightUnit.kg;
      d.weightValueCtrl.text = '${grams ~/ 1000}';
    } else {
      d.unit = _PackWeightUnit.grams;
      d.weightValueCtrl.text = '$grams';
    }
    setState(() {
      _packs.add(d);
      _selectedPresetGrams.add(grams);
    });
  }

  void _removePack(int index) {
    if (_packs.length <= 1) {
      Get.snackbar('Keep one pack', 'Every product needs at least one pack size.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final grams = _packs[index].weightToTotalGrams();
    setState(() {
      _packs[index].dispose();
      _packs.removeAt(index);
      if (grams != null) _selectedPresetGrams.remove(grams);
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
      final imageUrl = await _prepareImageUrl();
      
      final variants = _packs.map((p) => p.toVariant()).toList();
      
      final productId = widget.productId ?? 'prod_${DateTime.now().millisecondsSinceEpoch}';
      final product = Product(
        id: productId,
        name: name,
        description: _desc.text.trim(),
        imageUrl: imageUrl,
        published: _published,
        variants: variants,
      );

      await widget.api.upsertProduct(productId, product);
      
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved?.call();
      Get.snackbar('Saved', 'Product saved successfully.',
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

  Widget _buildImagePlaceholder(ColorScheme scheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          size: 48,
          color: scheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Camera or Gallery',
          style: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isNew = widget.productId == null;
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
              const SizedBox(height: 16),
              Text(
                'Product Image',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _saving || _uploadingImage ? null : _showImagePickerOptions,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: _uploadingImage
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Uploading...'),
                            ],
                          ),
                        )
                      : _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                                        onPressed: _showImagePickerOptions,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        _imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(scheme),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                                            onPressed: _showImagePickerOptions,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildImagePlaceholder(scheme),
                ),
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
                      _PackPresetChip(
                        label: preset['label'] as String,
                        isSelected: _selectedPresetGrams.contains(preset['grams'] as int),
                        onTap: _saving ? null : () => _applyPreset(preset),
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

class _PackPresetChip extends StatelessWidget {
  const _PackPresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
