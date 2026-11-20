import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'category_screen.dart';
import 'favorites_screen.dart';
import 'item_detail_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String query = '';
  String filter = 'All';

  void _sortSheet(AppState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sort items by', style: serif(22)),
            const SizedBox(height: 8),
            for (final e in const ['Recently worn', 'Most worn', 'Name', 'Newest'].asMap().entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value, style: sans(16)),
                trailing: s.sortMode == e.key ? const Icon(Icons.check, color: C.green) : null,
                onTap: () {
                  s.setSort(e.key);
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ),
      ),
    );
  }

  List<ClothingItem> _results(AppState s) {
    var l = [...s.items];
    if (filter == 'Recently added') {
      l.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      l = l.take(8).toList();
    } else if (filter == 'In outfits') {
      l = l.where((i) => s.outfitCountFor(i.id) > 0).toList();
      l = s.sorted(l);
    } else {
      l = s.sorted(l);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      l = l
          .where((i) => '${i.name} ${i.colorName} ${i.brand} ${i.material} ${i.category.label}'.toLowerCase().contains(q))
          .toList();
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final searching = query.trim().isNotEmpty || filter != 'All';

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Wardrobe', style: serif(32)),
              const SizedBox(height: 4),
              Text('${s.items.length} pieces, digitized', style: sans(14, color: C.muted)),
            ]),
          ),
          RoundBtn(icon: Icons.more_horiz, size: 48, onTap: () => _sortSheet(s)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: C.line)),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: sans(15),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: C.muted),
                  hintText: 'Search by name, color, brand',
                  hintStyle: sans(15, color: C.muted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          RoundBtn(icon: Icons.tune_rounded, dark: true, size: 52, onTap: () => _sortSheet(s)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            Pill('All', selected: filter == 'All', onTap: () => setState(() => filter = 'All')),
            const SizedBox(width: 8),
            Pill('Favorites',
                icon: const Icon(Icons.favorite, size: 14, color: C.terracotta),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
            const SizedBox(width: 8),
            Pill('Recently added', selected: filter == 'Recently added', onTap: () => setState(() => filter = 'Recently added')),
            const SizedBox(width: 8),
            Pill('In outfits', selected: filter == 'In outfits', onTap: () => setState(() => filter = 'In outfits')),
          ]),
        ),
        const SizedBox(height: 22),
        if (searching) ...[
          Builder(builder: (_) {
            final r = _results(s);
            if (r.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: Text('No matching pieces', style: sans(15, color: C.muted))),
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: .72,
              children: [
                for (final i in r)
                  ItemCard(i, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: i.id)))),
              ],
            );
          }),
        ] else ...[
          Row(children: [
            Expanded(child: Text('Categories', style: serif(22))),
            Text('${Category.values.length} groups', style: sans(13, color: C.muted)),
          ]),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: .98,
            children: [
              for (final c in Category.values)
                Panel(
                  padding: const EdgeInsets.all(12),
                  radius: 24,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: c))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: SizedBox.expand(
                        child: s.byCategory(c).isEmpty
                            ? Container(
                                decoration: BoxDecoration(color: c.tile, borderRadius: BorderRadius.circular(18)),
                                alignment: Alignment.center,
                                child: Text(c.emoji, style: const TextStyle(fontSize: 44)),
                              )
                            : ItemThumb(s.sorted(s.byCategory(c)).first, emojiSize: 48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(c.label, style: sans(17, w: FontWeight.w700)),
                    Text('${s.byCategory(c).length} items', style: sans(12.5, color: C.muted)),
                  ]),
                ),
            ],
          ),
        ],
      ]),
    );
  }
}
