import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

enum Category { tops, bottoms, outerwear, shoes, bags, dresses, accessories }

extension CategoryX on Category {
  String get label => switch (this) {
        Category.tops => 'Tops',
        Category.bottoms => 'Bottoms',
        Category.outerwear => 'Outerwear',
        Category.shoes => 'Shoes',
        Category.bags => 'Bags',
        Category.dresses => 'Dresses',
        Category.accessories => 'Accessories',
      };

  String get emoji => switch (this) {
        Category.tops => '👕',
        Category.bottoms => '👖',
        Category.outerwear => '🧥',
        Category.shoes => '👟',
        Category.bags => '👜',
        Category.dresses => '👗',
        Category.accessories => '🕶️',
      };

  IconData get icon => switch (this) {
        Category.tops => Icons.checkroom_outlined,
        Category.bottoms => Icons.dry_cleaning_outlined,
        Category.outerwear => Icons.layers_outlined,
        Category.shoes => Icons.directions_walk,
        Category.bags => Icons.shopping_bag_outlined,
        Category.dresses => Icons.woman,
        Category.accessories => Icons.watch_outlined,
      };

  Color get tile => switch (this) {
        Category.tops => const Color(0xFFF1ECE4),
        Category.bottoms => const Color(0xFFEAEDF4),
        Category.outerwear => const Color(0xFFEFEAE1),
        Category.shoes => const Color(0xFFEFF1EB),
        Category.bags => const Color(0xFFF1EBE9),
        Category.dresses => const Color(0xFFE7EDE6),
        Category.accessories => const Color(0xFFF3EBDD),
      };

  List<String> get subtypes => switch (this) {
        Category.tops => ['T-shirts', 'Shirts', 'Knitwear', 'Tanks'],
        Category.bottoms => ['Jeans', 'Shorts', 'Trousers', 'Skirts'],
        Category.outerwear => ['Blazers', 'Coats', 'Jackets'],
        Category.shoes => ['Sneakers', 'Boots', 'Sandals'],
        Category.bags => ['Totes', 'Crossbody', 'Backpacks'],
        Category.dresses => ['Casual', 'Formal'],
        Category.accessories => ['Umbrellas', 'Hats', 'Jewelry'],
      };
}

/// Named colours used for detection / editing.
const Map<String, Color> palette = {
  'White': Color(0xFFFFFFFF),
  'Black': Color(0xFF1C1C1E),
  'Grey': Color(0xFF9A9A9A),
  'Cream': Color(0xFFEFE6D2),
  'Beige': Color(0xFFD9C7A6),
  'Camel': Color(0xFFC19A6B),
  'Brown': Color(0xFF6F4E37),
  'Navy': Color(0xFF1F2A44),
  'Indigo': Color(0xFF2B3A67),
  'Sky blue': Color(0xFF8FB1DF),
  'Sage': Color(0xFF9CAF88),
  'Olive': Color(0xFF6B7140),
  'Red': Color(0xFFC0392B),
  'Pink': Color(0xFFE8A0B4),
  'Yellow': Color(0xFFE6C34A),
};

String nearestColorName(Color c) {
  String best = 'White';
  double bestD = double.infinity;
  palette.forEach((name, p) {
    final dr = (c.red - p.red).toDouble();
    final dg = (c.green - p.green).toDouble();
    final db = (c.blue - p.blue).toDouble();
    final d = dr * dr + dg * dg + db * db;
    if (d < bestD) {
      bestD = d;
      best = name;
    }
  });
  return best;
}

class ClothingItem {
  final String id;
  String name;
  Category category;
  String subtype;
  String colorName;
  Color color;
  String material;
  String pattern;
  String brand;
  double price;

  /// 0 = very light/breathable … 3 = heavy/warm.
  int warmth;
  bool waterproof;
  bool openShoes;
  bool favorite;
  int worn;
  DateTime? lastWorn;
  DateTime addedAt;
  Uint8List? imageBytes; // cut-out photo (PNG) or original
  String emoji;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subtype,
    required this.colorName,
    required this.color,
    required this.material,
    this.pattern = 'Solid',
    this.brand = '',
    this.price = 0,
    this.warmth = 1,
    this.waterproof = false,
    this.openShoes = false,
    this.favorite = false,
    this.worn = 0,
    this.lastWorn,
    DateTime? addedAt,
    this.imageBytes,
    required this.emoji,
  }) : addedAt = addedAt ?? DateTime.now();

  Color get tile => category.tile;
  double get costPerWear => price / (worn == 0 ? 1 : worn);
  String get materialShort => material.split(RegExp(r'[ ·]')).first;
  String get warmthLabel =>
      ['Light', 'Breathable', 'Medium', 'Warm'][warmth.clamp(0, 3)];

  String get lastWornLabel {
    if (lastWorn == null) return '—';
    final d = DateTime.now().difference(lastWorn!).inDays;
    return '${d}d';
  }

  /// The photo itself is saved as a separate file; JSON only notes that it exists.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'subtype': subtype,
        'colorName': colorName,
        'color': color.value,
        'material': material,
        'pattern': pattern,
        'brand': brand,
        'price': price,
        'warmth': warmth,
        'waterproof': waterproof,
        'openShoes': openShoes,
        'favorite': favorite,
        'worn': worn,
        'lastWorn': lastWorn?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
        'emoji': emoji,
        'photo': imageBytes != null,
      };

  factory ClothingItem.fromJson(Map<String, dynamic> j, Uint8List? bytes) =>
      ClothingItem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: Category.values.byName(j['category'] as String),
        subtype: j['subtype'] as String,
        colorName: j['colorName'] as String,
        color: Color(j['color'] as int),
        material: j['material'] as String,
        pattern: (j['pattern'] as String?) ?? 'Solid',
        brand: (j['brand'] as String?) ?? '',
        price: ((j['price'] as num?) ?? 0).toDouble(),
        warmth: (j['warmth'] as int?) ?? 1,
        waterproof: (j['waterproof'] as bool?) ?? false,
        openShoes: (j['openShoes'] as bool?) ?? false,
        favorite: (j['favorite'] as bool?) ?? false,
        worn: (j['worn'] as int?) ?? 0,
        lastWorn: j['lastWorn'] == null
            ? null
            : DateTime.parse(j['lastWorn'] as String),
        addedAt: j['addedAt'] == null
            ? null
            : DateTime.parse(j['addedAt'] as String),
        imageBytes: bytes,
        emoji: (j['emoji'] as String?) ?? '',
      );
}

class Outfit {
  final String id;
  String name;
  List<String> itemIds;
  String occasion;
  bool favorite;
  Outfit({
    required this.id,
    required this.name,
    required this.itemIds,
    this.occasion = 'Casual',
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'itemIds': itemIds,
        'occasion': occasion,
        'favorite': favorite,
      };

  factory Outfit.fromJson(Map<String, dynamic> j) => Outfit(
        id: j['id'] as String,
        name: j['name'] as String,
        itemIds: List<String>.from(j['itemIds'] as List),
        occasion: (j['occasion'] as String?) ?? 'Casual',
        favorite: (j['favorite'] as bool?) ?? false,
      );
}
