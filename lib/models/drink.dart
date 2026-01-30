class DrinkCategory {
  final String id;
  final String name;
  final String icon;

  const DrinkCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class DrinkSize {
  final String label;
  final double priceAdd;

  const DrinkSize({required this.label, this.priceAdd = 0});
}

class DrinkAddon {
  final String name;
  final double price;

  const DrinkAddon({required this.name, required this.price});
}

class Drink {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String categoryId;
  final String imageEmoji;
  final List<DrinkSize> sizes;
  final List<DrinkAddon> addons;
  final List<String> sugarLevels;
  final List<String> iceLevels;
  final bool isFeatured;
  final double rating;

  const Drink({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    required this.imageEmoji,
    this.sizes = const [],
    this.addons = const [],
    this.sugarLevels = const ['0%', '25%', '50%', '75%', '100%'],
    this.iceLevels = const ['No Ice', 'Less Ice', 'Normal', 'Extra Ice'],
    this.isFeatured = false,
    this.rating = 4.5,
  });
}
