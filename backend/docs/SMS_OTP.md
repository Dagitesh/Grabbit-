# SMS OTP (registration)

Registration sends a **6-digit OTP by SMS** to the phone number (not email).

## Development (no Twilio)

Without Twilio credentials, the server **logs** the message to the console (`[SMS MOCK]`). Optional:

```env
MOCK_OTP_LOG=true
```

…also logs the raw OTP digits for quick testing.

## Production (Twilio)

Set:

| Variable | Description |
|----------|-------------|
| `TWILIO_ACCOUNT_SID` | Account SID |
| `TWILIO_AUTH_TOKEN` | Auth token |
| `TWILIO_FROM_NUMBER` | Twilio sender number (E.164, e.g. `+1...`) |

**SMS is enabled by default** (`SMS_ENABLED` unset or `true`). Real SMS is sent when all three Twilio variables are set.

To **disable** real sends (mock / console only), e.g. in staging:

```env
SMS_ENABLED=false
```

(Also `0`, `no`, or `off`.)

## Phone format

Numbers are normalized to **E.164** for Ethiopia (`+251…`). Local formats like `09…` are accepted.

## Verify OTP

`POST /api/auth/verify-otp` expects **`phone`** (same number as registration) and **`otpCode`** or **`otp`**, not `email`.
