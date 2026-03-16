/// Defines supported external apps and their deep link / URL schemes
class ExternalApp {
  final String id;
  final String name;
  final String category; // food, travel, tickets, shopping, transport, bills
  final String icon; // emoji for display
  final String? androidPackage;
  final String? iosScheme;
  final String fallbackUrl;
  final String? deepLinkTemplate; // e.g. "zomato://order?query={query}"

  const ExternalApp({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    this.androidPackage,
    this.iosScheme,
    required this.fallbackUrl,
    this.deepLinkTemplate,
  });
}

/// Pre-defined external apps the navigator can launch
class ExternalApps {
  // Food & Delivery
  static const zomato = ExternalApp(
    id: 'zomato',
    name: 'Zomato',
    category: 'food',
    icon: '🍕',
    androidPackage: 'com.application.zomato',
    iosScheme: 'zomato://',
    fallbackUrl: 'https://www.zomato.com',
    deepLinkTemplate: 'zomato://order',
  );

  static const swiggy = ExternalApp(
    id: 'swiggy',
    name: 'Swiggy',
    category: 'food',
    icon: '🍔',
    androidPackage: 'in.swiggy.android',
    iosScheme: 'swiggy://',
    fallbackUrl: 'https://www.swiggy.com',
    deepLinkTemplate: 'swiggy://explore',
  );

  static const uberEats = ExternalApp(
    id: 'uber_eats',
    name: 'Uber Eats',
    category: 'food',
    icon: '🥡',
    androidPackage: 'com.ubercab.eats',
    iosScheme: 'ubereats://',
    fallbackUrl: 'https://www.ubereats.com',
  );

  // Transport
  static const uber = ExternalApp(
    id: 'uber',
    name: 'Uber',
    category: 'transport',
    icon: '🚗',
    androidPackage: 'com.ubercab',
    iosScheme: 'uber://',
    fallbackUrl: 'https://m.uber.com',
    deepLinkTemplate: 'uber://?action=setPickup&pickup=my_location',
  );

  static const ola = ExternalApp(
    id: 'ola',
    name: 'Ola',
    category: 'transport',
    icon: '🛺',
    androidPackage: 'com.olacabs.customer',
    iosScheme: 'olacabs://',
    fallbackUrl: 'https://www.olacabs.com',
  );

  static const rapido = ExternalApp(
    id: 'rapido',
    name: 'Rapido',
    category: 'transport',
    icon: '🏍️',
    androidPackage: 'com.rapido.passenger',
    iosScheme: 'rapido://',
    fallbackUrl: 'https://www.rapido.bike',
  );

  // Tickets & Entertainment
  static const bookMyShow = ExternalApp(
    id: 'bookmyshow',
    name: 'BookMyShow',
    category: 'tickets',
    icon: '🎬',
    androidPackage: 'com.bt.bms',
    iosScheme: 'bookmyshow://',
    fallbackUrl: 'https://in.bookmyshow.com',
  );

  static const makemytrip = ExternalApp(
    id: 'makemytrip',
    name: 'MakeMyTrip',
    category: 'travel',
    icon: '✈️',
    androidPackage: 'com.makemytrip',
    iosScheme: 'makemytrip://',
    fallbackUrl: 'https://www.makemytrip.com',
  );

  static const irctc = ExternalApp(
    id: 'irctc',
    name: 'IRCTC',
    category: 'travel',
    icon: '🚆',
    androidPackage: 'com.cris.utsonmobile',
    iosScheme: 'irctc://',
    fallbackUrl: 'https://www.irctc.co.in',
  );

  // Shopping
  static const amazon = ExternalApp(
    id: 'amazon',
    name: 'Amazon',
    category: 'shopping',
    icon: '📦',
    androidPackage: 'in.amazon.mShop.android.shopping',
    iosScheme: 'amazon://',
    fallbackUrl: 'https://www.amazon.in',
  );

  static const flipkart = ExternalApp(
    id: 'flipkart',
    name: 'Flipkart',
    category: 'shopping',
    icon: '🛒',
    androidPackage: 'com.flipkart.android',
    iosScheme: 'flipkart://',
    fallbackUrl: 'https://www.flipkart.com',
  );

  // Bills & Payments
  static const googlePay = ExternalApp(
    id: 'gpay',
    name: 'Google Pay',
    category: 'bills',
    icon: '💳',
    androidPackage: 'com.google.android.apps.nbu.paisa.user',
    iosScheme: 'gpay://',
    fallbackUrl: 'https://pay.google.com',
  );

  static const phonePe = ExternalApp(
    id: 'phonepe',
    name: 'PhonePe',
    category: 'bills',
    icon: '📱',
    androidPackage: 'com.phonepe.app',
    iosScheme: 'phonepe://',
    fallbackUrl: 'https://www.phonepe.com',
  );

  static const paytm = ExternalApp(
    id: 'paytm',
    name: 'Paytm',
    category: 'bills',
    icon: '💰',
    androidPackage: 'net.one97.paytm',
    iosScheme: 'paytm://',
    fallbackUrl: 'https://paytm.com',
  );

  /// All registered apps
  static const List<ExternalApp> all = [
    zomato, swiggy, uberEats,
    uber, ola, rapido,
    bookMyShow, makemytrip, irctc,
    amazon, flipkart,
    googlePay, phonePe, paytm,
  ];

  /// Find app by keyword match
  static ExternalApp? findByKeyword(String text) {
    final lower = text.toLowerCase();

    // Direct name matches
    for (final app in all) {
      if (lower.contains(app.name.toLowerCase()) || lower.contains(app.id)) {
        return app;
      }
    }

    // Category / intent matches
    if (lower.contains('order food') || lower.contains('food delivery') || lower.contains('hungry')) {
      return zomato;
    }
    if (lower.contains('book cab') || lower.contains('book ride') || lower.contains('taxi') || lower.contains('ride')) {
      return uber;
    }
    if (lower.contains('book ticket') || lower.contains('movie') || lower.contains('show')) {
      return bookMyShow;
    }
    if (lower.contains('book flight') || lower.contains('book hotel') || lower.contains('travel')) {
      return makemytrip;
    }
    if (lower.contains('book train') || lower.contains('train ticket') || lower.contains('railway')) {
      return irctc;
    }
    if (lower.contains('shop') || lower.contains('buy online') || lower.contains('order online')) {
      return amazon;
    }
    if (lower.contains('pay bill') || lower.contains('recharge') || lower.contains('send money') || lower.contains('upi')) {
      return googlePay;
    }

    return null;
  }

  /// Get apps by category
  static List<ExternalApp> byCategory(String category) {
    return all.where((a) => a.category == category).toList();
  }
}
