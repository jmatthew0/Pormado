import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';
import 'weather_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final greet = now.hour < 12 ? 'Good morning' : now.hour < 18 ? 'Good afternoon' : 'Good evening';
    final w = s.weather;
    final outfit = s.todaysOutfit;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: C.green,
        onRefresh: s.loadWeather,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('EEEE, d MMMM').format(now), style: sans(14, color: C.muted)),
                const SizedBox(height: 6),
                Text('$greet,\n${s.userName}', style: serif(32)),
              ]),
            ),
            RoundBtn(icon: Icons.notifications_none_rounded, onTap: () => snack(context, 'No new notifications')),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: C.terracotta,
              child: Text(s.userName.isEmpty ? '?' : s.userName[0], style: serif(20, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 20),

          // Weather card
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeatherScreen())),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(28)),
              child: w == null
                  ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(color: Colors.white)))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('TODAY · ${w.city.toUpperCase()}',
                                style: sans(12, color: Colors.white70, w: FontWeight.w500).copyWith(letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text('${w.temp}°', style: serif(64, color: Colors.white, w: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(w.summary, style: sans(14, color: Colors.white70)),
                          ]),
                        ),
                        Icon(iconForCode(w.code), size: 56, color: const Color(0xFFE0AE4F)),
                      ]),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(w.tip, style: sans(14.5, color: Colors.white))),
                          const Icon(Icons.chevron_right, color: Colors.white70),
                        ]),
                      ),
                    ]),
            ),
          ),
          const SizedBox(height: 18),

          // Today's outfit
          Panel(
            padding: const EdgeInsets.all(18),
            radius: 28,
            child: outfit == null
                ? Text('Create an outfit to get a daily pick.', style: sans(14, color: C.muted))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Today\'s outfit', style: serif(22))),
                      Tag(s.todayIsPlanned ? 'Planned' : 'Auto-picked'),
                    ]),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: C.sand, borderRadius: BorderRadius.circular(22)),
                      child: OutfitStrip(s.itemsOf(outfit), height: 170, emoji: 44),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(outfit.name, style: sans(18, w: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(
                            '${outfit.occasion} · ${outfit.itemIds.length} pieces · ${s.fitOf(outfit)}% fit${w == null ? '' : ' for ${w.temp}°'}',
                            style: sans(13, color: C.muted),
                          ),
                        ]),
                      ),
                      HeartBtn(on: outfit.favorite, size: 44, onTap: () => s.toggleOutfitFavorite(outfit)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: Btn('Wear this', icon: Icons.check, style: BtnStyle.dark, onTap: () {
                          final ok = s.markWorn(DateTime.now(), outfit);
                          snack(context, ok ? 'Logged! Enjoy your day 🌿' : 'You already logged today\'s outfit');
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Btn('Shuffle', icon: Icons.shuffle, style: BtnStyle.outline, onTap: s.shuffleToday)),
                    ]),
                  ]),
          ),
        ]),
      ),
    );
  }
}
