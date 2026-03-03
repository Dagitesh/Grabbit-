import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'customer_shell.dart';

class MvpSpecScreen extends StatelessWidget {
  const MvpSpecScreen({super.key});

  static const String _specText = '''
You are a senior full-stack engineer.

We are building the Grabbit MVP (two-sided digital marketplace).

Authentication module is already completed.

Now implement:

1) Vendor Module
2) Deal Module

Include:
- Backend (Node.js + Express + PostgreSQL + Sequelize/Prisma)
- RESTful APIs
- Business logic
- Database models & relationships
- Flutter frontend screens
- API integration using Dio
- Clean architecture structure

--------------------------------------------------
PART 1 — BACKEND IMPLEMENTATION
--------------------------------------------------

Existing:
- User model with roles (CUSTOMER, VENDOR, ADMIN)
- JWT authentication
- Role-based middleware

--------------------------------
A) VENDOR MODULE
--------------------------------

1. Database Design:

Create VendorProfile model:

- id (UUID)
- user_id (FK → User)
- business_name
- business_description
- phone
- location
- is_approved (boolean, default false)
- created_at
- updated_at

Relationship:
User (1) → (1) VendorProfile

2. Vendor Features:

Implement endpoints:

- POST /api/vendor/profile
  → Create vendor profile (VENDOR role only)

- GET /api/vendor/profile
  → Get logged-in vendor profile

- PUT /api/vendor/profile
  → Update vendor profile

- GET /api/vendor/dashboard
  → Return:
      - total deals
      - active deals
      - expired deals
      - total orders (mock if needed)

- PUT /api/admin/vendor/:id/approve
  → Admin approves vendor

Use role middleware:
- Only ADMIN can approve
- Only VENDOR can access vendor routes

--------------------------------
B) DEAL MODULE
--------------------------------

1. Database Design:

Create Deal model:

- id (UUID)
- vendor_id (FK → VendorProfile)
- title
- description
- original_price
- discounted_price
- quantity_available
- expiry_date (datetime)
- is_active (boolean)
- created_at
- updated_at

Relationship:
VendorProfile (1) → (Many) Deals

2. Business Logic:

Expiry Logic:
- If current date > expiry_date → is_active = false
- Prevent purchase if expired or quantity = 0

Quantity Tracking:
- Decrease quantity when order is created (future ready)

3. Deal Endpoints:

Vendor:
- POST /api/deals
- PUT /api/deals/:id
- GET /api/vendor/deals

Customer:
- GET /api/deals (paginated)
- GET /api/deals/:id

Filtering:
- Query parameters:
    ?minPrice=
    ?maxPrice=
    ?active=true
    ?search=keyword

Add pagination:
- page
- limit

4. Provide:
- Complete controller, service, repository structure
- Validation middleware
- Example JSON responses
- Postman test examples

--------------------------------------------------
PART 2 — FLUTTER FRONTEND
--------------------------------------------------

Project already has authentication.

Add:

lib/features/vendor/
lib/features/deals/

--------------------------------
A) Vendor Frontend
--------------------------------

1. VendorProfileScreen
- Show business name
- Description
- Approval status
- Edit button

2. Create/Edit Vendor Profile Form

3. VendorDashboardScreen
Show:
- Total deals
- Active deals
- Expired deals
- Basic statistics cards

Call:
GET /vendor/dashboard

--------------------------------
B) Deal Frontend
--------------------------------

1. HomeScreen (Deal Listing)
- Paginated API call
- Grid/List layout
- Basic filtering
- Pull to refresh

2. DealDetailsScreen
- Title
- Description
- Discount %
- Expiry countdown
- Quantity remaining
- Reserve button (UI only for now)

3. VendorDealManagementScreen
- List vendor deals
- Edit button
- Create new deal button

--------------------------------
PART 3 — API INTEGRATION
--------------------------------

- Use Dio
- Add interceptor for JWT
- Centralized ApiService
- Error handling
- Loading indicators

--------------------------------
PART 4 — OUTPUT FORMAT
--------------------------------

Provide:

1. Full backend code (structured by file)
2. Full Flutter frontend code
3. Database migrations
4. API request/response examples
5. Instructions to run backend
6. Instructions to test endpoints
7. Instructions to run Flutter app

Code must be clean, modular, and MVP production-ready.

Do not skip implementation details.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Grabbit MVP – Vendor & Deals'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _specText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CustomerShell(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue to app'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

