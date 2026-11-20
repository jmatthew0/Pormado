import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/image_processing.dart';
import '../state.dart';
import '../ui.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.initialCategory});
  final Category? initialCategory;
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _picker = ImagePicker();
  int step = 1;
  bool editing = false;
  bool busy = false;

  Uint8List? original;
  Uint8List? cutout;
  bool removed = false;
  bool useCutout = true;
  Uint8List? get _shown => (useCutout && removed) ? cutout : original;
  late Category category = widget.initialCategory ?? Category.tops;
  late String subtype = category.subtypes.first;
  String colorName = 'White';
  String material = 'Cotton';
  String pattern = 'Solid';

  final nameCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  int warmth = 1;
  bool waterproof = false;
  bool favorite = false;

  static const materials = [
    'Cotton',
    'Linen',
    'Denim',
    'Wool',
    'Polyester',
    'Leather',
    'Silk',
    'Rubber',
    'Nylon'
  ];
  static const patterns = ['Solid', 'Striped', 'Checked', 'Floral', 'Printed'];

  @override
  void dispose() {
    nameCtrl.dispose();
    brandCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingest(Uint8List bytes) async {
    setState(() {
      busy = true;
      original = bytes;
    });
    final res = await ImageService.removeBackground(bytes);
    final c = await ImageService.dominantColor(res.bytes);
    if (!mounted) return;
    setState(() {
      cutout = res.bytes;
      removed = res.removed;
      useCutout = true;
      if (c != null) colorName = nearestColorName(c);
      busy = false;
    });
    if (!res.removed) {
      snack(context,
          'Couldn\'t find a clear background. Try a plain surface, or keep the original.');
    }
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await _picker.pickImage(
          source: src, maxWidth: 1600, imageQuality: 90);
      if (x == null) return;
      await _ingest(await x.readAsBytes());
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        snack(context,
            'Couldn\'t open the photo. Check camera/photo permissions.');
      }
    }
  }

  Future<void> _importLink() async {
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text('Import from link', style: serif(22)),
        content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://…/image.jpg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Import')),
        ],
      ),
    );
    if (url != null && url.startsWith('http')) {
      try {
        final r =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
        if (r.statusCode != 200) throw Exception();
        await _ingest(r.bodyBytes);
      } catch (_) {
        if (mounted) snack(context, 'Couldn\'t download that image.');
      }
    }
  }

  void _save() {
    final name = nameCtrl.text.trim().isEmpty
        ? '$colorName ${subtype.toLowerCase()}'
        : nameCtrl.text.trim();
    context.read<AppState>().addItem(ClothingItem(
          id: 'i${DateTime.now().microsecondsSinceEpoch}',
          name: name,
          category: category,
          subtype: subtype,
          colorName: colorName,
          color: palette[colorName] ?? Colors.grey,
          material: material,
          pattern: pattern,
          brand: brandCtrl.text.trim(),
          price: double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0,
          warmth: warmth,
          waterproof: waterproof,
          openShoes: category == Category.shoes && subtype == 'Sandals',
          favorite: favorite,
          imageBytes: _shown,
          emoji: category.emoji,
        ));
    Navigator.pop(context);
    snack(context, '$name saved to your wardrobe');
  }

  Widget _dropdown<T>(String label, T value, List<T> opts,
      String Function(T) text, ValueChanged<T?> on) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: sans(12.5, color: C.muted)),
        DropdownButton<T>(
          isExpanded: true,
          value: value,
          underline: const SizedBox(),
          style: sans(15, w: FontWeight.w700),
          items: [
            for (final o in opts)
              DropdownMenuItem(value: o, child: Text(text(o)))
          ],
          onChanged: on,
        ),
      ]),
    );
  }

  Widget _readonly(String label, Widget value) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: sans(12.5, color: C.muted)),
            const SizedBox(height: 4),
            value,
          ]),
        ),
      );

  Widget _step1() {
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          Panel(
            radius: 28,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 300,
              child: Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: busy
                        ? const Center(
                            child: CircularProgressIndicator(color: C.green))
                        : original == null
                            ? Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(category.emoji,
                                          style: const TextStyle(fontSize: 64)),
                                      const SizedBox(height: 10),
                                      Text('Add a photo of your piece',
                                          style: sans(15, color: C.muted)),
                                    ]),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(22),
                                child: Image.memory(_shown!,
                                    fit: BoxFit.contain, gaplessPlayback: true),
                              ),
                  ),
                ),
                if (original != null)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: C.ink,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.auto_awesome,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                            removed && useCutout
                                ? 'Background removed'
                                : 'Photo ready',
                            style: sans(12.5, color: Colors.white)),
                      ]),
                    ),
                  ),
                if (removed)
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Pill(useCutout ? 'Cutout' : 'Original',
                        selected: useCutout,
                        onTap: () => setState(() => useCutout = !useCutout)),
                  ),
                if (original != null)
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        original = null;
                        cutout = null;
                        removed = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: C.line)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.refresh, size: 16),
                          const SizedBox(width: 6),
                          Text('Retake', style: sans(13.5, w: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            for (final e in [
              (
                Icons.photo_camera_outlined,
                'Camera',
                () => _pick(ImageSource.camera)
              ),
              (
                Icons.photo_library_outlined,
                'Gallery',
                () => _pick(ImageSource.gallery)
              ),
              (Icons.link, 'Import link', _importLink),
            ].asMap().entries) ...[
              if (e.key > 0) const SizedBox(width: 10),
              Expanded(
                child: Panel(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  onTap: e.value.$3,
                  child: Column(children: [
                    Icon(e.value.$1, color: C.green),
                    const SizedBox(height: 8),
                    Text(e.value.$2, style: sans(13.5, w: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          Panel(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('We detected', style: serif(21))),
                GestureDetector(
                  onTap: () => setState(() => editing = !editing),
                  child: Text(editing ? 'Done' : 'Edit',
                      style: sans(15, color: C.green, w: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 14),
              if (!editing) ...[
                Row(children: [
                  _readonly(
                      'Category',
                      Text('${category.label} · $subtype',
                          style: sans(16, w: FontWeight.w700))),
                  _readonly(
                    'Color',
                    Row(children: [
                      Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                              color: palette[colorName],
                              shape: BoxShape.circle,
                              border: Border.all(color: C.line))),
                      const SizedBox(width: 8),
                      Text(colorName, style: sans(16, w: FontWeight.w700)),
                    ]),
                  ),
                ]),
                Row(children: [
                  _readonly('Material',
                      Text(material, style: sans(16, w: FontWeight.w700))),
                  _readonly('Pattern',
                      Text(pattern, style: sans(16, w: FontWeight.w700))),
                ]),
              ] else ...[
                Row(children: [
                  _dropdown<Category>(
                      'Category', category, Category.values, (c) => c.label,
                      (v) {
                    if (v == null) return;
                    setState(() {
                      category = v;
                      subtype = v.subtypes.first;
                    });
                  }),
                  const SizedBox(width: 16),
                  _dropdown<String>('Type', subtype, category.subtypes,
                      (s) => s, (v) => setState(() => subtype = v ?? subtype)),
                ]),
                Row(children: [
                  _dropdown<String>(
                      'Color',
                      colorName,
                      palette.keys.toList(),
                      (s) => s,
                      (v) => setState(() => colorName = v ?? colorName)),
                  const SizedBox(width: 16),
                  _dropdown<String>('Material', material, materials, (s) => s,
                      (v) => setState(() => material = v ?? material)),
                ]),
                Row(children: [
                  _dropdown<String>('Pattern', pattern, patterns, (s) => s,
                      (v) => setState(() => pattern = v ?? pattern)),
                  const Spacer(),
                ]),
              ],
            ]),
          ),
        ]);
  }

  Widget _field(String label, TextEditingController c,
          {TextInputType? type, String? prefix}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: sans(13, color: C.muted)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.line)),
            child: TextField(
              controller: c,
              keyboardType: type,
              style: sans(16),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixText: prefix,
                  contentPadding: const EdgeInsets.all(16)),
            ),
          ),
        ]),
      );

  Widget _step2() {
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          _field('Name', nameCtrl),
          _field('Brand', brandCtrl),
          _field('Price paid (for cost per wear)', priceCtrl,
              type: TextInputType.number, prefix: '₱ '),
          Text('How warm is it?', style: sans(13, color: C.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final e in ['Very light', 'Breathable', 'Medium', 'Warm']
                .asMap()
                .entries)
              Pill(e.value,
                  selected: warmth == e.key,
                  onTap: () => setState(() => warmth = e.key)),
          ]),
          const SizedBox(height: 14),
          Panel(
            radius: 20,
            child: Column(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: C.green,
                title: Text('Waterproof / rain-ready',
                    style: sans(15, w: FontWeight.w600)),
                value: waterproof,
                onChanged: (v) => setState(() => waterproof = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: C.green,
                title: Text('Add to favorites',
                    style: sans(15, w: FontWeight.w600)),
                value: favorite,
                onChanged: (v) => setState(() => favorite = v),
              ),
            ]),
          ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                RoundBtn(
                  icon: step == 1 ? Icons.close : Icons.chevron_left,
                  onTap: () => step == 1
                      ? Navigator.pop(context)
                      : setState(() => step = 1),
                ),
                Expanded(
                    child: Center(child: Text('Add item', style: serif(24)))),
                Text('$step/2', style: sans(14, color: C.muted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: step / 2,
                    minHeight: 6,
                    color: C.green,
                    backgroundColor: const Color(0xFFE6E0D4)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                    step == 1
                        ? 'Step 1 · Photo & detection'
                        : 'Step 2 · Details',
                    style: sans(13, color: C.muted)),
              ),
            ),
            Expanded(child: step == 1 ? _step1() : _step2()),
          ]),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: step == 1
                ? Btn('Continue',
                    icon: Icons.arrow_forward,
                    onTap: () => setState(() => step = 2))
                : Btn('Save to wardrobe', icon: Icons.check, onTap: _save),
          ),
        ]),
      ),
    );
  }
}
