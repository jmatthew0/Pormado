import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

const _sorts = [
  'Recently worn',
  'Most worn',
  'Warmest first',
  'Name',
  'Newest'
];

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});
  final Category category;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String sub = 'All';
  late String sort =
      widget.category == Category.outerwear ? 'Warmest first' : 'Recently worn';

  List<ClothingItem> _sorted(List<ClothingItem> l) {
    final c = [...l];
    final old = DateTime(2000);
    switch (sort) {
      case 'Most worn':
        c.sort((a, b) => b.worn.compareTo(a.worn));
      case 'Warmest first':
        c.sort((a, b) => b.warmth.compareTo(a.warmth));
      case 'Name':
        c.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 'Newest':
        c.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      default:
        c.sort((a, b) => (b.lastWorn ?? old).compareTo(a.lastWorn ?? old));
    }
    return c;
  }

  String _unit(Category c, int n) => switch (c) {
        Category.shoes => n == 1 ? 'pair' : 'pairs',
        Category.bags => n == 1 ? 'bag' : 'bags',
        Category.accessories => n == 1 ? 'item' : 'items',
        _ => n == 1 ? 'piece' : 'pieces',
      };

  (String, String) _digitize(Category c) => switch (c) {
        Category.outerwear => (
            'Digitize an outer layer',
            'Coats, jackets and blazers'
          ),
        Category.shoes => (
            'Digitize a pair',
            'Photograph one shoe, we handle the rest'
          ),
        Category.accessories => (
            'Digitize an accessory',
            'Jewelry, belts, eyewear and more'
          ),
        Category.tops => (
            'Digitize a top',
            'Snap a photo, we remove the background'
          ),
        Category.bottoms => (
            'Digitize a bottom',
            'Snap a photo, we remove the background'
          ),
        Category.bags => (
            'Digitize a bag',
            'Snap a photo, we remove the background'
          ),
        Category.dresses => (
            'Digitize a dress',
            'Snap a photo, we remove the background'
          ),
      };

  void _openSort() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Sort by', style: serif(22)),
              for (final o in _sorts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o, style: sans(16)),
                  trailing: o == sort
                      ? const Icon(Icons.check, color: C.green)
                      : null,
                  onTap: () {
                    setState(() => sort = o);
                    Navigator.pop(ctx);
                  },
                ),
            ]),
      ),
    );
  }

  void _open(ClothingItem i) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: i.id)));
  void _add() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddItemScreen(initialCategory: widget.category)));

  Widget _tipCard(
          {required IconData icon,
          String? title,
          required String body,
          bool white = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white ? Colors.white : C.sage,
          borderRadius: BorderRadius.circular(24),
          border: white ? Border.all(color: C.line) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: white ? const Color(0xFFF7EBDD) : Colors.white,
                shape: BoxShape.circle),
            child: Icon(icon,
                color: white ? const Color(0xFFB0661E) : C.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) ...[
                Text(title, style: sans(15, w: FontWeight.w700)),
                const SizedBox(height: 4)
              ],
              Text(body,
                  style: sans(14, color: white ? C.muted : C.ink, height: 1.4)),
            ]),
          ),
        ]),
      );

  Widget? _tip(AppState s, List<ClothingItem> all) {
    if (all.isEmpty) return null;
    final cat = widget.category;
    final byWorn = [...all]..sort((a, b) => b.worn.compareTo(a.worn));
    if (cat == Category.outerwear) {
      final w = s.weather;
      final wp = all.where((i) => i.waterproof).toList();
      if (w != null && w.rainy && wp.isNotEmpty) {
        final it = wp.first;
        final n = s
            .rankedOutfits()
            .take(5)
            .where((o) => o.itemIds.contains(it.id))
            .length;
        return _tipCard(
          icon: Icons.umbrella,
          white: true,
          title: 'Rain expected after ${w.rainHour}',
          body:
              'The ${it.name.toLowerCase()} is water-resistant and matches $n of tonight\'s suggested looks.',
        );
      }
      return null;
    }
    if (cat == Category.shoes) {
      if (all.length < 2 || byWorn.first.worn == byWorn.last.worn) return null;
      return _tipCard(
        icon: Icons.directions_walk,
        body:
            'Your ${byWorn.first.name.toLowerCase()} are your most-worn pair (${byWorn.first.worn}×). '
            'Rotate in the ${byWorn.last.name.toLowerCase()} on dry days to keep wear even.',
      );
    }
    if (cat == Category.bags) {
      final unused = all.where((i) => i.worn == 0).toList();
      if (unused.isEmpty) return null;
      return _tipCard(
        icon: Icons.shopping_bag_outlined,
        white: true,
        title: 'Your ${unused.first.name.toLowerCase()} is unused',
        body: 'Not worn yet. Try it with an outfit this week.',
      );
    }
    if (cat == Category.dresses) {
      final shoes = s.byCategory(Category.shoes);
      return _tipCard(
        icon: Icons.star_outline,
        body: 'The ${byWorn.first.name.toLowerCase()} is your most-worn piece.'
            '${shoes.isNotEmpty ? ' Pair it with the ${shoes.first.name.toLowerCase()} for a relaxed look.' : ''}',
      );
    }
    if (cat == Category.accessories || s.outfits.isEmpty) return null;
    var least = all.first;
    for (final i in all) {
      if (s.outfitCountFor(i.id) < s.outfitCountFor(least.id)) least = i;
    }
    final other =
        cat == Category.outerwear ? Category.tops : Category.outerwear;
    final partner = s.byCategory(other);
    return _tipCard(
      icon: Icons.lightbulb_outline,
      body:
          'The ${least.name.toLowerCase()} is in ${s.outfitCountFor(least.id)} of your ${s.outfits.length} outfits.'
          '${partner.isNotEmpty ? ' Try it with the ${partner.first.name.toLowerCase()}.' : ''}',
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: serif(26)),
          const SizedBox(height: 4),
          Text(l, style: sans(12.5, color: C.muted)),
        ]),
      );

  Widget _row(ClothingItem i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          radius: 22,
          padding: const EdgeInsets.all(12),
          onTap: () => _open(i),
          child: Row(children: [
            SizedBox(
                width: 58,
                height: 58,
                child: ItemThumb(i, radius: 16, emojiSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(15.5, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        '${i.subtype} · ${i.worn == 0 ? 'Not worn yet' : 'Worn ${i.worn}×'}',
                        style: sans(13, color: C.muted)),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: C.muted),
          ]),
        ),
      );

  Widget _wide() {
    final (t, sub) = _digitize(widget.category);
    return GestureDetector(
      onTap: _add,
      child: CustomPaint(
        painter: _DashedRRect(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: C.sage, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.photo_camera, color: C.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: sans(15.5, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(sub, style: sans(13, color: C.muted)),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tile() {
    final (t, sub) = _digitize(widget.category);
    return GestureDetector(
      onTap: _add,
      child: CustomPaint(
        painter: _DashedRRect(),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration:
                  const BoxDecoration(color: C.sage, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, color: C.green),
            ),
            const SizedBox(height: 12),
            Text(t, style: sans(15, w: FontWeight.w700)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(sub,
                  textAlign: TextAlign.center, style: sans(12, color: C.muted)),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cat = widget.category;
    final all = s.byCategory(cat);
    final shown = _sorted(
        sub == 'All' ? all : all.where((i) => i.subtype == sub).toList());
    final listMode = cat == Category.accessories || s.defaultView == 'List';
    final wide = cat == Category.outerwear ||
        cat == Category.shoes ||
        cat == Category.accessories;
    final tip = _tip(s, all);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Row(children: [
                RoundBtn(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.pop(context)),
                Expanded(
                  child: Column(children: [
                    Text(cat.label, style: serif(24)),
                    Text('${all.length} ${_unit(cat, all.length)}',
                        style: sans(13, color: C.muted)),
                  ]),
                ),
                RoundBtn(icon: Icons.tune_rounded, onTap: _openSort),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final t in ['All', ...cat.subtypes]) ...[
                    Pill(t,
                        selected: sub == t,
                        onTap: () => setState(() => sub = t)),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              if (cat == Category.bags && all.isNotEmpty) ...[
                Panel(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: IntrinsicHeight(
                    child: Row(children: [
                      _stat('${all.length}', 'Bags'),
                      const VerticalDivider(color: C.line, width: 1),
                      _stat('${all.where((i) => i.favorite).length}',
                          'Favorites'),
                      const VerticalDivider(color: C.line, width: 1),
                      _stat(
                          '${all.where((i) => i.worn == 0).length}', 'Unworn'),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(children: [
                Expanded(
                    child: Text('Showing ${shown.length} of ${all.length}',
                        style: sans(14, color: C.muted))),
                GestureDetector(
                  onTap: _openSort,
                  child: Row(children: [
                    Text(sort, style: sans(14.5, w: FontWeight.w700)),
                    const Icon(Icons.keyboard_arrow_down),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              if (listMode) ...[
                for (final i in shown) _row(i),
                _wide(),
              ] else ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .72,
                  children: [
                    for (final i in shown) ItemCard(i, onTap: () => _open(i)),
                    if (!wide) _tile(),
                  ],
                ),
                if (wide) ...[const SizedBox(height: 14), _wide()],
              ],
              if (tip != null) ...[const SizedBox(height: 18), tip],
            ]),
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
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(22)));
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
