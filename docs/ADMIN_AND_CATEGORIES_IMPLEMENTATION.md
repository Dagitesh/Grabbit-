# Admin Role & Dynamic Categories – Implementation Summary

## What Was Implemented

### 1. Admin user role
- **User.role** already supports `ADMIN`, `VENDOR`, `CUSTOMER` (backend constants and validation).
- **Registration**: Only **Customer** and **Vendor** are shown in the Flutter role dropdown. Admin cannot be chosen.
- **Creating an admin**: Set a user’s role to `ADMIN` in the database, or use a protected admin-creation flow (e.g. only existing admins can create new admins). Example in PostgreSQL:
  ```sql
  UPDATE users SET role = 'ADMIN' WHERE email = 'admin@example.com';
  ```

### 2. Vendor registration and approval
- On **Vendor** registration, a **VendorProfile** is created with **is_approved = false**.
- After a successful vendor sign-up, a **popup** is shown:  
  *"Thank you for registering as a vendor! Our team will review your application and reach out to you soon. In the meantime, you can log in or register as a customer to explore Grabbit's services."*  
  Then the user is sent to the OTP verification screen.
- **Creating deals**: A vendor can create deals only if their profile is approved. The backend returns 403 with a clear message if they are not approved.

### 3. Dynamic categories (Explore page)
- **DB**: `categories` table: `id`, `name`, `icon`, `created_at`, `updated_at`. Migration seeds Bakery, Veggies, Meals, Dairy, Meat.
- **Deals**: `deals.category_id` references `categories(id)`. The legacy `category` string column is kept for compatibility.
- **APIs**:
  - **GET /api/admin/categories** (public): list categories for the Explore page.
  - **POST/PUT/DELETE /api/admin/categories** (admin only): create, update, delete categories.
- **Flutter**: `CategoryProvider` loads categories from the API. The Explore home screen shows a horizontal list of categories from the API; selecting one filters deals by `categoryId`.

### 4. AppConfig (intro image)
- **DB**: `app_config` table: `id`, `intro_image_url`, `updated_at`.
- **APIs**:
  - **GET /api/admin/app-config** (public): returns `intro_image_url` (and optionally other config).
  - **PUT /api/admin/app-config** (admin only): update intro image URL.
- **Flutter**: Admin **Settings** screen has a field for the intro image URL and a Save button. The intro/landing screen can later be updated to load and display this URL.

### 5. Admin dashboard and workflows
- **GET /api/admin/dashboard** (admin only): returns counts for total users, total vendors, pending vendors, total deals, total orders, completed orders (and optional revenue).
- **GET /api/admin/vendors/pending** (admin only): list vendor profiles with `is_approved = false` and their user info.
- **PATCH /api/admin/vendors/:userId/approve** and **.../reject** (admin only): set vendor approval status.
- **Flutter**:
  - **AppGate**: If the current user’s role is `ADMIN`, the app shows **AdminShellScreen** (bottom nav: Dashboard, Vendors, Categories, Settings).
  - **Dashboard**: Shows the stats from the dashboard API.
  - **Vendors**: Lists pending vendors with Approve/Reject.
  - **Categories**: List, add, edit, delete categories (names and icons).
  - **Settings**: Edit intro image URL and save.

### 6. Notifications (structure only)
- No separate notifications table or API was added. Notifications (e.g. “new vendor registered”) can be added later (e.g. a `notifications` table and **GET /api/admin/notifications**), and the admin dashboard can show a bell icon that loads them.

---

## Files Touched / Added

### Backend
- **migrations/002_admin_categories_appconfig.sql** – categories, app_config, deal category_id, seed categories.
- **modules/category/category.model.js** – Category model.
- **modules/appConfig/appConfig.model.js** – AppConfig model.
- **modules/deal/deal.model.js** – added `category_id`.
- **modules/deal/deal.routes.js** – vendor approval check for POST deal; `categoryId` filter and `category_id` in create/update.
- **modules/auth/auth.service.js** – block self-registration as Admin; create VendorProfile with `is_approved: false` when role is VENDOR.
- **config/associations.js** – Category and Deal ↔ Category.
- **server.js** – load Category and AppConfig models; mount **admin** routes at `/api/admin`.
- **modules/admin/admin.routes.js** – public GET categories and app-config; admin-only dashboard, vendors/pending, approve/reject, categories CRUD, app-config PUT.

### Flutter
- **core/constants/api_constants.dart** – admin and category endpoints.
- **core/models/category_model.dart**, **app_config_model.dart** – models with fromJson/toJson and icon mapping.
- **core/api/api_service.dart** – getCategories, getAppConfig, getAdminDashboard, getAdminPendingVendors, adminApproveVendor, adminRejectVendor, adminCreateCategory, adminUpdateCategory, adminDeleteCategory, adminUpdateAppConfig; getDeals extended with categoryId.
- **features/customer/home/providers/category_provider.dart** – loads categories from API.
- **features/customer/home/providers/deal_provider.dart** – selectedCategoryId and setFilters(categoryId).
- **features/customer/home/presentation/widgets/category_filter_row.dart** – uses `List<CategoryModel>` from API; selection by category id.
- **features/customer/home/presentation/screens/customer_home_screen.dart** – uses CategoryProvider and passes categories + selectedCategoryId to filter row.
- **features/auth/presentation/screens/register_screen.dart** – after successful vendor registration, shows the thank-you popup, then navigates to OTP.
- **app_gate.dart** – if role is ADMIN, show AdminShellScreen.
- **features/admin/shell/admin_shell_screen.dart** – admin bottom nav and screens.
- **features/admin/dashboard/** – dashboard screen and provider (stats).
- **features/admin/vendors/** – pending vendors screen and provider (list, approve, reject).
- **features/admin/categories/** – categories screen and provider (list, add, edit, delete).
- **features/admin/settings/** – settings screen and provider (intro image URL).
- **main.dart** – providers for CategoryProvider, AdminDashboardProvider, AdminPendingVendorsProvider, AdminCategoriesProvider, AdminSettingsProvider.

---

## How to Run

1. **Database**  
   Run the migration (after 001):
   ```bash
   psql -U postgres -d grabbit_db -f backend/migrations/002_admin_categories_appconfig.sql
   ```
   Or rely on Sequelize `sync({ alter: true })` to create new tables/columns (migration still recommended for seeds and constraints).

2. **Create an admin user**  
   Either:
   - Insert a user with role `ADMIN`, or  
   - Update an existing user:  
     `UPDATE users SET role = 'ADMIN' WHERE email = 'your@email.com';`  
   Then log in with that user to see the Admin shell (Dashboard, Vendors, Categories, Settings).

3. **Vendor flow**  
   Register as Vendor → see thank-you popup → verify OTP → log in. Vendor cannot create deals until an admin approves them from **Admin → Vendors** (Approve).

4. **Categories**  
   Explore page loads categories from **GET /api/admin/categories**. Admins manage categories under **Admin → Categories**; new categories show up on Explore after refresh.

5. **Intro image**  
   Admin **Settings** screen: set **Intro image URL** and Save. The intro/landing screen can be updated later to call **GET /api/admin/app-config** and display the image.

---

## Optional Next Steps

- **Notifications**: Add a `notifications` table and **GET /api/admin/notifications**; create a row when a vendor registers (and optionally on complaints/reviews); show a bell and list in the admin app.
- **Intro screen**: In Flutter, call `getAppConfig()`, and if `intro_image_url` is set, show it on the intro/landing screen.
- **Deal create (vendor app)**: When creating/editing a deal, let the vendor pick a category from the categories API (e.g. dropdown) and send `category_id` in the request.
