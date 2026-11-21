import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final w = s.weather;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: w == null
            ? const Center(child: CircularProgressIndicator(color: C.green))
            : RefreshIndicator(
                color: C.green,
                onRefresh: s.loadWeather,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      Row(children: [
                        RoundBtn(
                            icon: Icons.chevron_left,
                            onTap: () => Navigator.pop(context)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _cityPicker(context, s),
                            child: Column(children: [
                              Text('Weather outfits', style: serif(22)),
                              const SizedBox(height: 3),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 13, color: C.muted),
                                    Text(
                                        ' ${w.city} · Updated ${DateFormat('h:mm').format(w.updated)}',
                                        style: sans(12.5, color: C.muted)),
                                    const Icon(Icons.arrow_drop_down,
                                        size: 16, color: C.muted),
                                  ]),
                            ]),
                          ),
                        ),
                        RoundBtn(icon: Icons.refresh, onTap: s.loadWeather),
                      ]),
                      if (s.useGps && s.locationDenied) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Location is off, so showing ${s.city.name}. Turn it on in Settings to get your local weather.',
                            textAlign: TextAlign.center,
                            style: sans(12.5, color: C.terracotta)),
                      ],
                      if (w.offline) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Offline – showing typical conditions. Pull to retry.',
                            textAlign: TextAlign.center,
                            style: sans(12.5, color: C.terracotta)),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                              colors: [Color(0xFF4C6555), Color(0xFF34473C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                        child: Column(children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(Units.deg(w.temp),
                                            style: serif(72,
                                                color: Colors.white,
                                                w: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Text(
                                            '${w.condition} · Feels like ${Units.deg(w.feels)}',
                                            style:
                                                sans(15, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'H ${Units.deg(w.high)} · L ${Units.deg(w.low)}',
                                            style: sans(13,
                                                color: Colors.white70)),
                                      ]),
                                ),
                                Icon(iconForCode(w.code),
                                    size: 64, color: const Color(0xFFE0AE4F)),
                              ]),
                          const SizedBox(height: 26),
                          Row(children: [
                            _stat(Icons.water_drop_outlined, '${w.humidity}%',
                                'Humidity'),
                            _stat(Icons.air, '${w.wind} km/h', 'Wind'),
                            _stat(Icons.grain, '${w.rainMax}%',
                                'Rain ${w.rainHour}'),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 22),
                      Row(children: [
                        Expanded(
                            child: Text('Today by hour', style: serif(22))),
                        Text('Next 12h', style: sans(13, color: C.muted)),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 118,
                        child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final h in w.hours)
                                Container(
                                  width: 78,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: h.rain >= 50 ? C.sage : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: h.rain >= 50
                                            ? const Color(0xFFB9CBBB)
                                            : C.line),
                                  ),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(h.label,
                                            style: sans(13, color: C.muted)),
                                        const SizedBox(height: 8),
                                        Icon(iconForCode(h.code),
                                            color: colorForCode(h.code),
                                            size: 26),
                                        const SizedBox(height: 8),
                                        Text(Units.deg(h.temp),
                                            style:
                                                sans(17, w: FontWeight.w700)),
                                      ]),
                                ),
                            ]),
                      ),
                      const SizedBox(height: 18),
                      Panel(
                        radius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF7EBDD),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Icon(
                                    w.rainy
                                        ? Icons.umbrella
                                        : Icons.wb_sunny_outlined,
                                    color: const Color(0xFFB0661E)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(w.adviceTitle,
                                          style: sans(16, w: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      Text(w.adviceBody,
                                          style: sans(14,
                                              color: C.muted, height: 1.45)),
                                    ]),
                              ),
                            ]),
                      ),
                      const SizedBox(height: 14),
                      Panel(
                        radius: 24,
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            child: Row(children: [
                              Expanded(
                                  child: Text('Prefer waterproof pieces',
                                      style: sans(15.5, w: FontWeight.w600))),
                              Switch(
                                  value: s.preferWaterproof,
                                  activeColor: Colors.white,
                                  activeTrackColor: C.green,
                                  onChanged: s.setWaterproof),
                            ]),
                          ),
                          const Divider(height: 1, color: C.line),
                          InkWell(
                            onTap: s.cycleComfort,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 18),
                              child: Row(children: [
                                Expanded(
                                    child: Text('Temperature comfort',
                                        style: sans(15.5, w: FontWeight.w600))),
                                Text(s.comfortLabel,
                                    style: sans(15, color: C.muted)),
                                const Icon(Icons.chevron_right, color: C.muted),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 22),
                      Row(children: [
                        Expanded(
                            child: Text('Suggested outfits', style: serif(22))),
                        Text('${s.rankedOutfits().take(3).length} matches',
                            style: sans(13, color: C.muted)),
                      ]),
                      const SizedBox(height: 12),
                      for (final o in s.rankedOutfits().take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Panel(
                            radius: 24,
                            onTap: () {
                              s.setTodayOverride(o.id);
                              snack(
                                  context, '${o.name} set as today\'s outfit');
                            },
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OutfitStrip(s.itemsOf(o),
                                      height: 84, emoji: 30),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                        child: Text(o.name,
                                            style: sans(15.5,
                                                w: FontWeight.w700))),
                                    Tag('${s.fitOf(o)}% fit'),
                                  ]),
                                ]),
                          ),
                        ),
                    ]),
              ),
      ),
    );
  }

  Widget _stat(IconData i, String v, String l) => Expanded(
        child: Column(children: [
          Icon(i, color: Colors.white70, size: 20),
          const SizedBox(height: 6),
          Text(v, style: sans(16, color: Colors.white, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(l, style: sans(12, color: Colors.white70)),
        ]),
      );

  void _cityPicker(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Choose your location', style: serif(22)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location, color: C.green),
                title: Text('Use my location',
                    style: sans(16, w: FontWeight.w700)),
                subtitle: Text(s.gpsPlace?.name ?? 'Follows you when you move',
                    style: sans(12.5, color: C.muted)),
                trailing:
                    s.useGps ? const Icon(Icons.check, color: C.green) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  s.useMyLocation();
                },
              ),
              const Divider(color: C.line),
              for (final c in phCities)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name, style: sans(16)),
                  trailing: (!s.useGps && s.city.name == c.name)
                      ? const Icon(Icons.check, color: C.green)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    s.setCity(c);
                  },
                ),
            ]),
      ),
    );
  }
}
