# AppTag Privacy Policy

**Last Updated**: 2026-04-23
**Effective Date**: 2026-04-23

AppTag ("the App") respects your privacy and complies with applicable privacy laws. This policy describes what data we collect, why, how we store it, and your rights.

---

## 1. Data We Collect

### 1.1 On Sign-Up / Login (Optional)
Most features of the App work without an account. Cloud backup and related features require sign-in, in which case we collect:

| Item | When | How |
|------|------|-----|
| Email address | Email sign-up | User input |
| Password (hashed) | Email sign-up | User input (hashed by Supabase) |
| Name, email, profile picture | Google / Apple Sign-In | Provided by SSO provider |

### 1.2 Automatically Collected
- Device info (OS version, app version, device model)
- Error and crash logs (for stability diagnostics)

### 1.3 User-Generated Content
- QR code content (URLs, text, contacts, coordinates, Wi-Fi info, etc.)
- Custom templates and sticker text
- Scan history (stored only on device)

---

## 2. Purposes

| Purpose | Data Used |
|---------|-----------|
| Account management | Email, SSO profile |
| Cloud backup of user templates (optional) | User content, account ID |
| Service stability and quality improvement | Device info, error logs |
| Customer support | Email |

---

## 3. Retention and Deletion

| Item | Retention |
|------|-----------|
| Account info | Deleted immediately upon account deletion |
| Cloud backup data | Deleted immediately upon account deletion |
| Local device data | Removed automatically when the app is uninstalled |
| Error / crash logs | Auto-deleted after 90 days |

We have no legal obligation to retain additional data.

---

## 4. Third-Party Services

We do not share personal data with third parties. For service operation, we use the following providers:

| Provider | Service | Data Region |
|----------|---------|-------------|
| Supabase, Inc. | Auth, database hosting | ap-northeast-2 (Seoul) |
| Google LLC | Google Sign-In | Per Google policy |
| Apple Inc. | Sign in with Apple | Per Apple policy |

---

## 5. Your Rights

You may at any time:
- Access your personal data
- Correct your data
- Delete your account and data
- Restrict processing

### How to Exercise
1. **In-app**: Profile → "Delete Account"
2. **Email**: tawooltag@gmail.com (processed within 5 business days)

---

## 6. Data Storage Location

| Data | Location |
|------|----------|
| User templates, QR Tasks | Local (Hive) + Supabase (if logged in) |
| Scan history | Local (Hive) only |
| Color palettes, user shape presets | Local (Hive) only |
| Temporary files | Device temp dir (auto-cleaned by OS) |
| Account info | Supabase (ap-northeast-2) |

---

## 7. Permissions

All permissions are requested only when the user explicitly triggers the related feature.

| Permission | Purpose |
|------------|---------|
| Camera | QR code scanning |
| NFC | NFC tag read / write |
| Location | Current location for map-tag creation |
| Contacts | Contact QR generation |
| Photos / Media | Logo image selection, saving QR to gallery |
| Query all packages | Listing installed apps to save their deep-links as QR codes |

---

## 8. Changes to This Policy

Updates will be announced via app update or on this page.

---

## 9. Contact

- Email: **tawooltag@gmail.com**
