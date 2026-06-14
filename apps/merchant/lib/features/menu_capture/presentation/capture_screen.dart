import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_domain/restaurant_domain.dart' as domain;

import '../../../core/l10n_ext.dart';
import '../../menu/application/providers.dart' as menu;
import '../application/providers.dart';
import '../domain/capture_template.dart';
import '../domain/geometry.dart';
import '../domain/item_draft.dart';
import '../domain/text_recognizer.dart';
import 'draft_review_screen.dart';
import 'field_display.dart';
import 'photo_box_canvas.dart';
import 'template_editor_screen.dart';
import 'template_list_screen.dart';

/// The capture sweep: pick a category, a menu photo and a template; OCR the
/// photo once; then slide the big block over each item, capturing a draft each
/// time. Drafts go to the review screen for editing and bulk save.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  static const _imageTypes = XTypeGroup(
    label: 'images',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
  );

  String? _categoryId;
  CaptureTemplate? _template;
  String? _imagePath;
  Size? _imageSize;
  RecognizedText? _ocr;
  bool _ocrRunning = false;

  RegionRect _block = kDefaultCaptureBlock;
  bool _showLabels = true;
  final List<ItemDraft> _drafts = [];

  Future<void> _pickPhoto() async {
    final file = await openFile(acceptedTypeGroups: [_imageTypes]);
    if (file == null) return;
    final size = await imageSizeOf(file.path);
    if (!mounted) return;
    setState(() {
      _imagePath = file.path;
      _imageSize = size;
      _ocr = null;
      _drafts.clear();
    });
    await _runOcr();
  }

  Future<void> _runOcr() async {
    if (_imagePath == null) return;
    setState(() => _ocrRunning = true);
    try {
      final result = await ref
          .read(textRecognizerProvider)
          .recognize(_imagePath!);
      if (!mounted) return;
      setState(() => _ocr = result);
    } on OcrLanguageUnavailable {
      _snack(context.l10n.captureOcrLanguageMissing);
    } on UnsupportedError {
      _snack(context.l10n.captureUnsupportedPlatform);
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  void _capture() {
    if (_ocr == null || _template == null || _imageSize == null) return;
    final imageBox = PixelBox.ltwh(0, 0, _imageSize!.width, _imageSize!.height);
    final draft = ref
        .read(captureEngineProvider)
        .buildDraft(_ocr!, _template!, _block.toPixels(imageBox));
    setState(() {
      if (!draft.isEmpty) _drafts.add(draft);
      // Auto-advance the block down by its own height for the next item.
      _block = RegionRect(
        left: _block.left,
        top: (_block.top + _block.height).clamp(0.0, 1 - _block.height),
        width: _block.width,
        height: _block.height,
      );
    });
  }

  Future<void> _review() async {
    if (_drafts.isEmpty || _imagePath == null || _categoryId == null) return;
    final saved = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => DraftReviewScreen(
          categoryId: _categoryId!,
          sourcePhotoPath: _imagePath!,
          drafts: List.of(_drafts),
        ),
      ),
    );
    if (saved != null && saved > 0 && mounted) {
      Navigator.pop(context); // done importing; back to the menu
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(menu.categoriesProvider).value ?? const [];
    final templates = ref.watch(captureTemplatesProvider);
    _categoryId ??= categories.isEmpty ? null : categories.first.id;
    final ready = _ocr != null && _template != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.captureTitle),
        actions: [
          if (ready)
            IconButton(
              tooltip: context.l10n.captureLabelsToggle,
              onPressed: () => setState(() => _showLabels = !_showLabels),
              icon: Icon(_showLabels ? Icons.label : Icons.label_off_outlined),
            ),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TemplateListScreen()),
            ),
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: Text(context.l10n.captureTemplatesShort),
          ),
        ],
      ),
      body: Column(
        children: [
          _setupBar(context, categories, templates),
          if (_ocrRunning) const LinearProgressIndicator(),
          Expanded(child: _canvasArea(context, templates, ready)),
        ],
      ),
      floatingActionButton: ready
          ? FloatingActionButton.extended(
              onPressed: _capture,
              icon: const Icon(Icons.add_box_outlined),
              label: Text(context.l10n.captureCaptureItem),
            )
          : null,
    );
  }

  Widget _setupBar(
    BuildContext context,
    List<domain.Category> categories,
    List<CaptureTemplate> templates,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<String>(
            value: _categoryId,
            hint: Text(context.l10n.captureChooseCategory),
            items: [
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          DropdownButton<CaptureTemplate>(
            value: _template,
            hint: Text(context.l10n.captureChooseTemplate),
            items: [
              for (final t in templates)
                DropdownMenuItem(value: t, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() {
              _template = v;
              // Start the block at the size the template was designed with, so
              // the regions keep their proportions.
              if (v != null) _block = v.block;
            }),
          ),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(context.l10n.capturePickPhoto),
          ),
          if (_drafts.isNotEmpty)
            FilledButton.icon(
              onPressed: _review,
              icon: const Icon(Icons.checklist),
              label: Text(
                '${context.l10n.captureReviewAction} '
                '(${context.l10n.captureDraftCount(_drafts.length)})',
              ),
            ),
        ],
      ),
    );
  }

  Widget _canvasArea(
    BuildContext context,
    List<CaptureTemplate> templates,
    bool ready,
  ) {
    if (templates.isEmpty) return _noTemplatesCta(context);
    if (_imagePath == null || _imageSize == null) {
      return Center(child: Text(context.l10n.captureSelectPhotoFirst));
    }
    if (_template == null) {
      return Center(child: Text(context.l10n.captureSelectTemplateFirst));
    }
    final colors = captureRegionColors(_template!.regions);
    return ColoredBox(
      color: Colors.black12,
      child: PhotoBoxCanvas(
        imagePath: _imagePath!,
        imageSize: _imageSize!,
        block: _block,
        onBlockChanged: ready ? (b) => setState(() => _block = b) : null,
        showLabels: _showLabels,
        regions: [
          for (final r in _template!.regions)
            CanvasRegion(
              id: r.id,
              rect: r.rect,
              color: colors[r.id]!,
              label: r.label.isEmpty
                  ? captureFieldLabel(context, r.field)
                  : r.label,
            ),
        ],
      ),
    );
  }

  /// Shown when no templates exist yet — leads straight into the builder,
  /// seeded with the photo if one was already picked.
  Widget _noTemplatesCta(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.captureNoTemplates, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _createTemplate,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.captureCreateTemplate),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTemplate() async {
    final name = await _promptName();
    if (name == null || name.isEmpty || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TemplateEditorScreen(
          template: CaptureTemplate(
            id: domain.newId(),
            name: name,
            regions: const [],
          ),
          initialPhotoPath: _imagePath,
        ),
      ),
    );
  }

  Future<String?> _promptName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.captureTemplateNameHint,
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
}
