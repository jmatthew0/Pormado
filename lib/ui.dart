import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'state.dart';

class C {
  static const bg = Color(0xFFF3F1EC);
  static const green = Color(0xFF455C4D);
  static const ink = Color(0xFF1F1F22);
  static const muted = Color(0xFF77746C);
  static const line = Color(0xFFE6E2D9);
  static const terracotta = Color(0xFFC17F63);
  static const sage = Color(0xFFDCE5DC);
  static const sand = Color(0xFFEFEAE1);
}

TextStyle serif(double size,
        {Color color = C.ink, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.fraunces(
        fontSize: size, fontWeight: w, color: color, height: 1.1);

TextStyle sans(double size,
        {Color color = C.ink,
        FontWeight w = FontWeight.w500,
        double? height}) =>
    GoogleFonts.inter(
        fontSize: size, color: color, fontWeight: w, height: height);

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, style: sans(14, color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.onTap,
    this.radius = 24,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
          color: color, borderRadius: r, border: Border.all(color: C.line)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class RoundBtn extends StatelessWidget {
  const RoundBtn(
      {super.key,
      required this.icon,
      this.onTap,
      this.dark = false,
      this.size = 44});
  final IconData icon;
  final VoidCallback? onTap;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? C.ink : Colors.white,
      shape: CircleBorder(side: BorderSide(color: dark ? C.ink : C.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: dark ? Colors.white : C.ink)),
      ),
    );
  }
}

enum BtnStyle { green, dark, outline }

class Btn extends StatelessWidget {
  const Btn(this.label,
      {super.key, this.icon, this.onTap, this.style = BtnStyle.green});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final BtnStyle style;

  @override
  Widget build(BuildContext context) {
    final bg = switch (style) {
      BtnStyle.green => C.green,
      BtnStyle.dark => C.ink,
      BtnStyle.outline => Colors.white
    };
    final fg = style == BtnStyle.outline ? C.ink : Colors.white;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(27),
        border: style == BtnStyle.outline ? Border.all(color: C.line) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: onTap,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8)
            ],
            Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: sans(16, color: fg, w: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label,
      {super.key, this.selected = false, this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? C.ink : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? C.ink : C.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(label, style: sans(14, color: selected ? Colors.white : C.ink)),
        ]),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.label,
      {super.key, this.bg = C.sage, this.fg = C.green, this.icon});
  final String label;
  final Color bg, fg;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5)
          ],
          Text(label, style: sans(12.5, color: fg, w: FontWeight.w600)),
        ]),
      );
}

class ItemThumb extends StatelessWidget {
  const ItemThumb(this.item,
      {super.key, this.radius = 18, this.emojiSize = 52});
  final ClothingItem item;
  final double radius;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final b = item.imageBytes;
    final Widget child = b == null
        ? Text(item.emoji, style: TextStyle(fontSize: emojiSize))
        : Image.memory(b, fit: BoxFit.contain, gaplessPlayback: true);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: item.tile,
        alignment: Alignment.center,
        padding: b == null ? EdgeInsets.zero : const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
}

class HeartBtn extends StatelessWidget {
  const HeartBtn(
      {super.key, required this.on, required this.onTap, this.size = 34});
  final bool on;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(on ? Icons.favorite : Icons.favorite_border,
              size: size * .52, color: on ? C.terracotta : C.muted),
        ),
      );
}

class ItemCard extends StatelessWidget {
  const ItemCard(this.item, {super.key, this.onTap});
  final ClothingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return Panel(
      padding: const EdgeInsets.all(10),
      radius: 22,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            ItemThumb(item),
            Positioned(
                top: 8,
                right: 8,
                child: HeartBtn(
                    on: item.favorite, onTap: () => s.toggleFavorite(item))),
          ]),
        ),
        const SizedBox(height: 10),
        Text(item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: sans(15, w: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
                border: Border.all(color: C.line)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text('${item.colorName} · ${item.materialShort}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sans(12, color: C.muted)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Worn ${item.worn}×', style: sans(12, color: C.muted)),
      ]),
    );
  }
}

/// Row of thumbnails for an outfit.
class OutfitStrip extends StatelessWidget {
  const OutfitStrip(this.items,
      {super.key, this.height = 100, this.emoji = 34});
  final List<ClothingItem> items;
  final double height;
  final double emoji;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: ItemThumb(items[i], radius: 16, emojiSize: emoji)),
          ],
        ]),
      );
}

/// Bottom sheet that lets the person pick a saved outfit.
Future<Outfit?> pickOutfit(BuildContext context,
    {String title = 'Choose an outfit'}) {
  final s = context.read<AppState>();
  return showModalBottomSheet<Outfit>(
    context: context,
    backgroundColor: C.bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .9,
      builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Text(title, style: serif(24)),
            const SizedBox(height: 14),
            if (s.outfits.isEmpty)
              Text('No saved outfits yet. Build one in the Outfits tab.',
                  style: sans(14, color: C.muted)),
            for (final o in s.rankedOutfits())
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  onTap: () => Navigator.pop(ctx, o),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutfitStrip(s.itemsOf(o), height: 70, emoji: 26),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: Text(o.name,
                                  style: sans(15, w: FontWeight.w700))),
                          Tag('${s.fitOf(o)}% fit'),
                        ]),
                      ]),
                ),
              ),
          ]),
    ),
  );
}

/// Bottom sheet to pick a single wardrobe piece.
Future<ClothingItem?> pickItem(BuildContext context,
    {Set<String> exclude = const {}}) {
  final s = context.read<AppState>();
  return showModalBottomSheet<ClothingItem>(
    context: context,
    backgroundColor: C.bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .92,
      builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Add a piece', style: serif(24)),
            for (final c in Category.values)
              if (s.byCategory(c).any((i) => !exclude.contains(i.id))) ...[
                const SizedBox(height: 16),
                Text(c.label,
                    style: sans(14, color: C.muted, w: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final i
                      in s.byCategory(c).where((i) => !exclude.contains(i.id)))
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, i),
                      child: SizedBox(
                        width: 92,
                        child: Column(children: [
                          SizedBox(
                              width: 92,
                              height: 92,
                              child: ItemThumb(i, emojiSize: 36)),
                          const SizedBox(height: 4),
                          Text(i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: sans(12)),
                        ]),
                      ),
                    ),
                ]),
              ],
          ]),
    ),
  );
}
