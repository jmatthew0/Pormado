import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';
import 'day_planner_screen.dart';

class OutfitDetailScreen extends StatelessWidget {
  const OutfitDetailScreen({super.key, required this.outfitId});
  final String outfitId;

  Widget _chip(String t, {bool filled = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? C.sage : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: filled ? null : Border.all(color: C.line),
        ),
        child: Text(t,
            style:
                sans(13, color: filled ? C.green : C.ink, w: FontWeight.w600)),
      );

  Widget _stat(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: serif(24)),
          const SizedBox(height: 4),
          Text(l, style: sans(12.5, color: C.muted)),
        ]),
      );

  String _range(double avgWarmth) {
    const r = [
      [28, 36],
      [25, 30],
      [21, 26],
      [14, 22]
    ];
    final x = r[avgWarmth.round().clamp(0, 3)];
    return '${Units.conv(x[0])}–${Units.deg(x[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = s.outfitById(outfitId);
    if (o == null) return const Scaffold(body: SizedBox());
    final items = s.itemsOf(o);
    final avg = items.isEmpty
        ? 1.0
        : items.map((e) => e.warmth).reduce((a, b) => a + b) / items.length;
    final proof = items.any((i) => i.waterproof);

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
                    child:
                        Center(child: Text('Saved outfit', style: serif(22)))),
                HeartBtn(
                    on: o.favorite,
                    size: 44,
                    onTap: () => s.toggleOutfitFavorite(o)),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                decoration: BoxDecoration(
                    color: C.sand, borderRadius: BorderRadius.circular(28)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(o.occasion,
                            style: sans(12.5, w: FontWeight.w600)),
                      ),
                      const SizedBox(height: 14),
                      OutfitStrip(items, height: 170, emoji: 44),
                    ]),
              ),
              const SizedBox(height: 18),
              Text(o.name, style: serif(30)),
              const SizedBox(height: 6),
              Text(
                  'Built from your closet · Created ${DateFormat('d MMM').format(o.createdAt)}',
                  style: sans(14, color: C.muted)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _chip(o.occasion, filled: true),
                _chip(_range(avg)),
                _chip(proof ? 'Rain-ready' : 'Dry weather'),
              ]),
              const SizedBox(height: 18),
              Panel(
                radius: 24,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: IntrinsicHeight(
                  child: Row(children: [
                    _stat('${o.worn}×', 'Times worn'),
                    const VerticalDivider(color: C.line, width: 1),
                    _stat(o.lastWornLabel, 'Last worn'),
                    const VerticalDivider(color: C.line, width: 1),
                    _stat('${s.fitOf(o)}%', 'Fit score'),
                  ]),
                ),
              ),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text('Pieces', style: serif(22))),
                Text('${items.length} items', style: sans(13, color: C.muted)),
              ]),
              const SizedBox(height: 12),
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Panel(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(children: [
                      SizedBox(
                          width: 56,
                          height: 56,
                          child: ItemThumb(i, radius: 14, emojiSize: 24)),
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
                              Text('${i.category.label} · ${i.colorName}',
                                  style: sans(13, color: C.muted)),
                            ]),
                      ),
                      TextButton(
                        onPressed: () async {
                          final n = await pickItem(context,
                              exclude: o.itemIds.toSet(), only: i.category);
                          if (n != null) s.swapPiece(o, i.id, n.id);
                        },
                        child: Text('Swap',
                            style:
                                sans(14, color: C.green, w: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Btn('Wear today',
                      icon: Icons.check, style: BtnStyle.dark, onTap: () {
                    final ok = s.markWorn(DateTime.now(), o);
                    snack(context,
                        ok ? 'Logged for today' : 'Today is already logged');
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Btn('Plan a day',
                      icon: Icons.event, style: BtnStyle.outline, onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DayPlannerScreen(
                                date: DateTime.now(), preset: o)));
                  }),
                ),
              ]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(
                  onPressed: () {
                    s.setDraft([...o.itemIds]);
                    s.setOccasion(o.occasion);
                    s.tab.value = 2;
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                  child: Text('Edit in builder',
                      style: sans(14, color: C.green, w: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () {
                    s.deleteOutfit(o);
                    Navigator.pop(context);
                  },
                  child: Text('Delete', style: sans(14, color: C.muted)),
                ),
              ]),
            ]),
      ),
    );
  }
}
