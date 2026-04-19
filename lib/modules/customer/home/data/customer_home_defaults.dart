import '../domain/customer_home_category.dart';

/// Shown when Firestore has no doc yet or invalid payload (offline / first launch).
List<CustomerHomeCategory> defaultCustomerHomeCategories() => [
      const CustomerHomeCategory(
        title: 'Fresh',
        subtitle: 'DAILY HARVEST',
        tagline:
            'Blue Oyster — delicate texture & vibrant caps. Perfect for sauté & soups.',
        imageUrl:
            'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?fm=jpg&fit=crop&w=1400&q=88',
        order: 0,
      ),
      const CustomerHomeCategory(
        title: 'Dry',
        subtitle: 'AGED UMAMI',
        tagline:
            'Shiitake & dried caps — rich, concentrated flavor for broths & stir-fries.',
        imageUrl:
            'https://images.unsplash.com/photo-1576045057995-568f588f82fb?fm=jpg&fit=crop&w=1400&q=88',
        order: 1,
      ),
      const CustomerHomeCategory(
        title: 'Powder',
        subtitle: 'SUPERFOOD',
        tagline:
            'Fine mushroom blends (Reishi, Lion\'s Mane) — nutritional boost for drinks & meals.',
        imageUrl:
            'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?fm=jpg&fit=crop&w=1400&q=88',
        order: 2,
      ),
      const CustomerHomeCategory(
        title: 'Medicinal',
        subtitle: 'ELIXIRS',
        tagline:
            'Chaga & Cordyceps-inspired extracts — premium jars & wellness-focused concentrates.',
        imageUrl:
            'https://images.unsplash.com/photo-1583947215259-38e31be8751f?fm=jpg&fit=crop&w=1400&q=88',
        order: 3,
      ),
    ];
