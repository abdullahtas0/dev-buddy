# ShopBuddy - DevBuddy Example App

A realistic mini e-commerce application that demonstrates all DevBuddy diagnostic modules in action. The app includes **intentional performance issues** so you can see exactly how DevBuddy detects, reports, and suggests fixes for common Flutter problems.

## Quick Start

```bash
# From the monorepo root
melos bootstrap

# Run the example
cd packages/dev_buddy/example
flutter run
```

## App Overview

ShopBuddy is a 5-screen shopping app with bottom navigation:

| Tab | Screen | Purpose |
|-----|--------|---------|
| Shop | `ProductListScreen` | Browse 50 products in a grid |
| - | `ProductDetailScreen` | View product details, add to cart |
| Cart | `CartScreen` | Manage cart items, adjust quantities |
| - | `CheckoutScreen` | Order summary, simulated payment |
| Inspector | `InspectorScreen` | View raw DevBuddy diagnostics |

## DevBuddy Integration

The entire integration is a single widget wrapper in `main.dart`:

```dart
MaterialApp(
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
)
```

- **Debug mode:** Full overlay with floating FPS pill + diagnostic panel
- **Release mode:** Compiles to zero bytes via conditional compilation

## Intentional Performance Issues

Each issue is designed to trigger a specific DevBuddy module. Comments in the code mark each one.

### 1. Excessive Widget Rebuilds

**File:** `product_list_screen.dart`
**Module:** RebuildTrackerModule + PerformanceModule

`_ProductCard` has no `const` constructor. Every scroll frame creates new widget instances for all visible cards, causing unnecessary rebuilds.

```dart
// BUG: No const, rebuilds on every scroll frame.
class _ProductCard extends StatelessWidget { ... }
```

**What DevBuddy shows:** Rebuild count warnings + FPS drops during fast scrolling.

### 2. Heavy Paint Operations

**File:** `product_list_screen.dart`
**Module:** PerformanceModule

Each product card uses `BoxShadow` + `Opacity` + `ClipRRect`, creating expensive composite layers that multiply across the grid.

**What DevBuddy shows:** Frame duration spikes and jank detection events.

### 3. Full-Resolution Images Without Caching

**Files:** `product_list_screen.dart`, `product_detail_screen.dart`, `cart_screen.dart`
**Module:** MemoryModule

All `Image.network()` calls load 400x400 images at full resolution without `cacheWidth`/`cacheHeight`. As the user scrolls, decoded image data accumulates in memory.

```dart
Image.network(
  product.imageUrl,  // 400x400 from picsum.photos
  height: 140,       // Displayed at 140px but decoded at full 400px
  fit: BoxFit.cover,
)
```

**What DevBuddy shows:** RSS memory growth warnings, memory spike events.

### 4. Full ListView Rebuild on State Change

**File:** `cart_screen.dart`
**Module:** RebuildTrackerModule

Tapping +/- on any cart item calls `setState(() {})` on the entire screen, forcing every `CartItem` tile to rebuild instead of just the changed one.

```dart
void _onCartChanged() => setState(() {});
```

**What DevBuddy shows:** Excessive rebuild warnings when adjusting quantities.

### 5. Slow Network Request

**File:** `checkout_screen.dart`
**Module:** NetworkModule

The checkout button sends an HTTP GET to `httpbin.org/delay/3`, which intentionally takes 3 seconds to respond.

```dart
final request = await client.getUrl(
  Uri.parse('https://httpbin.org/delay/3'),
);
```

**What DevBuddy shows:** Slow network request warning (>2000ms threshold), request timing in the network tab.

## Screens in Detail

### ProductListScreen (Shop Tab)

- 2-column `GridView.builder` displaying 50 fake products
- Each card shows: image, name, price, star rating, review count
- Tap navigates to `ProductDetailScreen`
- Scrolling triggers PerformanceModule and RebuildTrackerModule events

### ProductDetailScreen

- Full product info: large image (350px), name, category, price, rating, description
- "Add to Cart" button with snackbar confirmation
- Uses `CartModel.instance` singleton for state
- Large image load triggers MemoryModule

### CartScreen (Cart Tab)

- Lists all cart items with product image, name, price
- +/- buttons adjust quantity, remove button when quantity reaches 0
- Shows total price and "Checkout" button
- Empty state placeholder when cart is empty

### CheckoutScreen

- Order summary with all items and total
- "Place Order" button triggers 3-second network request
- Loading spinner during request
- Success screen after order placement
- Demonstrates NetworkModule slow request detection

### InspectorScreen (Inspector Tab)

Shows what AI tools (Claude Code, Cursor) see through the MCP integration:

| Button | Action |
|--------|--------|
| **Snapshot** | Displays `DevBuddyEngine.snapshot()` as formatted JSON |
| **Events** | Lists the last 10 diagnostic events with timestamps |
| **Markdown** | Exports a full diagnostic report in GitHub-flavored Markdown |
| **Clear** | Removes all logged events and resets counters |

The inspector uses a dark terminal-style display with selectable text for easy copying.

## Data

### Product Data (`fake_products.dart`)

Generates 50 products with:
- **Names:** 20 rotating names (Wireless Headphones, Smart Watch, Running Shoes, etc.)
- **Prices:** $9.99 - $199.99 range
- **Images:** `picsum.photos` placeholder images (400x400)
- **Ratings:** 3.5 - 5.0 stars
- **Reviews:** 10 - 510 review counts
- **Categories:** Electronics, Clothing, Home, Sports, Books (cycling)

### Cart Model (`cart_model.dart`)

Singleton `ChangeNotifier` managing cart state:
- `addProduct(Product)` - Add or increment
- `updateQuantity(int productId, int delta)` - Adjust quantity
- `clear()` - Empty cart
- `totalPrice` / `itemCount` getters

## Maestro E2E Tests

Automated UI flows in `.maestro/`:

| Flow | Description |
|------|-------------|
| `test_devbuddy_v2.yaml` | Full ShopBuddy journey: browse, add to cart, inspect diagnostics |
| `test_devbuddy.yaml` | Original demo flow with event generation |
| `test_panel_only.yaml` | Focused panel integration test |

Run with:
```bash
maestro test .maestro/test_devbuddy_v2.yaml
```

The v2 flow generates 7 screenshots documenting the complete user journey:
`demo_01_shop`, `demo_02_scrolled`, `demo_03_detail`, `demo_04_cart`, `demo_05_inspector`, `demo_06_snapshot`, `demo_07_panel`

## Project Structure

```
example/
├── lib/
│   ├── main.dart                    # App entry, DevBuddy setup
│   ├── models/
│   │   ├── product.dart             # Product data model
│   │   └── cart_model.dart          # Cart state (ChangeNotifier singleton)
│   ├── data/
│   │   └── fake_products.dart       # 50 generated products
│   └── screens/
│       ├── product_list_screen.dart  # Product grid (Shop tab)
│       ├── product_detail_screen.dart # Product detail view
│       ├── cart_screen.dart          # Cart management (Cart tab)
│       ├── checkout_screen.dart      # Payment simulation
│       └── inspector_screen.dart     # DevBuddy diagnostics (Inspector tab)
├── .maestro/                         # E2E test flows
├── pubspec.yaml
└── analysis_options.yaml
```

## Requirements

- Flutter >= 3.10.0
- Dart >= 3.11.3
- Network access (for product images and checkout simulation)
