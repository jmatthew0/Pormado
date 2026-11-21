import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';

class DayPlannerScreen extends StatefulWidget {
  const DayPlannerScreen({super.key, required this.date, this.preset});
  final DateTime date;
  final Outfit? preset;
  @override
  State<DayPlannerScreen> createState() => _DayPlannerScreenState();
}

class _DayPlannerScreenState extends State<DayPlannerScreen> {
  late DateTime date =
      DateTime(widget.date.year, widget.date.month, widget.date.day);
  List<String> pieces = [];
  String occasion = 'Casual';

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    final o = widget.preset ?? s.outfitById(s.plans[dayKey(date)]);
    if (o != null) {
      pieces = [...o.itemIds];
      occasion = o.occasion;
    }
  }

  void _selectDay(DateTime d) {
    final s = context.read<AppState>();
    final o = s.outfitById(s.plans[dayKey(d)]);
    setState(() {
      date = d;
      if (o != null) {
        pieces = [...o.itemIds];
        occasion = o.occasion;
      }
    });
  }

  DayForecast? _forecast(AppState s) {
    for (final d in s.weather?.days ?? const <DayForecast>[]) {
      if (d.date == dayKey(date)) return d;
    }
    return null;
  }

  bool _same(List<String> a, List<String> b) =>
      a.length == b.length && a.toSet().containsAll(b);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fc = _forecast(s);
    final items = pieces.map(s.itemById).whereType<ClothingItem>().toList();
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final rain = (fc?.rain ?? 0) >= 50;
    final hasProof = items.any((i) => i.waterproof);
    final candidates =
        s.items.where((i) => i.waterproof && !pieces.contains(i.id)).toList();
    final suggestion =
        (rain && items.isNotEmpty && !hasProof && candidates.isNotEmpty)
            ? candidates.first
            : null;

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
                    child: Column(children: [
                      Text('Plan a day', style: serif(22)),
                      Text(DateFormat('MMMM yyyy').format(date),
                          style: sans(12.5, color: C.muted)),
                    ]),
                  ),
                  RoundBtn(
                      icon: Icons.calendar_today_outlined,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null)
                          _selectDay(DateTime(d.year, d.month, d.day));
                      }),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Builder(builder: (_) {
                        final d = monday.add(Duration(days: i));
                        final sel = d.year == date.year &&
                            d.month == date.month &&
                            d.day == date.day;
                        return GestureDetector(
                          onTap: () =>
                              _selectDay(DateTime(d.year, d.month, d.day)),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: sel ? C.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(18)),
                            child: Column(children: [
                              Text(DateFormat('E').format(d).substring(0, 1),
                                  style: sans(12,
                                      color: sel ? Colors.white70 : C.muted)),
                              const SizedBox(height: 6),
                              Text('${d.day}',
                                  style: sans(17,
                                      color: sel ? Colors.white : C.ink,
                                      w: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: s.plans.containsKey(dayKey(d))
                                      ? (sel ? Colors.white : C.green)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                    ),
                ]),
                const SizedBox(height: 16),
                Panel(
                  radius: 24,
                  padding: const EdgeInsets.all(18),
                  child: fc == null
                      ? Text('Forecasts are available for the next 7 days.',
                          style: sans(14, color: C.muted))
                      : Row(children: [
                          Icon(iconForCode(fc.code),
                              size: 40, color: colorForCode(fc.code)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(Units.deg(fc.high),
                                            style: serif(30)),
                                        const SizedBox(width: 8),
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text(labelForCode(fc.code),
                                                style:
                                                    sans(14, color: C.muted))),
                                      ]),
                                  const SizedBox(height: 2),
                                  Text(
                                      'Low ${Units.deg(fc.low)} · ${fc.rain}% chance of rain',
                                      style: sans(13, color: C.muted)),
                                ]),
                          ),
                        ]),
                ),
                const SizedBox(height: 22),
                Text('DAY · ${occasion.toUpperCase()}',
                    style: sans(12, color: C.muted).copyWith(letterSpacing: 1)),
                const SizedBox(height: 10),
                Panel(
                  radius: 24,
                  padding: const EdgeInsets.all(12),
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                              'Pick a saved outfit below, or add pieces one by one.',
                              style: sans(14, color: C.muted)),
                        )
                      : Column(children: [
                          for (final e in items.asMap().entries)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: ItemThumb(e.value,
                                        radius: 14, emojiSize: 22)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.value.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                sans(15.5, w: FontWeight.w700)),
                                        Text(e.value.category.label,
                                            style: sans(13, color: C.muted)),
                                      ]),
                                ),
                                RoundBtn(
                                    icon: Icons.sync,
                                    size: 38,
                                    onTap: () async {
                                      final n = await pickItem(context,
                                          exclude: pieces.toSet(),
                                          only: e.value.category);
                                      if (n != null)
                                        setState(() =>
                                            pieces[pieces.indexOf(e.value.id)] =
                                                n.id);
                                    }),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => pieces.remove(e.value.id)),
                                  child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.close,
                                          size: 18, color: C.muted)),
                                ),
                              ]),
                            ),
                        ]),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final i =
                          await pickItem(context, exclude: pieces.toSet());
                      if (i != null) setState(() => pieces.add(i.id));
                    },
                    icon: const Icon(Icons.add, size: 18, color: C.green),
                    label: Text('Add piece',
                        style: sans(14, color: C.green, w: FontWeight.w700)),
                  ),
                ),
                if (suggestion != null) ...[
                  const SizedBox(height: 8),
                  Text('EVENING',
                      style:
                          sans(12, color: C.muted).copyWith(letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: C.sage, borderRadius: BorderRadius.circular(24)),
                    child: Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.umbrella,
                            color: C.green, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add the ${suggestion.name.toLowerCase()}',
                                  style: sans(15, w: FontWeight.w700)),
                              Text('Rain is likely (${fc!.rain}%)',
                                  style: sans(13, color: C.muted)),
                            ]),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => pieces.add(suggestion.id)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 11),
                          decoration: BoxDecoration(
                              color: C.green,
                              borderRadius: BorderRadius.circular(22)),
                          child: Text('Add',
                              style: sans(14,
                                  color: Colors.white, w: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: Text('Choose an outfit', style: serif(22))),
                  Text('Saved', style: sans(13, color: C.muted)),
                ]),
                const SizedBox(height: 12),
                if (s.outfits.isEmpty)
                  Text('No saved outfits yet. Build one in the Outfits tab.',
                      style: sans(14, color: C.muted)),
                for (final o in s.rankedOutfits())
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                      radius: 22,
                      color: _same(o.itemIds, pieces) ? C.sage : Colors.white,
                      onTap: () => setState(() {
                        pieces = [...o.itemIds];
                        occasion = o.occasion;
                      }),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.name,
                                    style: sans(15.5, w: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                    '${o.occasion} · ${o.itemIds.length} pieces · ${s.fitOf(o)}% fit',
                                    style: sans(12.5, color: C.muted)),
                              ]),
                        ),
                        if (_same(o.itemIds, pieces))
                          const Icon(Icons.check_circle, color: C.green),
                      ]),
                    ),
                  ),
              ]),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Btn('Save plan for ${DateFormat('EEEE').format(date)}',
                icon: Icons.check, onTap: () {
              if (pieces.isEmpty) {
                snack(context, 'Pick at least one piece first');
                return;
              }
              s.planPieces(date, pieces, occasion: occasion);
              snack(context,
                  'Planned for ${DateFormat('EEE d MMM').format(date)}');
              Navigator.pop(context);
            }),
          ),
        ]),
      ),
    );
  }
}
