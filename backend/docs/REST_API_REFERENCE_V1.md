# Grabbit

## REST API Reference — v1

**Base URL (example)**

```
Production:  https://your-api-host.com
Development: http://localhost:3000
```

**Default headers (JSON endpoints)**

| Header         | Value              |
|----------------|--------------------|
| `Content-Type` | `application/json` |
| `Accept`       | `application/json` |

**Multipart endpoints** use `Content-Type: multipart/form-data` (do not set `Content-Type` manually; let the client set the boundary).

---

## 2. Authentication

### Mechanism

- **Bearer JWT** in the `Authorization` header:
  - `Authorization: Bearer <access_token>`
- **Access token** encodes `sub` (user UUID) and `role` (`CUSTOMER`, `VENDOR`, or `ADMIN`).
- **Refresh token** is a separate JWT (type `refresh`), sent in the **JSON body** to `POST /api/auth/refresh-token`.

### Token lifetimes (server defaults)

| Token          | Lifetime | Notes                                      |
|----------------|----------|--------------------------------------------|
| Access token   | **15m**  | Config: `ACCESS_TOKEN_EXPIRY` (`15m`)      |
| Refresh token  | **7d**   | Config: `REFRESH_TOKEN_EXPIRY` (`7d`)      |
| Login response | `expiresIn: 900` | Seconds until access token expiry (900 = 15 min) |

### OTP (customer registration)

- OTP length: **6** digits; expiry: **5** minutes (`OTP_EXPIRY_MINUTES`).
- Set `MOCK_OTP_LOG=true` in development to log OTP to server console.

### Logout

**There is no `POST /logout` endpoint.** JWTs are **stateless**. The client **discards** `accessToken` and `refreshToken` locally. To invalidate access before expiry, use short-lived access tokens and rotate refresh tokens (refresh endpoint issues a **new** refresh token).

---

### Login

**POST**  
`/api/auth/login`

Short description: Authenticate with email and password. Returns user profile and token pair. **Requires verified email** (`is_verified: true`).

🔐 **Auth required:** No

**REQUEST HEADERS**

```
Content-Type: application/json
```

**REQUEST BODY (JSON)**

```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**RESPONSE 200 (Success)**

```json
{
  "user": {
    "id": "uuid",
    "full_name": "Jane Doe",
    "email": "user@example.com",
    "phone": "+251...",
    "role": "CUSTOMER",
    "is_verified": true
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 900
}
```

**ERROR RESPONSES**

```json
{
  "success": false,
  "message": "Invalid email or password"
}
```
*401 — wrong credentials*

```json
{
  "success": false,
  "message": "Account not verified. Please verify with OTP first."
}
```
*403 — valid password but email not verified*

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    { "type": "field", "msg": "Email is required", "path": "email", "location": "body" }
  ]
}
```
*422 — validation*

---

### Get current user

**GET**  
`/api/me`

Short description: Returns the authenticated user’s record (password and OTP fields excluded).

🔐 **Auth required:** Yes — **Bearer token** (any verified role that can log in: `CUSTOMER`, `VENDOR`, `ADMIN`)

**REQUEST HEADERS**

```
Authorization: Bearer <access_token>
```

**REQUEST BODY**

None

**RESPONSE 200 (Success)**

```json
{
  "id": "uuid",
  "full_name": "Jane Doe",
  "email": "user@example.com",
  "phone": "+251...",
  "role": "CUSTOMER",
  "is_verified": true,
  "created_at": "2025-01-01T12:00:00.000Z",
  "updated_at": "2025-01-01T12:00:00.000Z"
}
```

**ERROR RESPONSES**

```json
{ "success": false, "message": "Access token required" }
```
*401 — missing/invalid Bearer token*

```json
{ "success": false, "message": "User not found" }
```
*404*

---

### Refresh token

**POST**  
`/api/auth/refresh-token`

Short description: Exchange a valid refresh token for a **new** access token and **new** refresh token.

🔐 **Auth required:** No (uses refresh token in body)

**REQUEST BODY (JSON)**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

**RESPONSE 200 (Success)**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 900
}
```

**ERROR RESPONSES**

```json
{ "success": false, "message": "Invalid refresh token" }
```
*401*

```json
{ "success": false, "message": "User not found" }
```
*401*

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [{ "msg": "Refresh token is required", "path": "refreshToken" }]
}
```
*422*

