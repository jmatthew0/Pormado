import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'services/weather.dart';

class AppState extends ChangeNotifier {
  String userName = 'Maya';

  final List<ClothingItem> items = [];
  final List<Outfit> outfits = [];
  final Map<String, String> plans = {}; // yyyy-MM-dd -> outfitId
  final Set<String> wornDays = {};
  final ValueNotifier<int> tab = ValueNotifier<int>(0);

  // Weather
  PhCity city = phCities.first;
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

  final _rng = Random();

  AppState() {
    _seed();
  }

  Future<void> init() async {
    await loadWeather();
    if (draft.isEmpty) shuffleDraft(notify: false);
    notifyListeners();
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

  List<ClothingItem> byCategory(Category c) => items.where((i) => i.category == c).toList();
  List<ClothingItem> get favoriteItems => items.where((i) => i.favorite).toList();
  List<Outfit> get favoriteOutfits => outfits.where((o) => o.favorite).toList();
  int outfitCountFor(String itemId) => outfits.where((o) => o.itemIds.contains(itemId)).length;

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
  Future<void> loadWeather() async {
    weatherLoading = true;
    notifyListeners();
    try {
      weather = await Weather.fetch(city);
    } catch (_) {
      weather = Weather.fallback(city);
    }
    weatherLoading = false;
    notifyListeners();
  }

  void setCity(PhCity c) {
    city = c;
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

  String get comfortLabel => const ['Runs cold', 'Neutral', 'Runs warm'][comfort];

  /// Target warmth (0 light … 3 warm) for current Philippine conditions.
  int get targetWarmth {
    final f = weather?.feels ?? 32;
    var t = f >= 32 ? 0 : f >= 28 ? 1 : f >= 24 ? 2 : 3;
    t += comfort == 0 ? 1 : comfort == 2 ? -1 : 0;
    return t.clamp(0, 3);
  }

  /// "Smart fit" score for a set of pieces against the weather.
  int fit(List<ClothingItem> l) {
    if (l.isEmpty) return 0;
    var score = 100.0;
    final avg = l.map((e) => e.warmth).reduce((a, b) => a + b) / l.length;
    score -= (avg - targetWarmth).abs() * 14;
    if (weather?.rainy ?? false) {
      final proof = l.any((e) => e.waterproof && (e.category == Category.outerwear || e.category == Category.accessories));
      if (!proof) score -= preferWaterproof ? 18 : 8;
      if (l.any((e) => e.openShoes && !e.waterproof)) score -= 8;
    }
    final hasBase = l.any((e) => e.category == Category.tops || e.category == Category.dresses);
    final hasBottom = l.any((e) => e.category == Category.bottoms || e.category == Category.dresses);
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

  bool get todayIsPlanned => plans.containsKey(dayKey(DateTime.now())) && todayOverrideId == null;

  void shuffleToday() {
    if (outfits.length < 2) return;
    final current = todaysOutfit?.id;
    final top = rankedOutfits().take(4).where((o) => o.id != current).toList();
    final pool = top.isEmpty ? outfits.where((o) => o.id != current).toList() : top;
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
      out..add(_pick(Category.tops))..add(_pick(Category.bottoms));
    }
    out.add(_pick(Category.shoes));
    final rainy = weather?.rainy ?? false;
    if (_rng.nextDouble() < (rainy ? 0.9 : 0.3)) out.add(_pick(Category.outerwear));
    if (_rng.nextDouble() < 0.5) out.add(_pick(Category.bags));
    return out.whereType<ClothingItem>().map((e) => e.id).toSet().toList();
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
      i.lastWorn = d;
    }
    notifyListeners();
    return true;
  }

  // ---------- Seed data ----------
  ClothingItem _i(
    String id,
    String name,
    Category cat,
    String sub,
    String colorName,
    String material,
    String emoji, {
    String brand = '',
    double price = 0,
    int warmth = 1,
    bool waterproof = false,
    bool open = false,
    bool fav = false,
    int worn = 0,
    int? lastDays,
    int addedDays = 30,
  }) =>
      ClothingItem(
        id: id,
        name: name,
        category: cat,
        subtype: sub,
        colorName: colorName,
        color: palette[colorName] ?? Colors.grey,
        material: material,
        emoji: emoji,
        brand: brand,
        price: price,
        warmth: warmth,
        waterproof: waterproof,
        openShoes: open,
        favorite: fav,
        worn: worn,
        lastWorn: lastDays == null ? null : DateTime.now().subtract(Duration(days: lastDays)),
        addedAt: DateTime.now().subtract(Duration(days: addedDays)),
      );

  void _seed() {
    items.addAll([
      _i('tee', 'Classic crew tee', Category.tops, 'T-shirts', 'White', 'Cotton', '👕', brand: 'Uniqlo', price: 590, warmth: 0, fav: true, worn: 12, lastDays: 1, addedDays: 200),
      _i('knit', 'Chunky knit', Category.tops, 'Knitwear', 'Cream', 'Wool blend', '🧶', brand: 'Cotton On', price: 1490, warmth: 3, worn: 4, lastDays: 20, addedDays: 150),
      _i('linen', 'Linen button-up', Category.tops, 'Shirts', 'Sky blue', 'Linen', '👔', brand: 'Penshoppe', price: 990, warmth: 0, fav: true, worn: 7, lastDays: 3, addedDays: 90),
      _i('tank', 'Ribbed tank', Category.tops, 'Tanks', 'Black', 'Cotton', '🎽', brand: 'H&M', price: 390, warmth: 0, worn: 5, lastDays: 6, addedDays: 60),
      _i('jeans', 'Indigo jeans', Category.bottoms, 'Jeans', 'Indigo', 'Denim', '👖', brand: 'Levi\'s', price: 3200, warmth: 2, worn: 15, lastDays: 2, addedDays: 300),
      _i('shorts', 'Linen shorts', Category.bottoms, 'Shorts', 'Beige', 'Linen', '🩳', brand: 'Zara', price: 1290, warmth: 0, worn: 6, lastDays: 4, addedDays: 70),
      _i('blazer', 'Navy wool blazer', Category.outerwear, 'Blazers', 'Navy', 'Wool 70% · Polyester 30%', '🧥', brand: 'Everlane', price: 2490, warmth: 2, fav: true, worn: 9, lastDays: 3, addedDays: 120),
      _i('trench', 'Camel trench', Category.outerwear, 'Coats', 'Camel', 'Cotton gabardine', '🧥', brand: 'Mango', price: 4200, warmth: 2, waterproof: true, fav: true, worn: 8, lastDays: 9, addedDays: 250),
      _i('rain', 'Packable rain jacket', Category.outerwear, 'Jackets', 'Olive', 'Nylon', '🧥', brand: 'Uniqlo', price: 1990, warmth: 1, waterproof: true, worn: 5, lastDays: 5, addedDays: 80),
      _i('sneakers', 'White sneakers', Category.shoes, 'Sneakers', 'White', 'Leather', '👟', brand: 'Veja', price: 5500, warmth: 1, worn: 14, lastDays: 1, addedDays: 220),
      _i('boots', 'Ankle boots', Category.shoes, 'Boots', 'Black', 'Leather', '🥾', brand: 'Dr. Martens', price: 6500, warmth: 3, fav: true, worn: 10, lastDays: 11, addedDays: 260),
      _i('slides', 'Rubber slides', Category.shoes, 'Sandals', 'Black', 'Rubber', '🩴', brand: 'Havaianas', price: 890, warmth: 0, waterproof: true, open: true, worn: 18, lastDays: 2, addedDays: 180),
      _i('tote', 'Leather tote', Category.bags, 'Totes', 'Black', 'Leather', '👜', brand: 'Charles & Keith', price: 3290, warmth: 1, worn: 11, lastDays: 2, addedDays: 140),
      _i('sage', 'Sage midi dress', Category.dresses, 'Casual', 'Sage', 'Viscose', '👗', brand: 'Zalora', price: 1890, warmth: 0, fav: true, worn: 6, lastDays: 8, addedDays: 100),
      _i('umbrella', 'Compact umbrella', Category.accessories, 'Umbrellas', 'Black', 'Polyester', '☂️', brand: 'Muji', price: 450, warmth: 0, waterproof: true, worn: 20, lastDays: 4, addedDays: 160),
    ]);

    outfits.addAll([
      Outfit(id: 'o1', name: 'Relaxed Weekend Layers', itemIds: ['tee', 'jeans', 'sneakers'], occasion: 'Casual', favorite: true),
      Outfit(id: 'o2', name: 'Office-ready blazer look', itemIds: ['blazer', 'jeans', 'boots'], occasion: 'Work'),
      Outfit(id: 'o3', name: 'Cozy brunch', itemIds: ['knit', 'jeans', 'boots', 'tote'], occasion: 'Weekend brunch'),
      Outfit(id: 'o4', name: 'Breezy brunch', itemIds: ['sage', 'slides', 'tote'], occasion: 'Weekend brunch', favorite: true),
      Outfit(id: 'o5', name: 'Rainy day commute', itemIds: ['linen', 'jeans', 'rain', 'sneakers', 'umbrella'], occasion: 'Work', favorite: true),
      Outfit(id: 'o6', name: 'Mall & merienda', itemIds: ['tank', 'shorts', 'slides', 'tote'], occasion: 'Casual'),
    ]);

    final now = DateTime.now();
    for (final d in [1, 2, 4, 5, 8, 9]) {
      final day = now.subtract(Duration(days: d));
      wornDays.add(dayKey(day));
      plans[dayKey(day)] = outfits[d % outfits.length].id;
    }
    for (final d in [1, 2, 4, 6]) {
      plans[dayKey(now.add(Duration(days: d)))] = outfits[(d + 2) % outfits.length].id;
    }
    draft = ['tee', 'jeans', 'sneakers'];
  }
}
