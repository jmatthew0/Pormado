import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import 'add_item_screen.dart';
import '../state.dart';
import '../ui.dart';

const occasions = [
  'Casual',
  'Weekend brunch',
  'Work',
  'Date night',
  'Errands',
  'Beach'
];

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});
  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  int seg = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SafeArea(
      bottom: false,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outfits', style: serif(32)),
                      const SizedBox(height: 4),
                      Text('Build combinations from your closet',
                          style: sans(14, color: C.muted)),
                    ]),
              ),
              RoundBtn(
                  icon: Icons.add,
                  dark: true,
                  size: 48,
                  onTap: () {
                    s.setDraft([]);
                    setState(() => seg = 0);
                  }),
            ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: C.line)),
              child: Row(children: [
                for (final e in ['Create', 'Saved (${s.outfits.length})']
                    .asMap()
                    .entries)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => seg = e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
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
            const SizedBox(height: 18),
            if (seg == 0) _builder(context, s) else _saved(context, s),
          ]),
    );
  }

  Widget _builder(BuildContext context, AppState s) {
    final pieces = s.draft.map(s.itemById).whereType<ClothingItem>().toList();
    final fit = s.fit(pieces);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Panel(
        radius: 28,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            if (pieces.isNotEmpty)
              Tag('Smart fit $fit%', icon: Icons.star_rounded),
            const Spacer(),
            RoundBtn(icon: Icons.shuffle, size: 40, onTap: s.shuffleDraft),
          ]),
          const SizedBox(height: 10),
          if (pieces.isEmpty)
            SizedBox(
              height: 230,
              child: Center(
                child: s.items.isEmpty
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Your wardrobe is empty', style: serif(20)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                              'Digitize a few pieces first, then Pormado can mix outfits for you.',
                              textAlign: TextAlign.center,
                              style: sans(13.5, color: C.muted, height: 1.4)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 200,
                          child: Btn('Add a piece',
                              icon: Icons.add_a_photo_outlined,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AddItemScreen()))),
                        ),
                      ])
                    : Text('Tap Add piece or Shuffle to start',
                        style: sans(14, color: C.muted)),
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final p in pieces)
                  SizedBox(
                      width: pieces.length <= 3 ? 100 : 90,
                      height: pieces.length <= 3 ? 130 : 110,
                      child: ItemThumb(p, emojiSize: 40)),
              ],
            ),
          const SizedBox(height: 10),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
            child: Text('Layers · ${pieces.length} pieces',
                style: sans(16, w: FontWeight.w700))),
        GestureDetector(
          onTap: () async {
            final o = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: C.bg,
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28))),
              builder: (ctx) => SafeArea(
                child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('Occasion', style: serif(22)),
                      for (final o in occasions)
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(o, style: sans(16)),
                            onTap: () => Navigator.pop(ctx, o)),
                    ]),
              ),
            );
            if (o != null) s.setOccasion(o);
          },
          child: Text('Occasion: ${s.draftOccasion}',
              style: sans(13.5, color: C.muted)),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in pieces)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: C.line)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(p.name, style: sans(14)),
              const SizedBox(width: 6),
              GestureDetector(
                  onTap: () => s.removeFromDraft(p.id),
                  child: const Icon(Icons.close, size: 16, color: C.muted)),
            ]),
          ),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          flex: 4,
          child: Btn('Add piece', icon: Icons.add, style: BtnStyle.outline,
              onTap: () async {
            final i = await pickItem(context, exclude: s.draft.toSet());
            if (i != null) s.addToDraft(i.id);
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Btn('Save outfit', icon: Icons.check, onTap: () {
            if (pieces.length < 2) {
              snack(context, 'Add at least two pieces first');
              return;
            }
            s.saveDraft();
            snack(context, 'Outfit saved');
          }),
        ),
      ]),
    ]);
  }

  Widget _saved(BuildContext context, AppState s) {
    if (s.outfits.isEmpty) {
      return Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
              child: Text('No saved outfits yet',
                  style: sans(15, color: C.muted))));
    }
    return Column(children: [
      for (final o in s.outfits)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Panel(
            radius: 26,
            onTap: () => _actions(context, s, o),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              OutfitStrip(s.itemsOf(o), height: 96, emoji: 32),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.name, style: sans(16, w: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('${o.occasion} · ${o.itemIds.length} pieces',
                            style: sans(12.5, color: C.muted)),
                      ]),
                ),
                Tag('${s.fitOf(o)}% fit'),
                const SizedBox(width: 8),
                HeartBtn(
                    on: o.favorite,
                    size: 38,
                    onTap: () => s.toggleOutfitFavorite(o)),
              ]),
            ]),
          ),
        ),
    ]);
  }

  void _actions(BuildContext context, AppState s, Outfit o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.name, style: serif(22)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Wear today'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final ok = s.markWorn(DateTime.now(), o);
                    snack(context,
                        ok ? 'Logged for today' : 'Today is already logged');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Plan for a day'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      s.plan(d, o);
                      if (context.mounted)
                        snack(context, 'Planned in your calendar');
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit in builder'),
                  onTap: () {
                    Navigator.pop(ctx);
                    s.setDraft([...o.itemIds]);
                    s.setOccasion(o.occasion);
                    setState(() => seg = 0);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(ctx);
                    s.deleteOutfit(o);
                  },
                ),
              ]),
        ),
      ),
    );
  }
}