---

### Logout

**Not implemented (by design).**

Clients should **remove** stored `accessToken` and `refreshToken`. Optional: call refresh once with invalid token handling disabled only if you add a server-side blocklist in the future.

---

## 3. Core modules

### 3.1 Authentication (public + tokens)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Customer self-registration (OTP sent / stored; role forced to CUSTOMER) |
| POST | `/api/auth/login` | Login → tokens |
| POST | `/api/auth/verify-otp` | Verify email with 6-digit OTP |
| POST | `/api/auth/refresh-token` | Rotate access + refresh tokens |

---

### 3.2 Users & session

Short description: Current user profile for any authenticated principal.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/me` | Current user JSON (excludes secrets) |

---

### 3.3 System & uploads

Short description: Health check and generic image upload for building absolute media URLs.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Liveness payload |
| POST | `/api/upload` | Multipart upload (`file` field) → `{ url }` |

---

### 3.4 Catalog & geography (public)

Short description: Subcities and marketplace deals/reviews as consumed by customers (admin-removed deals hidden from public list/detail).

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/subcities` | List Addis subcities (sorted) |
| GET | `/api/deals` | Paginated/filtered deals (`removed_by_admin` excluded) |
| GET | `/api/deals/:id` | Single deal (404 if removed by admin) |
| GET | `/api/deals/:dealId/reviews` | Public reviews for a deal |

---

### 3.5 Deals (vendor write)

Short description: Vendors create and update their own listings. Admin-moderated deals cannot be edited.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/deals` | Create deal (requires `subcity_id`, `category_id`, pricing rules) |
| PUT | `/api/deals/:id` | Update own deal |

---

### 3.6 Orders & reviews (customer)

Short description: Customers place orders on deals, list their orders, cancel within rules, and submit one review per order.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/orders` | Create order (reserve quantity, notify vendor) |
| GET | `/api/orders` | List **current user’s** orders (any authenticated role; typically customer) |
| PATCH | `/api/orders/:id/cancel` | Cancel order (time window rules) |
| POST | `/api/orders/:id/review` | Submit review (1–5 stars); notifies vendor |

---

### 3.7 Vendor portal

Short description: Vendor profile, dashboard stats, own deals, orders on their deals, and in-app notifications.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/vendor/profile` | Vendor profile |
| PUT | `/api/vendor/profile` | Update vendor profile |
| GET | `/api/vendor/dashboard` | Profile + aggregate stats |
| GET | `/api/vendor/deals` | All deals for this vendor (includes moderation fields if removed) |
| GET | `/api/vendor/orders` | Orders for vendor’s deals |
| GET | `/api/vendor/notifications` | Notification feed (`?unread=true`, `limit`) |
| PATCH | `/api/vendor/notifications/:id/read` | Mark one read |
| PATCH | `/api/vendor/notifications/read-all` | Mark all read |

---

### 3.8 Admin

Short description: Categories, app config, vendor onboarding, dashboard metrics, and deal moderation. Most routes require role `ADMIN`. **Public** admin routes: categories list + app-config **GET** only.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin/categories` | **Public** — list categories |
| GET | `/api/admin/app-config` | **Public** — intro image URL, etc. |
| POST | `/api/admin/vendors/register` | **ADMIN** — multipart vendor + PDF certificate |
| GET | `/api/admin/vendors/pending` | **ADMIN** — legacy; returns `[]` |
| PATCH | `/api/admin/vendors/:userId/approve` | **ADMIN** — **410 Gone** (legacy) |
| PATCH | `/api/admin/vendors/:userId/reject` | **ADMIN** — **410 Gone** (legacy) |
| GET | `/api/admin/vendors` | **ADMIN** — list vendors + branches |
| POST | `/api/admin/categories` | **ADMIN** — create category |
| PUT | `/api/admin/categories/:id` | **ADMIN** — update category |
| DELETE | `/api/admin/categories/:id` | **ADMIN** — delete category |
| PUT | `/api/admin/app-config` | **ADMIN** — update app config |
| GET | `/api/admin/dashboard` | **ADMIN** — aggregate stats |
| GET | `/api/admin/deal-moderation-reasons` | **ADMIN** — preset removal reasons |
| GET | `/api/admin/deals` | **ADMIN** — list deals (moderation, images, vendor) |
| POST | `/api/admin/deals/:id/remove` | **ADMIN** — remove deal + notify vendor |

