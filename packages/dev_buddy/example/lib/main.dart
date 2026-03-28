import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dev_buddy/dev_buddy.dart';

import 'screens/product_list_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/inspector_screen.dart';

void main() {
  runApp(const DevBuddyExampleApp());
}

/// A realistic mini e-commerce app ("ShopBuddy") that demonstrates
/// how DevBuddy works in a real application.
///
/// DevBuddy runs silently in the background. The floating pill in
/// the corner shows live FPS. Tap it to open the diagnostic panel
/// and see what issues DevBuddy has detected.
///
/// The app has intentional but realistic performance problems:
/// - Product grid: no const constructors → excessive rebuilds
/// - Product images: full resolution → memory growth
/// - Cart: setState rebuilds entire list → jank on quantity changes
/// - Checkout: slow API → 3s network delay
class DevBuddyExampleApp extends StatelessWidget {
  const DevBuddyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopBuddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      // === DevBuddy Setup (1 line) ===
      // Wraps the entire app. In release builds, this compiles to zero.
      builder: (context, child) => DevBuddyOverlayImpl(
        enabled: kDebugMode,
        modules: [
          PerformanceModule(),
          ErrorTranslatorModule(),
          NetworkModule(),
          MemoryModule(),
          RebuildTrackerModule(),
        ],
        child: child!,
      ),
      home: const _ShopBuddyHome(),
    );
  }
}

class _ShopBuddyHome extends StatefulWidget {
  const _ShopBuddyHome();

  @override
  State<_ShopBuddyHome> createState() => _ShopBuddyHomeState();
}

class _ShopBuddyHomeState extends State<_ShopBuddyHome> {
  int _currentIndex = 0;

  final _screens = const [
    ProductListScreen(),
    CartScreen(),
    InspectorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: 'Inspector',
          ),
        ],
      ),
    );
  }
}
