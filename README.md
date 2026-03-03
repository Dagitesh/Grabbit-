# Grabbit — MVP Authentication Module

Two-sided marketplace mobile app with backend REST API and Flutter frontend.

---

## Part 1 — Backend (Node.js + Express + PostgreSQL)

### Folder structure

```
backend/
  src/
    config/          # database, constants
    modules/
      auth/          # auth.controller, auth.service, auth.routes, auth.validation
      user/          # user.model, user.repository
    middleware/      # validate, auth (JWT + roles)
    utils/           # errorHandler
  server.js
  postman/           # Postman collection
```

### Prerequisites

- Node.js 18+
- PostgreSQL 14+

### Setup and run

1. **Install dependencies**

   ```bash
   cd backend
   npm install
   ```

2. **Database**

   - Create a PostgreSQL database, e.g. `grabbit_db`.
   - Copy env example and set your values:

   ```bash
   copy .env.example .env
   ```

   Edit `.env`:

   ```
   PORT=3000
   NODE_ENV=development
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=grabbit_db
   DB_USER=postgres
   DB_PASSWORD=your_password
   JWT_ACCESS_SECRET=your_super_secret_access_key_min_32_chars
   JWT_REFRESH_SECRET=your_super_secret_refresh_key_min_32_chars
   MOCK_OTP_LOG=true
   ```

3. **Run migrations / sync schema**

   Tables are created automatically on startup via `sequelize.sync({ alter: true })`. To run sync without starting the server:

   ```bash
   npm run db:migrate
   ```

4. **Start the server**

   ```bash
   npm start
   # or with auto-reload:
   npm run dev
   ```

   Server runs at `http://localhost:3000`.

### API base URL for Flutter

- **Android emulator:** `http://10.0.2.2:3000` (default in app).
- **iOS simulator:** use your machine IP, e.g. `http://192.168.1.x:3000`, or configure in app.
- **Physical device:** use your machine’s LAN IP, e.g. `http://192.168.1.x:3000`.

---

## Part 2 — Flutter app

### Structure

```
lib/
  core/
    constants/     # api_constants, storage_keys
    network/      # api_client (Dio + interceptors)
    services/      # secure_storage_service
  features/
    auth/
      data/models/       # user_model, auth_response_model
      presentation/     # providers, screens
      services/         # auth_api_service
  main.dart
```

### Run the app

1. **Install dependencies**

   ```bash
   cd grabbit_app
   flutter pub get
   ```

2. **Point to your backend**

   Default base URL is `http://10.0.2.2:3000` (Android emulator). For iOS or a real device, change `ApiConstants.baseUrl` in `lib/core/constants/api_constants.dart` to your backend URL (e.g. `http://<your-ip>:3000`), or use:

   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
   ```

3. **Run**

   ```bash
   flutter run
   ```

### Flow

- **No token** → Login screen.
- **Register** → Register → OTP screen → (after verify) → Login → Home.
- **Login** → Home (tokens stored in secure storage).
- **Logout** → Clear storage → Login.

---

## Part 3 — API examples

### 1. Register

**Request**

```http
POST /api/auth/register
Content-Type: application/json

{
  "full_name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "role": "CUSTOMER"
}
```

Optional: `"phone": "+1234567890"`. Role: `CUSTOMER` or `VENDOR`.

**Response (201)**

```json
{
  "id": "uuid",
  "full_name": "John Doe",
  "email": "john@example.com",
  "role": "CUSTOMER",
  "is_verified": false,
  "message": "Registration successful. Please verify your email with the OTP sent."
}
```

With `MOCK_OTP_LOG=true`, the 6-digit OTP is printed in the backend console.

---

### 2. Verify OTP

**Request**

```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response (200)**

```json
{
  "message": "Email verified successfully. You can now log in."
}
```

---

### 3. Login

**Request**

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response (200)**

```json
{
  "user": {
    "id": "uuid",
    "full_name": "John Doe",
    "email": "john@example.com",
    "phone": null,
    "role": "CUSTOMER",
    "is_verified": true
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": 900
}
```

---

### 4. Refresh token

**Request**

```http
POST /api/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "eyJhbGc..."
}
```

**Response (200)**

```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": 900
}
```

---

### Postman

Import `backend/postman/Grabbit Auth API.postman_collection.json`. Set collection variable `baseUrl` to `http://localhost:3000` (or your backend URL).

---

## Database (Sequelize)

- **User** table is created/updated on server start via `sequelize.sync({ alter: true })`.
- **Manual sync only:** `npm run db:migrate`.

User model fields: `id` (UUID), `full_name`, `email` (unique), `phone`, `password` (hashed), `role` (ENUM: CUSTOMER, VENDOR, ADMIN), `is_verified`, `otp_code`, `otp_expires_at`, `created_at`, `updated_at`.

---

## Security

- Passwords hashed with **bcrypt** (12 rounds).
- **JWT**: access token 15 min, refresh token 7 days.
- **express-validator** on register, login, verify-otp, refresh-token.
- **Role-based middleware** available for protected routes (`authenticate`, `authorize(ROLES.CUSTOMER, ROLES.VENDOR)`).
- Flutter: **flutter_secure_storage** for tokens; **Dio** interceptor adds `Authorization: Bearer <accessToken>` and can refresh on 401.

---

## Quick test (backend)

1. Start backend and ensure DB is running.
2. Register a user (Postman or Flutter).
3. Check server console for mock OTP (if `MOCK_OTP_LOG=true`).
4. Call verify-otp with that OTP.
5. Call login and use the returned tokens for authenticated requests.
