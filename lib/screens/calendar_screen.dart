import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../ui.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime selected = DateTime.now();

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = DateTime.now();
    final lead = (DateTime(month.year, month.month, 1).weekday + 6) % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final selKey = dayKey(selected);
    final outfit = s.outfitById(s.plans[selKey]);
    final isToday = _same(selected, today);
    final worn = s.wornDays.contains(selKey);

    Widget cell(int d) {
      final date = DateTime(month.year, month.month, d);
      final k = dayKey(date);
      final sel = _same(date, selected);
      final tod = _same(date, today);
      final planned = s.plans.containsKey(k) && !s.wornDays.contains(k);
      final wornD = s.wornDays.contains(k);
      return GestureDetector(
        onTap: () => setState(() => selected = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: sel ? C.green : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: sans(16, color: sel ? Colors.white : C.ink, w: tod ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (planned) Container(width: 5, height: 5, decoration: BoxDecoration(color: sel ? Colors.white : C.green, shape: BoxShape.circle)),
                if (wornD) Container(width: 5, height: 5, decoration: const BoxDecoration(color: C.terracotta, shape: BoxShape.circle)),
                if (tod && !planned && !wornD) Container(width: 5, height: 5, decoration: BoxDecoration(color: sel ? Colors.white : C.ink, shape: BoxShape.circle)),
              ]),
            ),
          ]),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Outfit calendar', style: serif(30)),
              const SizedBox(height: 4),
              Text('Plan looks before you open your closet', style: sans(14, color: C.muted)),
            ]),
          ),
          RoundBtn(icon: Icons.add, dark: true, size: 48, onTap: () => _plan(context, s)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          RoundBtn(icon: Icons.chevron_left, onTap: () => setState(() => month = DateTime(month.year, month.month - 1))),
          Text(DateFormat('MMMM yyyy').format(month), style: serif(22)),
          RoundBtn(icon: Icons.chevron_right, onTap: () => setState(() => month = DateTime(month.year, month.month + 1))),
        ]),
        const SizedBox(height: 14),
        Panel(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
          child: Column(children: [
            Row(children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(child: Center(child: Text(d, style: sans(12.5, color: C.muted)))),
            ]),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: .85,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox(),
                for (var d = 1; d <= days; d++) cell(d),
              ],
            ),
            const Divider(color: C.line),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final e in [(C.green, 'Planned'), (C.terracotta, 'Worn'), (C.ink, 'Today')]) ...[
                Container(width: 8, height: 8, decoration: BoxDecoration(color: e.$1, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(e.$2, style: sans(12.5, color: C.muted)),
                const SizedBox(width: 18),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Panel(
          radius: 28,
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${DateFormat('EEEE d').format(selected).toUpperCase()}${isToday ? ' · TODAY' : ''}',
                    style: sans(12.5, color: C.green, w: FontWeight.w700).copyWith(letterSpacing: .8)),
              ),
              if (isToday && s.weather != null) Tag('${s.weather!.temp}°', bg: const Color(0xFFF7EBDD), fg: const Color(0xFFB0661E)),
            ]),
            const SizedBox(height: 8),
            if (outfit == null) ...[
              Text('Nothing planned', style: serif(22)),
              const SizedBox(height: 14),
              Btn('Plan an outfit', icon: Icons.add, onTap: () => _plan(context, s)),
            ] else ...[
              Text(outfit.name, style: serif(22)),
              const SizedBox(height: 12),
              OutfitStrip(s.itemsOf(outfit), height: 100, emoji: 34),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: worn
                      ? Btn('Worn', icon: Icons.check_circle, style: BtnStyle.outline, onTap: () {})
                      : Btn('Mark as worn', icon: Icons.check, style: BtnStyle.dark, onTap: () {
                          if (selected.isAfter(DateTime(today.year, today.month, today.day, 23, 59))) {
                            snack(context, 'You can mark it worn on the day');
                            return;
                          }
                          s.markWorn(selected, outfit);
                        }),
                ),
                const SizedBox(width: 10),
                Expanded(child: Btn('Change', icon: Icons.swap_horiz, style: BtnStyle.outline, onTap: () => _plan(context, s))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Future<void> _plan(BuildContext context, AppState s) async {
    final o = await pickOutfit(context, title: 'Plan ${DateFormat('EEE d MMM').format(selected)}');
    if (o != null) s.plan(selected, o);
  }
}
