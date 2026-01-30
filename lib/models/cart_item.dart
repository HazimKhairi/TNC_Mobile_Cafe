import 'drink.dart';

class CartItem {
  final String id;
  final Drink drink;
  final DrinkSize selectedSize;
  final List<DrinkAddon> selectedAddons;
  final String sugarLevel;
  final String iceLevel;
  final String? specialInstructions;
  int quantity;

  CartItem({
    required this.id,
    required this.drink,
    required this.selectedSize,
    this.selectedAddons = const [],
    this.sugarLevel = '100%',
    this.iceLevel = 'Normal',
    this.specialInstructions,
    this.quantity = 1,
  });

  double get totalPrice {
    double price = drink.basePrice + selectedSize.priceAdd;
    for (final addon in selectedAddons) {
      price += addon.price;
    }
    return price * quantity;
  }

  String get customizationSummary {
    final parts = <String>[];
    parts.add(selectedSize.label);
    parts.add('Sugar: $sugarLevel');
    parts.add('Ice: $iceLevel');
    for (final addon in selectedAddons) {
      parts.add('+ ${addon.name}');
    }
    return parts.join(' | ');
  }

  Map<String, dynamic> toMap() => {
        'drinkId': drink.id,
        'drinkName': drink.name,
        'drinkEmoji': drink.imageEmoji,
        'basePrice': drink.basePrice,
        'selectedSize': selectedSize.label,
        'selectedSizePriceAdd': selectedSize.priceAdd,
        'selectedAddons':
            selectedAddons.map((a) => {'name': a.name, 'price': a.price}).toList(),
        'sugarLevel': sugarLevel,
        'iceLevel': iceLevel,
        'specialInstructions': specialInstructions,
        'quantity': quantity,
        'totalPrice': totalPrice,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final addons = (map['selectedAddons'] as List<dynamic>?)
            ?.map((a) => DrinkAddon(
                  name: a['name'] as String,
                  price: (a['price'] as num).toDouble(),
                ))
            .toList() ??
        [];

    final drink = Drink(
      id: map['drinkId'] as String,
      name: map['drinkName'] as String,
      description: '',
      basePrice: (map['basePrice'] as num).toDouble(),
      categoryId: '',
      imageEmoji: map['drinkEmoji'] as String,
    );

    return CartItem(
      id: map['drinkId'] as String,
      drink: drink,
      selectedSize: DrinkSize(
        label: map['selectedSize'] as String,
        priceAdd: (map['selectedSizePriceAdd'] as num?)?.toDouble() ?? 0,
      ),
      selectedAddons: addons,
      sugarLevel: map['sugarLevel'] as String? ?? '100%',
      iceLevel: map['iceLevel'] as String? ?? 'Normal',
      specialInstructions: map['specialInstructions'] as String?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
