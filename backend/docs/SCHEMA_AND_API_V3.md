# Grabbit schema & API v3 (customer-only signup, admin vendors, Addis subcities)

## Database migration

Run on PostgreSQL **after** `001` / `002`:

```bash
psql $DATABASE_URL -f migrations/003_addis_subcities_vendor_customer_reviews.sql
psql $DATABASE_URL -f migrations/004_deal_admin_moderation.sql
```

Then seed subcities + categories:

```bash
npm run db:seed
```

## Model highlights

- **`subcities`**: Addis Ababa subcities for customer home location + deal location + vendor branches.
- **`customer_profiles`**: `first_name`, `last_name`, `subcity_id`, `saved_preferences`.
- **`vendor_profiles`**: `owner_name`, `business_type`, `certificate_pdf_url`, `address`, `branch_count`. **`is_approved` removed** (no separate verification flag).
- **`vendor_branches`**: optional rows per vendor (`subcity_id`, `address_detail`).
- **`deals`**: `subcity_id` (required on create via API). **Moderation:** `removed_by_admin`, `admin_removal_reason_code`, `admin_removal_reason_label`, `admin_removed_at` — admin removal with preset reason; public listings hide removed deals.
- **`reviews`**: `deal_id`, `user_id`, `vendor_id` (denormalized for listing + notifications).
- **`vendor_notifications`**: in-app feed for vendors (`order`, `review`, `deal_removed`).

## Auth

- **`POST /api/auth/register`**: **customers only** — `first_name`, `last_name`, `email`, `phone`, `subcity_id`, `password` (no `role`).
- **`POST /api/auth/verify-otp`**: body `otpCode` or `otp` (6 digits).

## Public

- **`GET /api/subcities`**
- **`GET /api/deals`**: query `subcityId`, `categoryId`, `minPrice`, `maxPrice`, `urgentOnly=true` (expires within 7 days), `active`, `search`, … — **excludes** deals removed by admin.
- **`GET /api/deals/:dealId/reviews`**

## Admin (JWT role `ADMIN`)

- **`POST /api/admin/vendors/register`** — `multipart/form-data`:
  - File field **`certificate`** (PDF, required)
  - Fields: `owner_email`, `initial_password`, `business_name`, `owner_name`, `tin`, `business_type`, `contact_phone`, `address`, `branch_count` (optional)
  - `branches` — JSON string array: `[{ "subcity_id": "uuid", "address_detail": "..." }]`
- **`GET /api/admin/vendors`** — list vendors + branches
- **`GET /api/admin/vendors/pending`** — returns `[]` (legacy endpoint)
- **`GET /api/admin/deal-moderation-reasons`** — preset `{ code, label }[]` for removal dropdown
- **`GET /api/admin/deals`** — `?page=&limit=&search=&includeRemoved=true` — list deals with parsed `images`, `vendor`, `category_name`, `subcity_name`
- **`POST /api/admin/deals/:id/remove`** — body `{ "reason_code": "MISLEADING" }` — sets `removed_by_admin`, deactivates deal, creates vendor notification `deal_removed`

## Vendor

- **`GET /api/vendor/notifications`**, **`PATCH /api/vendor/notifications/:id/read`**, **`PATCH /api/vendor/notifications/read-all`**
- **`POST /api/deals`**: requires **`subcity_id`** and **`category_id`**.

## Customer

- **`POST /api/orders/:orderId/review`** — `{ "rating": 1-5, "comment": "..." }` (one review per order).

Predefined categories (seed): **Meat**, **Vegan**, **Pastries**, **Drinks**, **Urgent**.
