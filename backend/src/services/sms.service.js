/**
 * SMS delivery for OTP (registration). Uses Twilio when credentials are set; otherwise logs only.
 *
 * Env (Twilio): TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER (E.164, e.g. +1...)
 * SMS_ENABLED: defaults to enabled (real Twilio when credentials exist).
 * Set to false / 0 / no to force mock-only (no Twilio API calls).
 */

const https = require('https');
const querystring = require('querystring');
const { OTP_EXPIRY_MINUTES } = require('../config/constants');

/** Normalize to E.164 for Ethiopia (+251). */
function normalizePhoneE164(raw) {
  if (raw == null) return '';
  let p = String(raw).trim().replace(/[\s-]/g, '');
  if (!p) return '';
  if (p.startsWith('+')) return p;
  if (p.startsWith('0')) return '+251' + p.slice(1);
  if (p.startsWith('251')) return '+' + p;
  if (/^9\d{8}$/.test(p)) return '+251' + p;
  return p.startsWith('+') ? p : '+' + p;
}

function sendTwilioSms(toE164, messageBody) {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM_NUMBER;

  const postData = querystring.stringify({
    To: toE164,
    From: from,
    Body: messageBody,
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'api.twilio.com',
        path: `/2010-04-01/Accounts/${sid}/Messages.json`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(postData),
          Authorization: `Basic ${Buffer.from(`${sid}:${token}`).toString('base64')}`,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (c) => {
          data += c;
        });
        res.on('end', () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(JSON.parse(data || '{}'));
          } else {
            reject(new Error(`Twilio HTTP ${res.statusCode}: ${data}`));
          }
        });
      }
    );
    req.on('error', reject);
    req.write(postData);
    req.end();
  }  );
}

/** True unless SMS_ENABLED is explicitly turned off (false / 0 / no / off). Default = real sends when Twilio is configured. */
function isSmsSendingEnabled() {
  const v = String(process.env.SMS_ENABLED ?? 'true').trim().toLowerCase();
  if (['false', '0', 'no', 'off'].includes(v)) return false;
  return true;
}

/**
 * Send registration OTP via SMS. Falls back to console when Twilio is not configured.
 */
async function sendRegistrationOtp(phoneE164, otpCode) {
  const body = `Your Grabbit verification code is: ${otpCode}. It expires in ${OTP_EXPIRY_MINUTES} minutes.`;

  const smsDisabled = !isSmsSendingEnabled();
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM_NUMBER;

  if (smsDisabled || !sid || !token || !from) {
    console.log(`[SMS MOCK] To ${phoneE164}: ${body}`);
    if (process.env.MOCK_OTP_LOG === 'true') {
      console.log(`[MOCK_OTP_LOG] OTP digits only: ${otpCode}`);
    }
    return { mock: true };
  }

  await sendTwilioSms(phoneE164, body);
  return { sent: true };
}

module.exports = {
  normalizePhoneE164,
  sendRegistrationOtp,
};
