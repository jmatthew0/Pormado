import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final item = s.itemById(itemId);
    if (item == null) return const Scaffold(body: SizedBox());
    final money =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    Widget row(String k, Widget v, {bool last = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: C.line))),
          child: Row(children: [
            Expanded(child: Text(k, style: sans(15, color: C.muted))),
            v,
          ]),
        );

    Widget stat(String v, String l) => Expanded(
          child: Panel(
            radius: 20,
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v, style: serif(24)),
              const SizedBox(height: 4),
              Text(l, style: sans(12, color: C.muted)),
            ]),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                Row(children: [
                  RoundBtn(
                      icon: Icons.chevron_left,
                      onTap: () => Navigator.pop(context)),
                  Expanded(
                      child: Center(
                          child: Text('Item details', style: serif(22)))),
                  HeartBtn(
                      on: item.favorite,
                      size: 44,
                      onTap: () => s.toggleFavorite(item)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                    height: 320,
                    child: ItemThumb(item, radius: 28, emojiSize: 110)),
                const SizedBox(height: 16),
                Text(
                    '${item.category.label.toUpperCase()} · ${item.subtype.toUpperCase()}',
                    style: sans(12, color: C.muted).copyWith(letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(item.name, style: serif(32)),
                const SizedBox(height: 4),
                Text(
                    item.brand.isEmpty
                        ? item.warmthLabel
                        : '${item.brand} · ${item.warmthLabel}',
                    style: sans(15, color: C.muted)),
                const SizedBox(height: 16),
                Row(children: [
                  stat('${item.worn}×', 'Times worn'),
                  const SizedBox(width: 10),
                  stat(item.lastWornLabel, 'Last worn'),
                  const SizedBox(width: 10),
                  stat(item.price == 0 ? '—' : money.format(item.costPerWear),
                      'Cost per wear'),
                ]),
                const SizedBox(height: 16),
                Panel(
                  radius: 24,
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    row(
                        'Color',
                        Row(children: [
                          Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: C.line))),
                          const SizedBox(width: 8),
                          Text(item.colorName,
                              style: sans(15, w: FontWeight.w700)),
                        ])),
                    row(
                        'Material',
                        Flexible(
                            child: Text(item.material,
                                textAlign: TextAlign.right,
                                style: sans(15, w: FontWeight.w700)))),
                    row(
                        'Pattern',
                        Text(item.pattern,
                            style: sans(15, w: FontWeight.w700))),
                    row(
                        'Rain-ready',
                        Text(item.waterproof ? 'Yes' : 'No',
                            style: sans(15, w: FontWeight.w700))),
                    row(
                        'In outfits',
                        Text('${s.outfitCountFor(item.id)}',
                            style: sans(15, w: FontWeight.w700)),
                        last: true),
                  ]),
                ),
                if (s.laundryTracking) ...[
                  const SizedBox(height: 14),
                  Panel(
                    radius: 20,
                    child: Row(children: [
                      Icon(
                          item.wearsSinceWash >= 3
                              ? Icons.local_laundry_service
                              : Icons.check_circle_outline,
                          color: item.wearsSinceWash >= 3
                              ? C.terracotta
                              : C.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.wearsSinceWash >= 3
                              ? 'Worn ${item.wearsSinceWash}× since last wash'
                              : 'Fresh · ${item.wearsSinceWash}× since last wash',
                          style: sans(14),
                        ),
                      ),
                      TextButton(
                          onPressed: () => s.markWashed(item),
                          child: Text('Mark washed',
                              style: sans(13.5,
                                  color: C.green, w: FontWeight.w700))),
                    ]),
                  ),
                ],
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: C.bg,
                          title: Text('Remove ${item.name}?', style: serif(20)),
                          content: const Text(
                              'It will also be removed from your saved outfits.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove')),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        s.deleteItem(item);
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: C.muted, size: 18),
                    label: Text('Remove from wardrobe',
                        style: sans(14, color: C.muted)),
                  ),
                ),
              ]),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Row(children: [
              Expanded(
                flex: 6,
                child: Btn('Add to outfit',
                    icon: Icons.layers_rounded,
                    onTap: () => _addToOutfit(context, s, item)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Btn('Log wear',
                    icon: Icons.event_available,
                    style: BtnStyle.outline, onTap: () {
                  s.logWear(item);
                  snack(context, 'Logged! ${item.name} worn ${item.worn}×');
                }),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _addToOutfit(
      BuildContext context, AppState s, ClothingItem item) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Add to outfit', style: serif(22)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                    backgroundColor: C.green,
                    child: Icon(Icons.add, color: Colors.white)),
                title: Text('Start a new outfit',
                    style: sans(16, w: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, 'new'),
              ),
              for (final o in s.outfits)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.name, style: sans(16)),
                  subtitle: Text('${o.itemIds.length} pieces',
                      style: sans(12.5, color: C.muted)),
                  trailing: o.itemIds.contains(item.id)
                      ? const Icon(Icons.check, color: C.green)
                      : null,
                  onTap: () => Navigator.pop(ctx, o.id),
                ),
            ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'new') {
      s.setDraft([item.id]);
      s.tab.value = 2;
      Navigator.popUntil(context, (r) => r.isFirst);
    } else {
      s.addToOutfit(s.outfitById(choice)!, item);
      snack(context, 'Added to ${s.outfitById(choice)!.name}');
    }
  }
}
