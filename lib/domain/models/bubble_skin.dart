/// A purchasable cosmetic: the color palette bubbles are drawn from. Colors are
/// ARGB ints to keep the domain Flutter-free; the game/UI wrap them in `Color`.
class BubbleSkin {
  const BubbleSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.colors,
  });

  final String id;
  final String name;
  final int price;
  final List<int> colors;
}

/// The shop catalog. 'classic' is free and owned by default.
const List<BubbleSkin> kBubbleSkins = [
  BubbleSkin(
    id: 'classic',
    name: 'Classic',
    price: 0,
    colors: [0xFF4FC3F7, 0xFFBA68C8, 0xFFFF8A65, 0xFF81C784, 0xFFFFD54F, 0xFFF06292],
  ),
  BubbleSkin(
    id: 'ocean',
    name: 'Ocean',
    price: 300,
    colors: [0xFF26C6DA, 0xFF2196F3, 0xFF00BCD4, 0xFF3F51B5, 0xFF4DD0E1, 0xFF5C6BC0],
  ),
  BubbleSkin(
    id: 'sunset',
    name: 'Sunset',
    price: 500,
    colors: [0xFFFF7043, 0xFFFFA726, 0xFFFFCA28, 0xFFEF5350, 0xFFEC407A, 0xFFAB47BC],
  ),
  BubbleSkin(
    id: 'neon',
    name: 'Neon',
    price: 800,
    colors: [0xFF00E676, 0xFF1DE9B6, 0xFF00B0FF, 0xFFD500F9, 0xFFFFEA00, 0xFFFF1744],
  ),
];

BubbleSkin skinById(String id) =>
    kBubbleSkins.firstWhere((s) => s.id == id, orElse: () => kBubbleSkins.first);
