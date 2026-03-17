# Grabbit Schema v2 – Change Analysis & Migration Guide

This document describes the refactor from the previous schema to the new entity structure, constraints, and how to migrate safely without changing UI style.

---

## 1. Entity Structure Summary

| Entity | Purpose |
|--------|--------|
| **User** | Base auth: `email`, `phone`, `password_hash`, `role` (Admin/Vendor/Customer). Keeps `full_name`, `is_verified`, OTP fields. |
| **CustomerProfile** | 1:1 with User (`user_id`). New table. |
| **VendorProfile** | 1:1 with User. **Added:** `tin` (UNIQUE). |
| **Location** | Standalone; multiple per vendor. `vendor_id`, `lat`, `long`, `address`. |
| **Deal** | Linked to Vendor + optional Location. **New/renamed:** `discount_price`, `total_quantity`, `available_quantity`, `start_time`, `expiry_time`, `location_id`. Legacy `discounted_price`, `quantity_available`, `expiry_date` kept during transition. |
| **Order** | Linked to Customer + Deal. **Added:** unique `claim_code`. |
| **Payment** | 1:1 with Order. **New table.** `gateway_provider` (Telebirr/Chapa), `transaction_reference` (UNIQUE). |
| **Review** | 1:1 with Order. **New table.** `rating` (1–5), `comment`. |

---

## 2. Constraints Implemented

- **UNIQUE:** `User.email`, `User.phone` (nullable allowed), `VendorProfile.tin`, `Payment.transaction_reference`, `Order.claim_code`.
- **CHECK:**  
  - `discount_price < original_price`  
  - `available_quantity <= total_quantity`  
  - `expiry_time > start_time`  
  - `rating BETWEEN 1 AND 5`
- **Safety:** `ON DELETE RESTRICT` on transaction-related FKs (e.g. Order → User/Deal, Payment → Order, Review → Order). Other FKs (e.g. Location → User) use CASCADE/SET NULL as appropriate.

---

## 3. File-Level Change Summary

### Backend (Node/Sequelize)

| File | Changes |
|------|--------|
| `backend/migrations/001_grabbit_schema_v2.sql` | **New.** Run once to alter/create tables and constraints. |
| `backend/src/modules/user/user.model.js` | `password` → `password_hash`; `phone` unique. Scopes use `password_hash`. |
| `backend/src/modules/auth/auth.service.js` | Uses `password_hash` for create and compare. |
| `backend/src/modules/vendor/vendorProfile.model.js` | Added `tin` (STRING, unique). |
| `backend/src/modules/customer/customerProfile.model.js` | **New.** CustomerProfile model. |
| `backend/src/modules/location/location.model.js` | **New.** Location model. |
| `backend/src/modules/deal/deal.model.js` | Added `location_id`, `discount_price`, `total_quantity`, `available_quantity`, `start_time`, `expiry_time`; kept legacy columns for sync safety. |
| `backend/src/modules/order/order.model.js` | Added `claim_code` (unique); FKs set to `RESTRICT`. |
| `backend/src/modules/payment/payment.model.js` | **New.** Payment model. |
| `backend/src/modules/review/review.model.js` | **New.** Review model. |
| `backend/src/config/associations.js` | CustomerProfile, Location, Payment, Review; Deal ↔ Location; Order ↔ Payment, Review. |
| `backend/src/server.js` | Require new models before associations. |
| `backend/src/modules/deal/deal.routes.js` | Accept/serialize `location_id`, `discount_price`, `total_quantity`, `available_quantity`, `start_time`, `expiry_time`; keep legacy names in API responses for compatibility. |
| `backend/src/modules/order/order.routes.js` | Generate and persist unique `claim_code`; use `available_quantity`/`expiry_time` with fallbacks; include `claim_code` in responses. |
| `backend/src/modules/vendor/vendor.routes.js` | Profile GET/PUT accept and return `tin`; deal includes for orders include `discount_price`. |

### Flutter (Dart)

| File | Changes |
|------|--------|
| `grabbit_app/lib/features/customer/orders/data/order_model.dart` | Added `claimCode`; `fromJson`/`toJson`. |
| `grabbit_app/lib/features/customer/home/data/deal_model.dart` | Added `locationId`, `totalQuantity`, `startTime`, `expiryTime`; fromJson uses `discount_price`/`available_quantity`/`expiry_time` with fallbacks; `toJson` added. |
| `grabbit_app/lib/features/vendor/profile/data/vendor_profile_model.dart` | Added `tin`; `toJson`. |
| `grabbit_app/lib/features/vendor/orders/data/vendor_order_model.dart` | Added `claimCode`; `toJson`. |
| `grabbit_app/lib/core/models/customer_profile_model.dart` | **New.** fromJson/toJson. |
| `grabbit_app/lib/core/models/location_model.dart` | **New.** fromJson/toJson. |
| `grabbit_app/lib/core/models/payment_model.dart` | **New.** fromJson/toJson. |
| `grabbit_app/lib/core/models/review_model.dart` | **New.** fromJson/toJson. |
| `grabbit_app/lib/core/api/vendor_api_service.dart` | `updateProfile(tin)`; `createDeal`/`updateDeal` optional `locationId`, `totalQuantity`, `startTime`, `expiryTime`. |

---

## 4. Migration Steps (Recommended Order)

1. **Back up the database** (e.g. `pg_dump`).
2. **Run the SQL migration**  
   From project root:  
   `psql -U your_user -d your_grabbit_db -f backend/migrations/001_grabbit_schema_v2.sql`  
   Or run the script in your SQL client.
3. **Backend**  
   - Install dependencies if needed: `cd backend && npm install`.  
   - Start (or restart) the server. It loads new models and associations; `sync({ alter: true })` will add any missing columns and will not drop legacy deal columns (they remain in the model).
4. **Flutter**  
   - No UI changes required. Models and API service support new fields; existing screens keep working.  
   - When you add Location/Payment/Review UI, use the new models and optional API params.

---

## 5. Specific Line / Behaviour Notes

- **User password:** Column is `password_hash` after migration; auth reads/writes `password_hash`. If you run Sequelize sync before the SQL migration, you may temporarily have both `password` and `password_hash`; run the migration so only `password_hash` remains.
- **Deals:** API still returns `discounted_price` and `quantity_available` (from `discount_price`/`available_quantity`) so existing Flutter code continues to work. New fields can be sent in create/update when you add UI.
- **Orders:** Every new order gets a unique `claim_code`; existing orders get one when the migration runs. Flutter `OrderModel` and `VendorOrderModel` include `claimCode`; you can show it on order details when ready.
- **Vendor profile:** Backend and Flutter support `tin`; add a TIN field to the vendor profile screen when needed.
- **Locations:** Backend has the Location model and Deal ↔ Location association. Add vendor location CRUD and deal–location picker in a later iteration without changing current UI style.

---

## 6. Rollback (If Needed)

- Restore DB from backup.  
- Revert code (git) to the previous backend and Flutter versions.  
- The migration does not drop legacy deal columns, so reverting only the app and keeping the DB as-is is possible; ensure the reverted app still understands the columns your DB has.
