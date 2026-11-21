import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/location.dart';
import 'services/weather.dart';
import 'storage.dart';

class AppState extends ChangeNotifier {
  String userName = 'Maya';

  final List<ClothingItem> items = [];
  final List<Outfit> outfits = [];
  final Map<String, String> plans = {}; // yyyy-MM-dd -> outfitId
  final Set<String> wornDays = {};
  final ValueNotifier<int> tab = ValueNotifier<int>(0);

  // Weather
  PhCity city = phCities.first; // manual choice / fallback (Manila)
  bool useGps = true;
  bool locationDenied = false;
  PhCity? gpsPlace;
  DateTime? _lastLoad;
  Weather? weather;
  bool weatherLoading = false;
  bool preferWaterproof = true;
  int comfort = 2; // 0 runs cold, 1 neutral, 2 runs warm

  // Builder draft
  List<String> draft = [];
  String draftOccasion = 'Weekend brunch';

  // Wardrobe sort: 0 recently worn, 1 most worn, 2 name, 3 newest
  int sortMode = 0;
  String? todayOverrideId;

  // Settings / onboarding
  bool ready = false;
  bool onboarded = false;
  Set<String> styles = {};
  bool removeBg = true;
  bool laundryTracking = true;
  bool dailyReminder = true;
  bool rainAlerts = false;
  String defaultView = 'Grid';

  final _rng = Random();

  // Saving
  bool _loaded = false;
  Timer? _saveTimer;
  final Set<String> _photoSaved = {};

  AppState();

  Future<void> init() async {
    await load();
    await loadWeather();
    if (draft.isEmpty) shuffleDraft(notify: false);
    notifyListeners();
  }