---

## 4. Endpoint reference (detail)

Standard error envelope (most routes):

```json
{
  "success": false,
  "message": "Human-readable message",
  "errors": [ ]
}
```

`errors` is present for **422** validation and may be omitted otherwise.

---

### POST `/api/auth/register`

**Description:** Register a **customer** only. Creates user + customer profile; stores OTP. Vendors are **not** self-registered.

**Auth:** No

**Body:**

```json
{
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane@example.com",
  "phone": "+251911000000",
  "subcity_id": "uuid",
  "password": "min6chars"
}
```

**Query:** None

**200 / 201:** `201 Created`

```json
{
  "id": "uuid",
  "full_name": "Jane Doe",
  "email": "jane@example.com",
  "role": "CUSTOMER",
  "is_verified": false,
  "subcity_id": "uuid",
  "message": "Registration successful. Please verify your email with the OTP sent."
}
```

**Errors:** `400` invalid subcity · `409` email exists · `422` validation

---

### POST `/api/auth/verify-otp`

**Description:** Mark email verified after correct 6-digit OTP.

**Auth:** No

**Body:**

```json
{
  "email": "jane@example.com",
  "otpCode": "123456"
}
```

(`otp` accepted instead of `otpCode`.)

**200:**

```json
{
  "message": "Email verified successfully. You can now log in."
}
```

**Errors:** `400` invalid/expired OTP · `404` user not found · `422` validation

---

### GET `/api/health`

**Auth:** No

**200:**

```json
{
  "status": "ok",
  "timestamp": "2025-01-01T12:00:00.000Z"
}
```

---

### POST `/api/upload`

**Auth:** No (consider protecting in production)

**Body:** `multipart/form-data`, field name **`file`** (max **5 MB** typical)

**200:**

```json
{
  "success": true,
  "url": "http://localhost:3000/uploads/1234567890-abc.jpg"
}
```

**400:**

```json
{
  "success": false,
  "message": "No file uploaded"
}
```

---

### GET `/api/subcities`

**Auth:** No

**200:** Array of subcity objects (`id`, `name`, `sort_order`, …).

---

### GET `/api/deals`

**Auth:** No

**Query parameters:**

| Param | Description |
|--------|-------------|
| `page` | Page number (default 1) |
| `limit` | Page size (default 10, max 50) |
| `search` | Title/description `ILIKE` |
| `location` | Legacy location string filter |
| `category` | Category name `ILIKE` |
| `categoryId` / `category_id` | UUID |
| `subcityId` / `subcity_id` | UUID |
| `minPrice`, `maxPrice` | Filter on discounted price |
| `active=true` | Active + not expired |
| `urgentOnly=true` or `urgent=true` | Expires within 7 days |

**Note:** Results always exclude `removed_by_admin = true`.

**200:**

```json
{
  "deals": [ ],
  "data": [ ],
  "items": [ ],
  "total": 0,
  "page": 1,
  "limit": 10,
  "totalPages": 1,
  "meta": { "totalPages": 1, "total": 0, "page": 1, "limit": 10 }
}
```

Each deal: shaped prices, ISO expiry, `images` as **array** of URLs, moderation fields **stripped**.

---

### GET `/api/deals/:id`

**Auth:** No

**404** if not found or admin-removed.

---

### GET `/api/deals/:dealId/reviews`

**Auth:** No

**404** if deal missing or removed.

**200:** Array of reviews with `reviewer_name`.

---

### POST `/api/deals`

**Auth:** Yes — **VENDOR**

**Body (required fields among others):** `title`, `original_price`, `discount_price` or `discounted_price`, quantity fields, `expiry_time` or `expiry_date`, **`subcity_id`**, **`category_id`**. Optional: `description`, `images` (array of URL strings), `location_id`, `start_time`.

**Rules:** Discounted price **&lt;** original price; valid subcity/category UUIDs.

**201:** Created deal (shaped JSON, includes moderation fields if any).

**Errors:** `400` validation · `401` · `403`

---

### PUT `/api/deals/:id`

**Auth:** Yes — **VENDOR** (owner only)

