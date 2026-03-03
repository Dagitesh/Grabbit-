# Grabbit Customer App

## Structure

```
lib/
  core/
    api/           api_service.dart
    theme/         app_colors.dart
    widgets/       loading_overlay, empty_state, error_view
    utils/         api_error_handler
    constants/     api_constants
    network/       api_client (Dio + JWT)
    services/      secure_storage_service
  features/
    auth/          (existing)
    customer/
      home/        data/deal_model, providers (deal, favorites), presentation (customer_home_screen, favorites_screen, widgets)
      deals/       providers/deal_detail_provider, presentation (deal_detail_screen, confirmation flow)
      orders/      data/order_model, providers/order_provider, presentation (my_orders_screen, order_detail_screen)
      profile/     presentation (customer_profile_screen)
      shell/       customer_nav_provider, customer_shell_screen
  main.dart
```

## Bottom navigation

1. **Home** – Paginated deals grid, search, price filter, pull to refresh, favorite icon on cards.
2. **My Orders** – List of orders; tap for order details.
3. **Favorites** – Locally persisted favorite deals (SharedPreferences).
4. **Profile** – GET /api/me, name, email, role, logout.

## API usage

- **GET /api/deals** – `page`, `limit`, `search`, `minPrice`, `maxPrice`, `active`. Response: `{ items: [...], meta: { page, limit, total, totalPages } }`.
- **GET /api/deals/:id** – Single deal.
- **GET /api/orders** – List of orders (array or `{ orders: [] }`).
- **POST /api/orders** – Body: `{ deal_id, quantity? }`. Returns created order (e.g. `{ id }`).
- **GET /api/me** – Current user (id, full_name, email, role, etc.).

## Expected JSON (backend)

**Deal (list/detail):**
```json
{
  "id": "uuid",
  "vendor_id": "uuid",
  "title": "Mystery Breakfast Bag",
  "description": "...",
  "original_price": "15.00",
  "discounted_price": "4.59",
  "quantity_available": 20,
  "expiry_date": "2026-03-10T23:59:59.000Z",
  "is_active": true
}
```

**Orders list:**
```json
[
  {
    "id": "uuid",
    "deal_id": "uuid",
    "deal_title": "Mystery Breakfast Bag",
    "status": "Created",
    "created_at": "2026-03-02T12:00:00.000Z",
    "discounted_price": "4.59",
    "quantity": 1
  }
]
```

**POST /api/orders response:**
```json
{ "id": "order-uuid" }
```

## Run

```bash
cd grabbit_app
flutter pub get
flutter run
```

Set backend URL: `flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000`

## Auth

App starts on **CustomerShell** (Home tab). For protected endpoints (orders, profile, deals if backend requires auth), ensure the user is logged in; use the auth flow (login/register) and store tokens via `flutter_secure_storage`. The existing `ApiClient` adds the JWT and refreshes on 401.
