import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';
import 'item_detail_screen.dart';
import 'outfit_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int seg = 0;
  Category? cat;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favs = s.favoriteItems;
    final cats =
        Category.values.where((c) => favs.any((i) => i.category == c)).toList();
    final shown = s.sorted(
        cat == null ? favs : favs.where((i) => i.category == cat).toList());
    final outfits = s.favoriteOutfits;

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
                    child: Center(child: Text('Favorites', style: serif(24)))),
                RoundBtn(
                    icon: Icons.sort,
                    onTap: () {
                      s.setSort((s.sortMode + 1) % 4);
                      snack(
                          context,
                          'Sorted by ${const [
                            'recently worn',
                            'most worn',
                            'name',
                            'newest'
                          ][s.sortMode]}');
                    }),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: C.terracotta,
                    borderRadius: BorderRadius.circular(28)),
                child: Row(children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOVED PIECES',
                              style: sans(12, color: Colors.white70)
                                  .copyWith(letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${favs.length}',
                                    style: serif(48, color: Colors.white)),
                                const SizedBox(width: 6),
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('items',
                                        style: serif(22,
                                            color: Colors.white70,
                                            w: FontWeight.w500))),
                              ]),
                          Text('${outfits.length} favorite outfits',
                              style: sans(14, color: Colors.white)),
                        ]),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 34),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: C.line)),
                child: Row(children: [
                  for (final e in ['Items', 'Outfits'].asMap().entries)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => seg = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: seg == e.key ? C.ink : Colors.transparent,
                              borderRadius: BorderRadius.circular(26)),
                          alignment: Alignment.center,
                          child: Text(e.value,
                              style: sans(15,
                                  color: seg == e.key ? Colors.white : C.muted,
                                  w: FontWeight.w600)),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              if (seg == 0) ...[
                SizedBox(
                  height: 44,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    _chip('All', cat == null, () => setState(() => cat = null)),
                    for (final c in cats)
                      _chip(c.label, cat == c, () => setState(() => cat = c)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (shown.isEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                          child: Text(
                              'Tap the heart on a piece to save it here',
                              style: sans(14, color: C.muted))))
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .72,
                    children: [
                      for (final i in shown)
                        ItemCard(i,
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailScreen(itemId: i.id)))),
                    ],
                  ),
              ] else ...[
                if (outfits.isEmpty)
                  Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Center(
                          child: Text('No favorite outfits yet',
                              style: sans(14, color: C.muted))))
                else
                  for (final o in outfits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Panel(
                        radius: 26,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    OutfitDetailScreen(outfitId: o.id))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutfitStrip(s.itemsOf(o), height: 96, emoji: 32),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: Text(o.name,
                                        style: sans(16, w: FontWeight.w700))),
                                HeartBtn(
                                    on: o.favorite,
                                    size: 38,
                                    onTap: () => s.toggleOutfitFavorite(o)),
                              ]),
                            ]),
                      ),
                    ),
              ],
            ]),
      ),
    );
  }

  Widget _chip(String l, bool on, VoidCallback t) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: t,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
                color: on ? C.sage : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: on ? C.sage : C.line)),
            child: Text(l, style: sans(14, color: C.ink)),
          ),
        ),
      );
}