**403** if not owner or **deal removed by admin**.

**Body:** Partial update (optional fields: `title`, `description`, `images`, prices, quantities, `expiry_*`, `category_id`, `subcity_id`, `is_active`, …).

---

### POST `/api/orders`

**Auth:** Yes — **CUSTOMER**

**Body:**

```json
{
  "deal_id": "uuid",
  "quantity": 1
}
```

**Rules:** Deal active, not expired, sufficient stock.

**201:** Order object + `deal_title`, `discounted_price`, `claim_code`, etc.

**Errors:** `400` business rules · `404` deal · `401` · `403`

---

### GET `/api/orders`

**Auth:** Yes — **any role** (returns rows where `user_id` = caller)

**200:** Array of enriched orders.

---

### PATCH `/api/orders/:id/cancel`

**Auth:** Yes — **CUSTOMER**

**Rules:** Owner only; not already `Cancelled`/`Completed`; not within **2 hours** of `pickup_at` window.

**200:** Updated order.

**Errors:** `400` · `404`

---

### POST `/api/orders/:id/review`

**Auth:** Yes — **CUSTOMER**

**Body:**

```json
{
  "rating": 5,
  "comment": "Great deal"
}
```

**Rules:** Rating 1–5; not cancelled; **one review per order**.

**201:** Review object.

**Errors:** `400` · `404` · `409` duplicate review

---

### Vendor routes (`/api/vendor/*`)

All require **Bearer** + role **VENDOR**.

- **GET** `/profile` — vendor profile JSON  
- **PUT** `/profile` — `{ business_name?, business_description?, phone?, location?, tin? }`  
- **GET** `/dashboard` — `{ vendor, stats }`  
- **GET** `/deals` — vendor’s deals; `images` parsed; includes moderation fields when applicable  
- **GET** `/orders` — orders for vendor’s deals + customer summary  
- **GET** `/notifications?unread=true&limit=100`  
- **PATCH** `/notifications/:id/read`  
- **PATCH** `/notifications/read-all` → `{ "success": true }`

---

### Admin — public reads

**GET** `/api/admin/categories` — no auth  
**GET** `/api/admin/app-config` — no auth  

---

### Admin — vendor register

**POST** `/api/admin/vendors/register`  
**Auth:** **ADMIN**  
**Content-Type:** `multipart/form-data`

| Field | Type | Required |
|--------|------|----------|
| `certificate` | PDF file | Yes (≤ ~15 MB) |
| `owner_email`, `initial_password`, `business_name`, `owner_name`, … | string | Per service validation |
| `branches` | JSON string | Optional array `[{ "subcity_id", "address_detail" }]` |

**201:** Registration result + profile payload.

**400:** Missing PDF / invalid payload

---

### Admin — categories / app-config / dashboard

- **POST** `/api/admin/categories` — `{ "name", "icon"? }`  
- **PUT** `/api/admin/categories/:id` — `{ "name"?, "icon"? }`  
- **DELETE** `/api/admin/categories/:id` — **204** empty body  
- **PUT** `/api/admin/app-config` — `{ "intro_image_url"?: "..." }`  
- **GET** `/api/admin/dashboard` — counts (users, vendors, deals, orders, `completedOrders`, …)

---

### Admin — deal moderation

**GET** `/api/admin/deal-moderation-reasons`  
**200:** `[{ "code": "MISLEADING", "label": "..." }, ...]`

**GET** `/api/admin/deals`  
**Query:** `page`, `limit`, `search`, `includeRemoved=true`  
**200:** `{ deals, total, page, limit, totalPages }` — deals include `images[]`, `vendor`, `category_name`, `subcity_name`.

**POST** `/api/admin/deals/:id/remove`  
**Body:** `{ "reason_code": "MISLEADING" }` (must match preset)  
**200:** `{ "success": true, "deal": { ... }, "message": "..." }`  
**Errors:** `400` invalid/already removed · `404`

---

## 5. Status lifecycles

### Order status (string field)

Current API behavior:

```
Created
  ├─→ Cancelled   (PATCH /api/orders/:id/cancel — customer, rules apply)
  └─→ Completed   (referenced in stats; no public transition endpoint in current codebase)
```

**Cancelled** orders cannot be reviewed. **Completed** / **Cancelled** cannot be cancelled again.

