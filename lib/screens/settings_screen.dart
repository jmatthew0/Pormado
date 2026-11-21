import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth.dart';
import '../services/weather.dart';
import '../state.dart';
import '../ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 0, 10),
        child: Text(t.toUpperCase(),
            style: sans(12, color: C.muted).copyWith(letterSpacing: 1)),
      );

  Widget _toggle(String title, String? sub, bool v, ValueChanged<bool> on,
          {bool last = false}) =>
      Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        decoration: BoxDecoration(
            border:
                last ? null : const Border(bottom: BorderSide(color: C.line))),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: sans(15.5, w: FontWeight.w700)),
              if (sub != null) Text(sub, style: sans(12.5, color: C.muted)),
            ]),
          ),
          Switch(
              value: v,
              activeColor: Colors.white,
              activeTrackColor: C.green,
              onChanged: on),
        ]),
      );

  Widget _navRow(String title, String value, VoidCallback onTap,
          {bool last = false}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(bottom: BorderSide(color: C.line))),
          child: Row(children: [
            Expanded(child: Text(title, style: sans(15.5, w: FontWeight.w700))),
            Flexible(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: sans(15, color: C.muted))),
            const Icon(Icons.chevron_right, color: C.muted),
          ]),
        ),
      );

  Widget _stat(String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: C.bg, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Text(v, style: serif(24)),
            const SizedBox(height: 2),
            Text(l, style: sans(12.5, color: C.muted)),
          ]),
        ),
      );

  void _editName(BuildContext context, Auth auth) async {
    final c = TextEditingController(text: auth.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text('Your name', style: serif(20)),
        content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (v != null && v.trim().isNotEmpty) auth.updateName(v);
  }

  void _pickLocation(BuildContext context, AppState s) {
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final auth = context.watch<Auth>();
    const styles = [
      'Minimal',
      'Smart casual',
      'Classic',
      'Streetwear',
      'Boho',
      'Sporty',
      'Romantic',
      'Edgy'
    ];

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
                    child: Center(
                        child: Text('Profile & settings', style: serif(22)))),
                const SizedBox(width: 44),
              ]),
              const SizedBox(height: 16),
              Panel(
                radius: 28,
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Row(children: [
                    CircleAvatar(
                        radius: 34,
                        backgroundColor: C.terracotta,
                        child: Text(auth.initial,
                            style: serif(28, color: Colors.white))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.guest ? 'Guest' : auth.name,
                                style: serif(22)),
                            Text(
                                auth.guest
                                    ? 'Not using an account'
                                    : auth.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sans(13, color: C.muted)),
                          ]),
                    ),
                    if (!auth.guest)
                      GestureDetector(
                        onTap: () => _editName(context, auth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: C.line)),
                          child:
                              Text('Edit', style: sans(14, w: FontWeight.w600)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    _stat('${s.items.length}', 'Items'),
                    const SizedBox(width: 10),
                    _stat('${s.outfits.length}', 'Outfits'),
                    const SizedBox(width: 10),
                    _stat('${s.favoriteItems.length}', 'Favorites'),
                  ]),
                ]),
              ),
              _section('Wardrobe'),
              Panel(
                radius: 24,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _toggle(
                      'Remove backgrounds automatically',
                      'Clean cutouts for every photo',
                      s.removeBg,
                      (v) => s.change(() => s.removeBg = v)),
                  _toggle(
                      'Laundry tracking',
                      'Remind me after 3 wears',
                      s.laundryTracking,
                      (v) => s.change(() => s.laundryTracking = v)),
                  _navRow(
                      'Default wardrobe view',
                      s.defaultView,
                      () => s.change(() => s.defaultView =
                          s.defaultView == 'Grid' ? 'List' : 'Grid'),
                      last: true),
                ]),
              ),
              _section('Weather & reminders'),
              Panel(
                radius: 24,
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _navRow(
                      'Location',
                      s.useGps
                          ? (s.gpsPlace?.name ?? 'Current location')
                          : s.city.name,
                      () => _pickLocation(context, s)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: C.line))),
                    child: Row(children: [
                      Expanded(
                          child: Text('Temperature',
                              style: sans(15.5, w: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: C.bg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [
                          for (final f in [false, true])
                            GestureDetector(
                              onTap: () => s.setFahrenheit(f),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Units.fahrenheit == f
                                        ? C.ink
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(17)),
                                child: Text(f ? '°F' : '°C',
                                    style: sans(13.5,
                                        color: Units.fahrenheit == f
                                            ? Colors.white
                                            : C.muted,
                                        w: FontWeight.w700)),
                              ),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                  _toggle(
                      'Daily outfit reminder',
                      '7:30 AM on workdays',
                      s.dailyReminder,
                      (v) => s.change(() => s.dailyReminder = v)),
                  _toggle('Rain alerts', 'Suggest waterproof layers',
                      s.rainAlerts, (v) => s.change(() => s.rainAlerts = v),
                      last: true),
                ]),
              ),
              _section('Style'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in styles)
                  Pill(t,
                      selected: s.styles.contains(t),
                      onTap: () => s.change(() => s.styles.contains(t)
                          ? s.styles.remove(t)
                          : s.styles.add(t))),
              ]),
              const SizedBox(height: 28),
              Btn('Sign out', icon: Icons.logout, style: BtnStyle.outline,
                  onTap: () {
                Navigator.pop(context);
                auth.signOut();
              }),
              if (!auth.guest)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          backgroundColor: C.bg,
                          title: Text('Delete account?', style: serif(20)),
                          content: const Text(
                              'This removes the account from this phone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(d, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(d, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        Navigator.pop(context);
                        auth.deleteAccount();
                      }
                    },
                    child:
                        Text('Delete account', style: sans(14, color: C.muted)),
                  ),
                ),
            ]),
      ),
    );
  }
}
