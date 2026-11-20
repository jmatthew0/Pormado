import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:pormado/models.dart';

void main() {
  test('cost per wear never divides by zero', () {
    final item = ClothingItem(
      id: 't', name: 'Tee', category: Category.tops, subtype: 'T-shirts',
      colorName: 'White', color: const Color(0xFFFFFFFF), material: 'Cotton',
      price: 500, emoji: '👕',
    );
    expect(item.costPerWear, 500);
  });
}
