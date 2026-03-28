import '../models/product.dart';

final fakeProducts = List.generate(50, (i) {
  final categories = ['Electronics', 'Clothing', 'Home', 'Sports', 'Books'];
  final names = [
    'Wireless Headphones', 'Smart Watch', 'Running Shoes', 'Backpack',
    'Coffee Maker', 'Bluetooth Speaker', 'Yoga Mat', 'Water Bottle',
    'Desk Lamp', 'Phone Case', 'Sunglasses', 'Keyboard', 'Mouse Pad',
    'Notebook', 'Pen Set', 'T-Shirt', 'Hoodie', 'Sneakers', 'Hat', 'Scarf',
  ];

  return Product(
    id: i,
    name: '${names[i % names.length]} ${i + 1}',
    description: 'High quality ${names[i % names.length].toLowerCase()} with premium materials. '
        'Perfect for everyday use. Free shipping on orders over \$50.',
    price: 9.99 + (i * 7.5 % 190),
    imageUrl: 'https://picsum.photos/seed/product$i/400/400',
    rating: 3.5 + (i % 15) * 0.1,
    reviewCount: 10 + i * 13 % 500,
    category: categories[i % categories.length],
  );
});
