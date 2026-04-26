import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../customer/home/data/customer_home_defaults.dart';
import '../../../customer/home/data/customer_home_api_datasource.dart';
import '../../../customer/home/domain/customer_home_category.dart';

/// Admin editor for customer home 2×2 tiles — persists via REST API.
///
/// Images: paste Unsplash / CDN URLs (local upload disabled).
class AdminCustomerHomePage extends StatefulWidget {
  const AdminCustomerHomePage({super.key});

  @override
  State<AdminCustomerHomePage> createState() => _AdminCustomerHomePageState();
}

class _RowCtr {
  _RowCtr._({
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.imageUrl,
    required this.order,
  });

  factory _RowCtr.from(CustomerHomeCategory c) {
    return _RowCtr._(
      title: TextEditingController(text: c.title),
      subtitle: TextEditingController(text: c.subtitle),
      tagline: TextEditingController(text: c.tagline),
      imageUrl: TextEditingController(text: c.imageUrl),
      order: TextEditingController(text: '${c.order}'),
    );
  }

  final TextEditingController title;
  final TextEditingController subtitle;
  final TextEditingController tagline;
  final TextEditingController imageUrl;
  final TextEditingController order;

  CustomerHomeCategory toCategory() {
    final o = int.tryParse(order.text.trim()) ?? 0;
    return CustomerHomeCategory(
      title: title.text.trim(),
      subtitle: subtitle.text.trim(),
      tagline: tagline.text.trim(),
      imageUrl: imageUrl.text.trim(),
      order: o,
    );
  }

  void dispose() {
    title.dispose();
    subtitle.dispose();
    tagline.dispose();
    imageUrl.dispose();
    order.dispose();
  }
}

class _AdminCustomerHomePageState extends State<AdminCustomerHomePage> {
  late final CustomerHomeApiDataSource _ds;

  List<_RowCtr> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  static bool _isAllowedTileImageUrl(String url) {
    final u = url.toLowerCase();
    return u.startsWith('https://images.unsplash.com/') ||
        u.startsWith('https://') && (u.contains('.cdn.') || u.contains('/images/'));
  }

  @override
  void initState() {
    super.initState();
    _ds = CustomerHomeApiDataSource(Get.find<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await _ds.fetchCategoriesOnce();
      for (final r in _rows) {
        r.dispose();
      }
      _rows = list.map(_RowCtr.from).toList();
      setState(() => _loading = false);
    } on Object catch (e) {
      setState(() {
        _loadError = '$e';
        _rows = defaultCustomerHomeCategories().map(_RowCtr.from).toList();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final built = <CustomerHomeCategory>[];
    for (final r in _rows) {
      final c = r.toCategory();
      if (c.title.isEmpty ||
          c.subtitle.isEmpty ||
          c.tagline.isEmpty ||
          c.imageUrl.isEmpty) {
        Get.snackbar(
          'Incomplete row',
          'Each tile needs title, subtitle, tagline, and image URL.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      if (!_isAllowedTileImageUrl(c.imageUrl)) {
        Get.snackbar(
          'Invalid image URL',
          'Paste a valid image URL (https://images.unsplash.com/... or CDN link).',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 8),
        );
        return;
      }
      built.add(c);
    }
    built.sort((a, b) => a.order.compareTo(b.order));
    setState(() => _saving = true);
    try {
      await _ds.saveCategories(built);
      if (mounted) {
        Get.snackbar(
          'Saved',
          'Customer home tiles updated. App reloads tiles live.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        Get.snackbar(
          'Save failed',
          '$e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addTile() {
    setState(() {
      _rows.add(
        _RowCtr.from(
          CustomerHomeCategory(
            title: 'New',
            subtitle: 'SUBTITLE',
            tagline: 'Describe this category.',
            imageUrl:
                'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?fm=jpg&fit=crop&w=1400&q=88',
            order: _rows.length,
          ),
        ),
      );
    });
  }

  void _removeAt(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Customer home categories'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Saving…' : 'Save to Firestore'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceMd,
                DesignTokens.spaceLg,
                DesignTokens.spaceXl + 72,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                      child: Material(
                        color: scheme.errorContainer,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceMd),
                          child: Text(
                            'Could not load Firestore ($_loadError). Showing defaults — Save writes your edits.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onErrorContainer),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    'Stored via REST API. '
                    'Customers see updates immediately. '
                    'Paste an Unsplash image URL (https://images.unsplash.com/…) '
                    'or other CDN-hosted image.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addTile,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add tile'),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  ...List.generate(_rows.length, (index) {
                    final r = _rows[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                      child: _TileEditorCard(
                        index: index,
                        ctr: r,
                        onRemove: () => _removeAt(index),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _TileEditorCard extends StatefulWidget {
  const _TileEditorCard({
    required this.index,
    required this.ctr,
    required this.onRemove,
  });

  final int index;
  final _RowCtr ctr;
  final VoidCallback onRemove;

  @override
  State<_TileEditorCard> createState() => _TileEditorCardState();
}

class _TileEditorCardState extends State<_TileEditorCard> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    Get.snackbar(
      'Image upload disabled',
      'Please paste a valid image URL (e.g., https://images.unsplash.com/...).',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  String _previewUrl() => widget.ctr.imageUrl.text.trim();

  bool _looksLikeUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _previewUrl();

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Tile ${widget.index + 1}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: widget.onRemove,
                  icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: widget.ctr.title,
              decoration: const InputDecoration(
                labelText: 'Title',
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: widget.ctr.subtitle,
              decoration: const InputDecoration(
                labelText: 'Subtitle (e.g. DAILY HARVEST)',
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: widget.ctr.tagline,
              decoration: const InputDecoration(
                labelText: 'Tagline / description',
                alignLabelWithHint: true,
              ),
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              'Category image',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: _uploading
                    ? ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : preview.isNotEmpty && _looksLikeUrl(preview)
                        ? Image.network(
                            preview,
                            fit: BoxFit.cover,
                            loadingBuilder: (ctx, child, prog) {
                              if (prog == null) return child;
                              return ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        prog.expectedTotalBytes != null &&
                                                prog.expectedTotalBytes! > 0
                                            ? prog.cumulativeBytesLoaded /
                                                prog.expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: scheme.outline,
                                size: 48,
                              ),
                            ),
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: scheme.outline,
                              size: 48,
                            ),
                          ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickAndUpload(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text(
                      'Gallery',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploading
                        ? null
                        : () => _pickAndUpload(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    label: const Text(
                      'Camera',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: widget.ctr.imageUrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://images.unsplash.com/… or CDN link',
                helperText:
                    'Paste Unsplash or other CDN-hosted image URL.',
                helperMaxLines: 2,
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.link_rounded),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            TextField(
              controller: widget.ctr.order,
              decoration: const InputDecoration(
                labelText: 'Sort order',
                hintText: '0 = first',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