### Deal visibility (logical)

```
Active listing (public)  →  hidden from GET /api/deals when removed_by_admin = true
Vendor may still see row via GET /api/vendor/deals + notification deal_removed
```

### Customer account

```
Registered (is_verified: false)
  └─→ Verified (POST /verify-otp)
       └─→ Can login (POST /login)
```

### Vendor onboarding (v3)

```
Admin POST /api/admin/vendors/register
  → Vendor user exists (no separate "pending approval" API flow)
```

---

## 6. Error reference

| HTTP | Meaning | Typical `message` / use |
|------|---------|-------------------------|
| **401** | Unauthorized | Missing/invalid Bearer token; invalid refresh token; bad login |
| **403** | Forbidden | Wrong role; unverified login attempt; not deal owner; moderated deal edit |
| **404** | Not Found | Entity missing; deal hidden/removed for public; unknown API path under `/api` |
| **409** | Conflict | Duplicate review; email already registered |
| **410** | Gone | Legacy admin approve/reject vendor |
| **422** | Validation | express-validator / body rules (`errors` array populated) |
| **500** | Server error | Unhandled exception; `stack` may appear in **development** only |

### Standard formats (as implemented + common variants)

**Primary (Grabbit `errorHandler`):**

```json
{
  "success": false,
  "message": "Error description"
}
```

**With validation details (422):**

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "type": "field",
      "value": "",
      "msg": "Email is required",
      "path": "email",
      "location": "body"
    }
  ]
}
```

**API 404 (unknown `/api/...` route):**

```json
{
  "success": false,
  "message": "Not found",
  "path": "/api/unknown"
}
```

**Alternate styles (some uploads / notification read-all):**

```json
{ "success": true, "url": "..." }
```

```json
{ "success": true }
```

*Note: Not all errors use `{ "error": "message" }`; the running server standardizes on `success` + `message`.*

---

## 7. Postman testing guide

### Environment setup

Create a Postman **Environment** with:

| Variable | Example |
|----------|---------|
| `baseUrl` | `http://localhost:3000` |
| `accessToken` | *(empty; set by script)* |
| `refreshToken` | *(empty; set by script)* |

Use `{{baseUrl}}/api/...` in requests.

### Token saving script (Login)

On **POST** `{{baseUrl}}/api/auth/login` → **Tests** tab:

```javascript
const json = pm.response.json();
if (json.accessToken) {
  pm.environment.set("accessToken", json.accessToken);
  pm.environment.set("refreshToken", json.refreshToken);
}
```

### Token saving script (Refresh)

On **POST** `{{baseUrl}}/api/auth/refresh-token`:

```javascript
const json = pm.response.json();
if (json.accessToken) {
  pm.environment.set("accessToken", json.accessToken);
  pm.environment.set("refreshToken", json.refreshToken);
}
```

### Authorized requests

Add header:

```
Authorization: Bearer {{accessToken}}
```

### Example workflow

1. **POST** `/api/auth/register` → note email; check OTP (e.g. `MOCK_OTP_LOG` or your email provider).  
2. **POST** `/api/auth/verify-otp` with `otpCode`.  
3. **POST** `/api/auth/login` → scripts store tokens.  
4. **GET** `/api/me` with Bearer.  
5. **GET** `/api/deals` (public).  
6. **POST** `/api/orders` as customer (deal_id from step 5).  
7. **Admin:** **POST** `/api/admin/vendors/register` (multipart) with admin token.  
8. **Vendor:** login → **POST** `/api/deals` → **GET** `/api/vendor/notifications`.  
9. **POST** `/api/auth/refresh-token` with body `{ "refreshToken": "{{refreshToken}}" }` before access expiry.

---

## 8. Formatting & conventions (strict)

- Methods are written **GET**, **POST**, **PUT**, **PATCH**, **DELETE** in documentation.  
- JSON examples use double-quoted keys.  
- Roles: **`CUSTOMER`**, **`VENDOR`**, **`ADMIN`**.  
- UUIDs are shown as `"uuid"` placeholders.  
- All path prefixes are under **`/api`** unless static files under **`/uploads`**.

---

*Document generated from Grabbit backend `server.js` and route modules. Version label **v1** maps to this REST surface; bump when breaking changes are introduced.*
