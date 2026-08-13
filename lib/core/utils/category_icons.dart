import 'package:flutter/material.dart';

/// Maps a PriceCatcher `item_category` (Bahasa Melayu) to a representative
/// Material icon, so product thumbnails aren't all the same generic basket.
///
/// The dataset has no product images, so this is a deliberate stand-in — a
/// per-category icon instead of a per-product photo. Matching is by
/// substring on a fixed, ordered keyword list (first match wins) rather
/// than an exact map, since a handful of categories share a root word
/// (e.g. every "IKAN ..." variant).
IconData categoryIcon(String category) {
  final value = category.toUpperCase();

  for (final entry in _keywordIcons) {
    if (value.contains(entry.$1)) return entry.$2;
  }
  return Icons.shopping_basket_outlined;
}

const List<(String, IconData)> _keywordIcons = [
  // Fresh & prepared food
  ('AYAM', Icons.dinner_dining),
  ('DAGING', Icons.kebab_dining),
  ('LAUK', Icons.restaurant),
  ('IKAN', Icons.set_meal),
  ('LAUT', Icons.set_meal),
  ('TELUR', Icons.egg),
  ('BERAS', Icons.rice_bowl),
  ('NASI', Icons.rice_bowl),
  ('MEE', Icons.ramen_dining),
  ('BIHUN', Icons.ramen_dining),
  ('KUETIAU', Icons.ramen_dining),
  ('KUEY TEOW', Icons.ramen_dining),
  ('ROTI', Icons.bakery_dining),
  ('MENTEGA', Icons.breakfast_dining),
  ('SAPUAN', Icons.breakfast_dining),
  ('TAUHU', Icons.square_outlined),
  ('TEMPE', Icons.square_outlined),
  ('SAYUR', Icons.grass),
  ('UBI', Icons.grass),
  ('BUAH', Icons.eco),
  ('KELAPA', Icons.eco),
  ('SANTAN', Icons.local_drink),
  ('SUSU', Icons.local_drink),
  ('KRIMER', Icons.local_drink),
  ('MINYAK', Icons.water_drop),
  ('GULA', Icons.icecream),
  ('COKLAT', Icons.cake),
  ('BISKUT', Icons.cookie),
  ('TEPUNG', Icons.grain),
  ('KACANG', Icons.grain),
  ('BAWANG', Icons.spa),
  ('CILI', Icons.local_fire_department),
  ('REMPAH', Icons.local_fire_department),
  ('KICAP', Icons.liquor),
  ('SOS', Icons.liquor),
  ('ESEN', Icons.science),
  ('RAGI', Icons.science),
  ('MINUMAN', Icons.local_cafe),
  ('TERSEDIA MINUM', Icons.local_cafe),
  ('MAKANAN RINGAN', Icons.fastfood),
  ('MAKANAN SEGERA', Icons.fastfood),
  ('MI SEGERA', Icons.fastfood),
  ('MAKANAN BAYI', Icons.child_care),
  ('SUSU BAYI', Icons.child_care),

  // Non-food
  ('ALAT TULIS', Icons.menu_book),
  ('BAHAN BACAAN', Icons.menu_book),
  ('MAJALAH', Icons.menu_book),
  ('BERUS GIGI', Icons.clean_hands),
  ('UBAT GIGI', Icons.medication_outlined),
  ('UBAT-UBATAN', Icons.medication_outlined),
  ('MOUTH WASH', Icons.medication_outlined),
  ('LAMPIN', Icons.baby_changing_station),
  ('PENGHALAU NYAMUK', Icons.pest_control),
  ('PENJAGAAN DIRI', Icons.face_outlined),
  ('PENJAGAAN RUMAH', Icons.home_outlined),
  ('PEWANGI RUMAH', Icons.local_florist_outlined),
  ('SABUN', Icons.clean_hands),
  ('SYAMPU', Icons.shower_outlined),
  ('TISU', Icons.layers_outlined),
  ('TUALA WANITA', Icons.favorite_border),
];
