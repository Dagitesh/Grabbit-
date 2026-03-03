# Grabbit Vendor App

## Opening the vendor UI

- **Log in with a user that has role `VENDOR`.** After login, the app shows the **Vendor** bottom nav (Dashboard, My Deals, Orders, Profile).
- **Log in with a user that has role `CUSTOMER`** (or any other role): the app shows the **Customer** bottom nav (Home, My Orders, Favorites, Profile).
- The app uses **GET /api/me** on startup (when a token exists) to load the current user and role, then routes to the correct shell.

## Vendor structure

```
lib/features/vendor/
  dashboard/   data (VendorDashboardModel), providers, presentation (VendorDashboardScreen)
  deals/       providers (VendorDealProvider), presentation (VendorMyDealsScreen, CreateDealScreen, EditDealScreen, VendorDealCard), deal_form_mixin
  orders/      data (VendorOrderModel), providers, presentation (VendorOrdersScreen, VendorOrderDetailScreen)
  profile/     data (VendorProfileModel), providers, presentation (VendorProfileScreen, EditVendorProfileScreen)
  shell/       VendorShellScreen (bottom nav)
```

## API (VendorApiService)

- **GET /api/vendor/profile** – vendor profile
- **PUT /api/vendor/profile** – update profile (business_name, business_description, phone, location)
- **GET /api/vendor/dashboard** – stats (totalDeals, activeDeals, expiredDeals, totalOrders, revenue?)
- **GET /api/vendor/deals** – list of vendor’s deals
- **GET /api/vendor/orders** – list of vendor’s orders
- **POST /api/deals** – create deal
- **PUT /api/deals/:id** – update deal
- **GET /api/deals/:id** – get deal (for edit pre-fill)

## Expected JSON (backend)

**GET /api/vendor/dashboard**
```json
{
  "vendor": { "id": "...", "user_id": "...", "business_name": "...", "phone": "...", "is_approved": true },
  "stats": {
    "totalDeals": 10,
    "activeDeals": 6,
    "expiredDeals": 4,
    "totalOrders": 25,
    "revenue": 199.50
  }
}
```

**GET /api/vendor/orders**
```json
[
  {
    "id": "...",
    "deal_id": "...",
    "deal_title": "...",
    "customer_name": "John",
    "status": "Created",
    "created_at": "2026-03-02T12:00:00.000Z",
    "discounted_price": "4.59",
    "quantity": 1
  }
]
```

## Run

Same as customer app: `flutter pub get` then `flutter run`. Log in with a **VENDOR** account to see the vendor UI.