  // ---------- Saving to the phone ----------
  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_loaded) {
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(milliseconds: 300), _save);
    }
  }

  /// Saves right away (called when the app goes to the background).
  Future<void> flush() async {
    _saveTimer?.cancel();
    if (_loaded) await _save();
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final j = await Storage.readJson();
      if (j != null) {
        items.clear();
        outfits.clear();
        plans.clear();
        wornDays.clear();
        for (final m in (j['items'] as List? ?? const [])) {
          final map = Map<String, dynamic>.from(m as Map);
          Uint8List? bytes;
          if (map['photo'] == true) {
            bytes = await Storage.readPhoto(map['id'] as String);
            if (bytes != null) _photoSaved.add(map['id'] as String);
          }
          items.add(ClothingItem.fromJson(map, bytes));
        }
        for (final m in (j['outfits'] as List? ?? const [])) {
          outfits.add(Outfit.fromJson(Map<String, dynamic>.from(m as Map)));
        }
        plans.addAll(Map<String, String>.from(j['plans'] as Map? ?? const {}));
        wornDays.addAll(List<String>.from(j['wornDays'] as List? ?? const []));
        final s = Map<String, dynamic>.from(j['settings'] as Map? ?? const {});
        preferWaterproof = (s['preferWaterproof'] as bool?) ?? preferWaterproof;
        comfort = (s['comfort'] as int?) ?? comfort;
        sortMode = (s['sortMode'] as int?) ?? sortMode;
        useGps = (s['useGps'] as bool?) ?? useGps;
        draftOccasion = (s['draftOccasion'] as String?) ?? draftOccasion;
        Units.fahrenheit = (s['fahrenheit'] as bool?) ?? false;
        onboarded = (s['onboarded'] as bool?) ?? false;
        styles = Set<String>.from((s['styles'] as List?) ?? const []);
        removeBg = (s['removeBg'] as bool?) ?? true;
        laundryTracking = (s['laundryTracking'] as bool?) ?? true;
        dailyReminder = (s['dailyReminder'] as bool?) ?? true;
        rainAlerts = (s['rainAlerts'] as bool?) ?? false;
        defaultView = (s['defaultView'] as String?) ?? 'Grid';
        final cityName = s['city'] as String?;
        for (final c in phCities) {
          if (c.name == cityName) city = c;
        }
      }
    } catch (_) {
      // unreadable file: start fresh
    }
    _loaded = true;
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final ids = items.map((e) => e.id).toSet();
      for (final i in items) {
        if (i.imageBytes != null && !_photoSaved.contains(i.id)) {
          await Storage.writePhoto(i.id, i.imageBytes!);
          _photoSaved.add(i.id);
        }
      }
      for (final id in _photoSaved.where((id) => !ids.contains(id)).toList()) {
        await Storage.deletePhoto(id);
        _photoSaved.remove(id);
      }
      await Storage.writeJson({
        'items': items.map((e) => e.toJson()).toList(),
        'outfits': outfits.map((e) => e.toJson()).toList(),
        'plans': plans,
        'wornDays': wornDays.toList(),
        'settings': {
          'preferWaterproof': preferWaterproof,
          'comfort': comfort,
          'sortMode': sortMode,
          'useGps': useGps,
          'draftOccasion': draftOccasion,
          'city': city.name,
          'fahrenheit': Units.fahrenheit,
          'onboarded': onboarded,
          'styles': styles.toList(),
          'removeBg': removeBg,
          'laundryTracking': laundryTracking,
          'dailyReminder': dailyReminder,
          'rainAlerts': rainAlerts,
          'defaultView': defaultView,
        },
      });
    } catch (_) {}
  }

  // ---------- Lookups ----------
  ClothingItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Outfit? outfitById(String? id) {
    if (id == null) return null;
    for (final o in outfits) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<ClothingItem> itemsOf(Outfit o) =>
      o.itemIds.map(itemById).whereType<ClothingItem>().toList();

  List<ClothingItem> byCategory(Category c) =>
      items.where((i) => i.category == c).toList();
  List<ClothingItem> get favoriteItems =>
      items.where((i) => i.favorite).toList();
  List<Outfit> get favoriteOutfits => outfits.where((o) => o.favorite).toList();
  int outfitCountFor(String itemId) =>
      outfits.where((o) => o.itemIds.contains(itemId)).length;

  List<ClothingItem> sorted(List<ClothingItem> l) {
    final c = [...l];
    final old = DateTime(2000);
    switch (sortMode) {
      case 1:
        c.sort((a, b) => b.worn.compareTo(a.worn));
      case 2:
        c.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case 3:
        c.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      default:
        c.sort((a, b) => (b.lastWorn ?? old).compareTo(a.lastWorn ?? old));
    }
    return c;
  }

  void setSort(int m) {
    sortMode = m;
    notifyListeners();
  }

  void setTodayOverride(String? id) {
    todayOverrideId = id;
    notifyListeners();
  }

  // ---------- Weather ----------
  Future<void> loadWeather({bool silent = false}) async {
    if (!silent) {
      weatherLoading = true;
      notifyListeners();
    }
    var place = city;
    if (useGps) {
      final g = await LocationService.current();
      if (g != null) {
        gpsPlace = g;
        locationDenied = false;
        place = g;
      } else {
        locationDenied = true;
      }
    }
    try {
      weather = await Weather.fetch(place);
    } catch (_) {
      weather = Weather.fallback(place);
    }
    _lastLoad = DateTime.now();
    weatherLoading = false;
    notifyListeners();
  }

  /// Called when the app returns to the foreground: follows you if you moved.
  Future<void> onResume() async {
    if (!useGps) return;
    final l = _lastLoad;
    if (l != null && DateTime.now().difference(l) < const Duration(minutes: 2))
      return;
    await loadWeather(silent: true);
  }

  void setCity(PhCity c) {
    city = c;
    useGps = false;
    locationDenied = false;
    loadWeather();
  }

  void useMyLocation() {
    useGps = true;
    loadWeather();
  }

  void setWaterproof(bool v) {
    preferWaterproof = v;
    notifyListeners();
  }

  void cycleComfort() {
    comfort = (comfort + 1) % 3;
    notifyListeners();
  }

  String get comfortLabel =>
      const ['Runs cold', 'Neutral', 'Runs warm'][comfort];

  /// Target warmth (0 light … 3 warm) for current Philippine conditions.
  int get targetWarmth {
    final f = weather?.feels ?? 32;
    var t = f >= 32
        ? 0
        : f >= 28
            ? 1
            : f >= 24
                ? 2
                : 3;
    t += comfort == 0
        ? 1
        : comfort == 2
            ? -1
            : 0;
    return t.clamp(0, 3);
  }

  /// "Smart fit" score for a set of pieces against the weather.
  int fit(List<ClothingItem> l) {
    if (l.isEmpty) return 0;
    var score = 100.0;
    final avg = l.map((e) => e.warmth).reduce((a, b) => a + b) / l.length;
    score -= (avg - targetWarmth).abs() * 14;
    if (weather?.rainy ?? false) {
      final proof = l.any((e) =>
          e.waterproof &&
          (e.category == Category.outerwear ||
              e.category == Category.accessories));
      if (!proof) score -= preferWaterproof ? 18 : 8;
      if (l.any((e) => e.openShoes && !e.waterproof)) score -= 8;
    }
    final hasBase = l.any(
        (e) => e.category == Category.tops || e.category == Category.dresses);
    final hasBottom = l.any((e) =>
        e.category == Category.bottoms || e.category == Category.dresses);
    final hasShoes = l.any((e) => e.category == Category.shoes);
    if (!hasBase) score -= 15;
    if (!hasBottom) score -= 15;
    if (!hasShoes) score -= 10;
    return score.round().clamp(35, 98);
  }

  int fitOf(Outfit o) => fit(itemsOf(o));

  List<Outfit> rankedOutfits() {
    final l = [...outfits];
    l.sort((a, b) => fitOf(b).compareTo(fitOf(a)));
    return l;
  }

  // ---------- Today ----------
  Outfit? get todaysOutfit {
    final o = outfitById(todayOverrideId);
    if (o != null) return o;
    final planned = outfitById(plans[dayKey(DateTime.now())]);
    if (planned != null) return planned;
    final r = rankedOutfits();
    return r.isEmpty ? null : r.first;
  }

  bool get todayIsPlanned =>
      plans.containsKey(dayKey(DateTime.now())) && todayOverrideId == null;

  void shuffleToday() {
    if (outfits.length < 2) return;
    final current = todaysOutfit?.id;
    final top = rankedOutfits().take(4).where((o) => o.id != current).toList();
    final pool =
        top.isEmpty ? outfits.where((o) => o.id != current).toList() : top;
    todayOverrideId = pool[_rng.nextInt(pool.length)].id;
    notifyListeners();
  }

  void wearToday(Outfit o) {
    markWorn(DateTime.now(), o);
  }

  // ---------- Items ----------
  void toggleFavorite(ClothingItem i) {
    i.favorite = !i.favorite;
    notifyListeners();
  }

  void toggleOutfitFavorite(Outfit o) {
    o.favorite = !o.favorite;
    notifyListeners();
  }

  void addItem(ClothingItem i) {
    items.insert(0, i);
    notifyListeners();
  }

  void deleteItem(ClothingItem i) {
    items.remove(i);
    for (final o in outfits) {
      o.itemIds.remove(i.id);
    }
    draft.remove(i.id);
    notifyListeners();
  }

  void logWear(ClothingItem i, [DateTime? when]) {
    i.worn++;
    i.wearsSinceWash++;
    i.lastWorn = when ?? DateTime.now();
    notifyListeners();
  }

  // ---------- Outfits ----------
  void saveDraft({String? name}) {
    if (draft.isEmpty) return;
    outfits.insert(
      0,
      Outfit(
        id: 'o${DateTime.now().microsecondsSinceEpoch}',
        name: name ?? '$draftOccasion look',
        itemIds: [...draft],
        occasion: draftOccasion,
      ),
    );
    notifyListeners();
  }

  void deleteOutfit(Outfit o) {
    outfits.remove(o);
    plans.removeWhere((_, v) => v == o.id);
    if (todayOverrideId == o.id) todayOverrideId = null;
    notifyListeners();
  }

  void addToOutfit(Outfit o, ClothingItem i) {
    if (!o.itemIds.contains(i.id)) o.itemIds.add(i.id);
    notifyListeners();
  }

  void setDraft(List<String> ids) {
    draft = ids;
    notifyListeners();
  }

  void addToDraft(String id) {
    if (!draft.contains(id)) draft.add(id);
    notifyListeners();
  }

  void removeFromDraft(String id) {
    draft.remove(id);
    notifyListeners();
  }

  void setOccasion(String o) {
    draftOccasion = o;
    notifyListeners();
  }

  void shuffleDraft({bool notify = true}) {
    if (items.isEmpty) return;
    var best = <String>[];
    var bestScore = -1;
    for (var n = 0; n < 40; n++) {
      final cand = _candidate();
      final s = fit(cand.map((id) => itemById(id)!).toList()) + _rng.nextInt(8);
      if (s > bestScore) {
        bestScore = s;
        best = cand;
      }
    }
    draft = best;
    if (notify) notifyListeners();
  }

  ClothingItem? _pick(Category c) {
    final l = byCategory(c);
    return l.isEmpty ? null : l[_rng.nextInt(l.length)];
  }

  List<String> _candidate() {
    final out = <ClothingItem?>[];
    if (byCategory(Category.dresses).isNotEmpty && _rng.nextDouble() < 0.3) {
      out.add(_pick(Category.dresses));
    } else {
      out
        ..add(_pick(Category.tops))
        ..add(_pick(Category.bottoms));
    }
    out.add(_pick(Category.shoes));
    final rainy = weather?.rainy ?? false;
    if (_rng.nextDouble() < (rainy ? 0.9 : 0.3))
      out.add(_pick(Category.outerwear));
    if (_rng.nextDouble() < 0.5) out.add(_pick(Category.bags));
    return out.whereType<ClothingItem>().map((e) => e.id).toSet().toList();
  }

  // ---------- Settings helpers ----------
  /// Runs [f] then saves and refreshes the UI.
  void change(VoidCallback f) {
    f();
    notifyListeners();
  }

  void setFahrenheit(bool f) => change(() => Units.fahrenheit = f);

  void finishOnboarding() => change(() => onboarded = true);

  void markWashed(ClothingItem i) => change(() => i.wearsSinceWash = 0);

  void swapPiece(Outfit o, String oldId, String newId) {
    final idx = o.itemIds.indexOf(oldId);
    if (idx >= 0) o.itemIds[idx] = newId;
    notifyListeners();
  }

  /// Plans a set of pieces for a day. Reuses a matching saved outfit or creates one.
  void planPieces(DateTime d, List<String> ids, {String occasion = 'Casual'}) {
    Outfit? match;
    for (final o in outfits) {
      if (o.itemIds.length == ids.length && o.itemIds.toSet().containsAll(ids))
        match = o;
    }
    if (match == null) {
      match = Outfit(
        id: 'o${DateTime.now().microsecondsSinceEpoch}',
        name: '${DateFormat('EEE d MMM').format(d)} plan',
        itemIds: [...ids],
        occasion: occasion,
      );
      outfits.insert(0, match);
    }
    plans[dayKey(d)] = match.id;
    notifyListeners();
  }

  // ---------- Calendar ----------
  void plan(DateTime d, Outfit o) {
    plans[dayKey(d)] = o.id;
    notifyListeners();
  }

  void unplan(DateTime d) {
    plans.remove(dayKey(d));
    notifyListeners();
  }

  /// Marks a day as worn: counts each piece once per day.
  bool markWorn(DateTime d, Outfit o) {
    final k = dayKey(d);
    if (wornDays.contains(k)) return false;
    wornDays.add(k);
    plans[k] = o.id;
    for (final i in itemsOf(o)) {
      i.worn++;
      i.wearsSinceWash++;
      i.lastWorn = d;
    }
    o.worn++;
    o.lastWorn = d;
    notifyListeners();
    return true;
  }
}
