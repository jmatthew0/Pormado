import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 1;
  String query = '';
  static const allStyles = [
    'Minimal',
    'Smart casual',
    'Classic',
    'Streetwear',
    'Boho',
    'Sporty',
    'Romantic',
    'Edgy'
  ];

  Widget _switch(bool v, ValueChanged<bool> on) => Switch(
      value: v,
      activeColor: Colors.white,
      activeTrackColor: C.green,
      onChanged: on);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final matches = query.trim().isEmpty
        ? const <PhCity>[]
        : phCities
            .where((c) =>
                c.name.toLowerCase().contains(query.trim().toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                Row(children: [
                  step == 2
                      ? RoundBtn(
                          icon: Icons.chevron_left,
                          onTap: () => setState(() => step = 1))
                      : const SizedBox(width: 44),
                  Expanded(
                      child: Center(
                          child: Text('Set up Pormado', style: serif(22)))),
                  Text('$step/2', style: sans(14, color: C.muted)),
                ]),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value: step / 2,
                      minHeight: 6,
                      color: C.green,
                      backgroundColor: const Color(0xFFE6E0D4)),
                ),
                const SizedBox(height: 8),
                Text('Takes about a minute. You can change this later.',
                    style: sans(12.5, color: C.muted)),
                const SizedBox(height: 22),
                if (step == 1) ...[
                  Text('What\'s your style?', style: serif(26)),
                  const SizedBox(height: 6),
                  Text('Pick a few. We\'ll save them to your profile.',
                      style: sans(14, color: C.muted)),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    for (final t in allStyles)
                      Pill(t,
                          selected: s.styles.contains(t),
                          onTap: () => s.change(() => s.styles.contains(t)
                              ? s.styles.remove(t)
                              : s.styles.add(t))),
                  ]),
                  const SizedBox(height: 28),
                  Text('Where are you?', style: serif(26)),
                  const SizedBox(height: 6),
                  Text('We use your location to match outfits to the forecast.',
                      style: sans(14, color: C.muted)),
                  const SizedBox(height: 16),
                  Panel(
                    radius: 26,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  color: C.sage,
                                  borderRadius: BorderRadius.circular(14)),
                              child:
                                  const Icon(Icons.my_location, color: C.green),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Use my current location',
                                        style: sans(15, w: FontWeight.w700)),
                                    Text(
                                        'Updates automatically when you travel',
                                        style: sans(12.5, color: C.muted)),
                                  ]),
                            ),
                            _switch(s.useGps, (v) {
                              if (v) {
                                s.useMyLocation();
                              } else {
                                s.change(() => s.useGps = false);
                              }
                            }),
                          ]),
                          const Divider(height: 28, color: C.line),
                          Text('Or enter a city',
                              style: sans(13, color: C.muted)),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                                color: C.bg,
                                borderRadius: BorderRadius.circular(16)),
                            child: TextField(
                              onChanged: (v) => setState(() => query = v),
                              style: sans(15),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: const Icon(Icons.search,
                                    color: C.muted, size: 20),
                                hintText:
                                    s.useGps ? 'e.g. Cebu City' : s.city.name,
                                hintStyle: sans(15, color: C.muted),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          for (final c in matches)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.location_on_outlined,
                                  color: C.green),
                              title: Text(c.name, style: sans(15)),
                              onTap: () {
                                s.setCity(c);
                                setState(() => query = '');
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          if (!s.useGps)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text('Weather location: ${s.city.name}',
                                    style: sans(13,
                                        color: C.green, w: FontWeight.w600))),
                        ]),
                  ),
                ] else ...[
                  Text('Comfort and units', style: serif(26)),
                  const SizedBox(height: 6),
                  Text('Helps us pick outfits that feel right for you.',
                      style: sans(14, color: C.muted)),
                  const SizedBox(height: 18),
                  Text('Temperature', style: sans(15, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Pill('°C',
                        selected: !Units.fahrenheit,
                        onTap: () => s.setFahrenheit(false)),
                    const SizedBox(width: 8),
                    Pill('°F',
                        selected: Units.fahrenheit,
                        onTap: () => s.setFahrenheit(true)),
                  ]),
                  const SizedBox(height: 22),
                  Text('How do you run?', style: sans(15, w: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    for (final e in ['Runs cold', 'Neutral', 'Runs warm']
                        .asMap()
                        .entries)
                      Pill(e.value,
                          selected: s.comfort == e.key,
                          onTap: () => s.change(() => s.comfort = e.key)),
                  ]),
                  const SizedBox(height: 22),
                  Panel(
                    radius: 22,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(children: [
                      Expanded(
                          child: Text('Prefer waterproof pieces when it rains',
                              style: sans(15, w: FontWeight.w600))),
                      _switch(s.preferWaterproof, s.setWaterproof),
                    ]),
                  ),
                ],
              ]),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: step == 1
                ? Btn('Continue',
                    icon: Icons.arrow_forward,
                    onTap: () => setState(() => step = 2))
                : Btn('Get started',
                    icon: Icons.check, onTap: s.finishOnboarding),
          ),
        ]),
      ),
    );
  }
}
