import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../application/providers.dart';
import '../domain/capture_template.dart';
import '../domain/geometry.dart';
import 'field_display.dart';
import 'photo_box_canvas.dart';
import 'region_layers_bar.dart';

/// Lets the merchant lay out a capture template against a sample photo: drag a
/// big block over one item, then draw labelled regions inside it. Regions are
/// stored normalized to the block, so the template re-applies as the block is
/// swept over each item at capture time.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  final CaptureTemplate template;

  /// When provided (e.g. the photo just picked in the capture flow), the editor
  /// opens already showing that photo to design against.
  final String? initialPhotoPath;

  const TemplateEditorScreen({
    super.key,
    required this.template,
    this.initialPhotoPath,
  });

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  static const _imageTypes = XTypeGroup(
    label: 'images',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  );

  String? _imagePath;
  Size? _imageSize;
  late RegionRect _block = widget.template.block;
  late List<CaptureRegion> _regions = [...widget.template.regions];
  String? _selectedId;
  bool _showLabels = true;

  @override
  void initState() {
    super.initState();
    final path = widget.initialPhotoPath;
    if (path != null) {
      _imagePath = path;
      imageSizeOf(path).then((size) {
        if (mounted) setState(() => _imageSize = size);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypes]);
    if (file == null) return;
    final size = await imageSizeOf(file.path);
    if (!mounted) return;
    setState(() {
      _imagePath = file.path;
      _imageSize = size;
    });
  }

  void _addRegion(CaptureField field, String label) {
    final i = _regions.length;
    setState(() {
      final region = CaptureRegion(
        id: domain.newId(),
        field: field,
        label: label,
        rect: RegionRect(
          left: 0.05,
          top: (0.05 + i * 0.04).clamp(0.0, 0.8),
          width: 0.9,
          height: 0.18,
        ),
      );
      _regions = [..._regions, region];
      _selectedId = region.id;
    });
  }

  void _updateRegion(String id, RegionRect rect) {
    setState(() {
      _regions = [
        for (final r in _regions)
          if (r.id == id) r.copyWith(rect: rect) else r,
      ];
    });
  }

  void _deleteSelected() {
    setState(() {
      _regions = _regions.where((r) => r.id != _selectedId).toList();
      _selectedId = null;
    });
  }

  Future<void> _save() async {
    if (_regions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.captureNeedsBlockAndRegion)),
      );
      return;
    }
    await ref
        .read(captureTemplatesProvider.notifier)
        .save(widget.template.copyWith(regions: _regions, block: _block));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _promptAddRegion() async {
    final field = await showModalBottomSheet<CaptureField>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final f in CaptureField.values)
              ListTile(
                leading: Icon(Icons.crop_square, color: captureFieldColor(f)),
                title: Text(captureFieldLabel(context, f)),
                onTap: () => Navigator.pop(context, f),
              ),
          ],
        ),
      ),
    );
    if (field == null || !mounted) return;
    if (field == CaptureField.attribute) {
      final label = await _promptLabel(context.l10n.captureFieldAttribute);
      if (label == null || label.isEmpty) return;
      _addRegion(field, label);
    } else {
      _addRegion(field, captureFieldLabel(context, field));
    }
  }

  Future<String?> _promptLabel(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.captureRegionLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _imagePath != null && _imageSize != null;
    final colors = captureRegionColors(_regions);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          if (hasPhoto) ...[
            IconButton(
              tooltip: context.l10n.captureLabelsToggle,
              onPressed: () => setState(() => _showLabels = !_showLabels),
              icon: Icon(_showLabels ? Icons.label : Icons.label_off_outlined),
            ),
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.image_outlined),
              label: Text(context.l10n.capturePickSamplePhoto),
            ),
          ],
          TextButton(
            onPressed: _save,
            child: Text(context.l10n.captureSaveTemplate),
          ),
        ],
      ),
      body: !hasPhoto
          ? Center(
              child: FilledButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(context.l10n.capturePickSamplePhoto),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    context.l10n.captureBigBlockHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: PhotoBoxCanvas(
                      imagePath: _imagePath!,
                      imageSize: _imageSize!,
                      block: _block,
                      onBlockChanged: (b) => setState(() => _block = b),
                      showLabels: _showLabels,
                      regions: [
                        for (final r in _regions)
                          CanvasRegion(
                            id: r.id,
                            rect: r.rect,
                            color: colors[r.id]!,
                            label: r.label.isEmpty
                                ? captureFieldLabel(context, r.field)
                                : r.label,
                          ),
                      ],
                      selectedRegionId: _selectedId,
                      onSelectRegion: (id) => setState(() => _selectedId = id),
                      onRegionChanged: _updateRegion,
                    ),
                  ),
                ),
                _layersBar(context, colors),
              ],
            ),
    );
  }

  /// A "layers" strip: tap a chip to make that region the editable one.
  Widget _layersBar(BuildContext context, Map<String, Color> colors) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _promptAddRegion,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.captureAddRegion),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RegionChips(
                regions: _regions,
                colors: colors,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
              ),
            ),
            if (_selectedId != null)
              IconButton(
                tooltip: context.l10n.captureDeleteRegion,
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }
}
