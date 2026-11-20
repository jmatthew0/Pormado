import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final Category category;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String sub = 'All';
  static const sortLabels = ['Recently worn', 'Most worn', 'Name', 'Newest'];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cat = widget.category;
    final all = s.byCategory(cat);
    final shown = s.sorted(sub == 'All' ? all : all.where((i) => i.subtype == sub).toList());

    // Tip: the piece in this category used in the fewest outfits.
    ClothingItem? tipItem;
    for (final i in all) {
      if (tipItem == null || s.outfitCountFor(i.id) < s.outfitCountFor(tipItem.id)) tipItem = i;
    }
    ClothingItem? partner;
    if (tipItem != null) {
      final other = cat == Category.outerwear ? Category.tops : Category.outerwear;
      final l = s.byCategory(other);
      if (l.isNotEmpty) partner = l.first;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
          Row(children: [
            RoundBtn(icon: Icons.chevron_left, onTap: () => Navigator.pop(context)),
            Expanded(
              child: Column(children: [
                Text(cat.label, style: serif(24)),
                Text('${all.length} pieces', style: sans(13, color: C.muted)),
              ]),
            ),
            RoundBtn(icon: Icons.tune_rounded, onTap: () {
              s.setSort((s.sortMode + 1) % sortLabels.length);
            }),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final t in ['All', ...cat.subtypes]) ...[
                Pill(t, selected: sub == t, onTap: () => setState(() => sub = t)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Text('Showing ${shown.length} of ${all.length}', style: sans(14, color: C.muted))),
            GestureDetector(
              onTap: () {
                s.setSort((s.sortMode + 1) % sortLabels.length);
              },
              child: Row(children: [
                Text(sortLabels[s.sortMode], style: sans(14.5, w: FontWeight.w700)),
                const Icon(Icons.keyboard_arrow_down),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: .72,
            children: [
              for (final i in shown)
                ItemCard(i, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: i.id)))),
              _DigitizeTile(cat: cat),
            ],
          ),
          if (tipItem != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: C.sage, borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.lightbulb_outline, color: C.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The ${tipItem.name.toLowerCase()} is in ${s.outfitCountFor(tipItem.id)} of your ${s.outfits.length} outfits.'
                    '${partner != null ? ' Try it with the ${partner.name.toLowerCase()}.' : ''}',
                    style: sans(14, color: C.ink, height: 1.4),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class _DigitizeTile extends StatelessWidget {
  const _DigitizeTile({required this.cat});
  final Category cat;
  @override
  Widget build(BuildContext context) {
    final noun = cat.label.toLowerCase();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddItemScreen(initialCategory: cat))),
      child: CustomPaint(
        painter: _DashedRRect(),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: C.sage, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, color: C.green),
            ),
            const SizedBox(height: 12),
            Text('Digitize a ${noun.endsWith('s') ? noun.substring(0, noun.length - 1) : noun}', style: sans(15, w: FontWeight.w700)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Snap a photo and add it to your wardrobe', textAlign: TextAlign.center, style: sans(12, color: C.muted)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFCBC0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
