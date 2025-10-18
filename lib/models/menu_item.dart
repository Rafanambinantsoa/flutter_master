enum MenuCategory { dish, drink, dessert }

enum MenuTemperature { hot, cold }

class MenuItemModel {
  final String id;
  final String name;
  final MenuCategory category;
  final double price;
  final String? imageUrl;
  final String? description;
  final MenuTemperature temperature;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl,
    this.description,
    this.temperature = MenuTemperature.hot,
  });
}
