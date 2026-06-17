# Production Security Specification (SECURITY.md)

This document outlines the Security Architecture, Zero-Trust Threat Model, audit tables schema (ERD), Security Controls, and OWASP Mobile Top 10 security review for the **Grill Chicken Tikka (Amman Charcoal Skewers & Loyalty)** application.

---

## 1. Development vs. Production Separation

Our codebase enforces a strict separation between low-friction sandbox testing environments and high-security live production environments via the immutable `AppConfig` class in `lib/core/constants/config.dart`.

| Feature | Development Mode | Production Mode (Enforced in Release Builds) |
| :--- | :--- | :--- |
| **Authentication Flow** | Static sandbox mock with SMS OTP bypass via code `000000` on any 10-digit number. | Enforced Real Firebase Phone Authentication. Non-bypassable OTP verification sent via sms gateway. |
| **Bypass Backdoors** | Allowed for ease of local screen testing and design layout validation. | **Strictly Blocked**. The login screen hides bypass card graphics, and `FakeAuthRepositoryImpl` is blocked at runtime. |
| **Fake Auth Repository** | Enabled via Riverpod configuration overrides. | **Disabled**. Real `FirebaseAuthRepositoryImpl` is selected. Triggering fake methods throws a fatal `StateError` to prevent runtime exploits. |
| **Administrative Console**| Admin console login is accessible directly via client interface link for layout testing. | **Admin Link Hidden** from customer-facing interfaces. Real Admin screens are locked down behind backend Firestore verification checks (`exists(/admins/uid)`). |
| **Logging Configuration** | Full debug logging enabled. | Debug/diagnostic output logging disabled to protect against sensitive information leaks from terminal dumps. |

---

## 2. Server-Authoritative Zero-Trust Architecture

In our production-certified architecture, the Flutter mobile client is considered **entirely untrusted**. No financial calculation, loyalty point calculation, coupon validation, or order ticket creation can be decided or modified by the client. Any direct client-side write to order files, financial total nodes, or loyalty points fields is blocked at the database layer.

The following architecture models how financial variables are locked against client manipulation:

### A. Cloud Functions Logic & Data Flow Diagram

```
[ UNTRUSTED FLUTTER CLIENT ]
             │
             │ 1. Passes Raw Cart Input Only (e.g. { productId, quantity, sideOption, zoneId })
             ▼
┌────────────────────────────────────────────────────────────────────────┐
│               validateAndPlaceOrder (HTTPS CALLABLE FUNCTION)          │
│                      Authenticated via Firebase Auth Token             │
├────────────────────────────────────────────────────────────────────────┤
│  • Reads Official Item Prices from `/products`                         │
│  • Reads Geographic Shipping Rates from `/delivery_zones`              │
│  • Verifies Expiry, Limits & User Records from `/coupons`              │
│  • Authoritatively Calculates: Subtotal, Taxes (5%), Discount, Total   │
│  • Generates Tamper-Free Order Ticket details with Pending Status      │
│  • Commits Official Order directly to Firestore using Admin SDK        │
│  • Log Transaction Record in `/order_audit_logs`                       │
└───────────────────┬───────────────────────────────────┬────────────────┘
                    │                                   │
     2. Writes Order│                                   │ 3. Returns Verified
        Ticket Doc  │                                   │    Metadata (Id & Total)
                    ▼                                   ▼
          ┌───────────────────┐               [ FLUTTER CLIENT ]
          │ Firestore DB      │               (Awaiting confirmation)
          │ `/orders/{id}`    │
          └─────────┬─────────┘
                    │
                    │ 4. Order status transitions to "delivered"
                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                awardLoyaltyPoints (FIRESTORE TRIGGER FUNCTION)         │
│                      Triggered on Document Update Event                │
├────────────────────────────────────────────────────────────────────────┤
│  • Guards against duplicate earnings via `pointsAwarded` flag check   │
│  • Authoritatively converts: 1 JOD Spent = 1000 Loyalty Points         │
│  • Atomically Increments `/users/{uid}/points`                         │
│  • Commits Ledger Item to `/loyalty_transactions`                      │
│  • Appends audit log trace to `/order_audit_logs`                      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Interaction Sequence Diagram

The following chronological timeline traces the secure checkout sequence through backend barriers:

```
Flutter Client             validateAndPlaceOrder            Firestore DB            awardLoyaltyPoints
     │                              │                            │                           │
     │── 1. checkout(rawCart) ─────>│                            │                           │
     │                              │── 2. Query product price ─>│                           │
     │                              │<─ 3. Return official price ┤                           │
     │                              │                            │                           │
     │                              │── 4. Verify coupon limits ─>│                           │
     │                              │<─ 5. Return coupon status ─┤                           │
     │                              │                            │                           │
     │                              │── 6. Write Order ticket ──>│                           │
     │                              │    (status: "pending")     │                           │
     │                              │                            │                           │
     │                              │── 7. Write audit log ─────>│                           │
     │                              │                            │                           │
     │<─ 8. Return Confirmation ────│                            │                           │
     │      (orderId, total)        │                            │                           │
     │                              │                            │                           │
     │                              ~ Time passes: Kitchen workflow completes ~              │
     │                              │                            │                           │
     │── 9. Set status = "delivered" ───────────────────────────>│                           │
     │      (Delivery confirmation) │                            │                           │
     │                              │                            │── 10. Database Update ────>│
     │                              │                            │       Events Fire          │── 11. Read Order total
     │                              │                            │                            │── 12. Accumulate points:
     │                              │                            │<── 13. Write User balance ─│       +1000 per 1.00 JOD
     │                              │                            │<── 14. Write transaction ──│
     │                              │                            │<── 15. Set pointsAwarded ──│
     │                              │                            │    (Prevent replay fraud)  │
```

---

## 4. Entity-Relationship Diagram (ERD) & Firestore Schema

All persistent collections adhere to strict models linked to the authoritative backend. We introduce four audit engines (`loyalty_transactions`, `coupon_redemptions`, `order_audit_logs`, and `admin_activity_logs`) to track state transitions seamlessly.

```
  ┌──────────────────────┐               ┌──────────────────────┐
  │      categories      │               │       products       │
  ├──────────────────────┤               ├──────────────────────┤
  │ PK  id               │<───────────── │ PK  id               │
  │     name             │               │     categoryId (FK)  │
  │     nameAr           │               │     title / titleAr  │
  │     isDeleted        │               │     price            │
  └──────────────────────┘               │     sideOptions [ ]  │
                                         └──────────────────────┘
  ┌──────────────────────┐               ┌──────────────────────┐
  │    delivery_zones    │               │       coupons        │
  ├──────────────────────┤               ├──────────────────────┤
  │ PK  id               │               │ PK  id               │
  │     name             │               │     code             │
  │     fee              │               │     discountType     │
  │     minOrder         │               │     value            │
  └──────────────────────┘               │     usageLimit       │
                                         │     usedCount        │
                                         └──────────────────────┘
  ┌──────────────────────┐               ┌──────────────────────┐
  │        users         │               │        admins        │
  ├──────────────────────┤               ├──────────────────────┤
  │ PK  uid (Matches auth)               │ PK  uid (Matches auth)
  │     phone            │               │     role             │
  │     name             │               └──────────────────────┘
  │     points           │
  └──────────────────────┘
             │
             ├──────────────────────────────────────┐
             │ 1 : N                                │ 1 : N
             ▼                                      ▼
  ┌──────────────────────┐               ┌──────────────────────┐
  │ loyalty_transactions │               │  coupon_redemptions  │
  ├──────────────────────┤               ├──────────────────────┤
  │ PK  id               │               │ PK  id               │
  │     customerUid (FK) │               │     customerUid (FK) │
  │     pointsChanged    │               │     couponCode       │
  │     transactionType  │               │     redeemedAt       │
  │     createdAt        │               └──────────────────────┘
  └──────────────────────┘
             │
             │ 1 : N
             ▼
  ┌──────────────────────┐               ┌──────────────────────┐
  │        orders        │               │   order_audit_logs   │
  ├──────────────────────┤               ├──────────────────────┤
  │ PK  id               │<──────────────│ PK  id               │
  │     customerUid (FK) │ 1 : N         │     orderId (FK)     │
  │     orderNumber      │               │     action           │
  │     items [ ]        │               │     details          │
  │     subtotal / total │               │     timestamp        │
  │     deliveryFee/tax  │               └──────────────────────┘
  │     status           │
  │     pointsAwarded    │
  └──────────────────────┘
```

### Firestore Document Schema Structures

#### 1. Loyalty Transactions (`/loyalty_transactions/{id}`)
*Holds historical ledger of customer loyalty program movements.*
```json
{
  "id": "tx_90182",
  "customerUid": "user_abc123",
  "pointsChanged": 150,
  "transactionType": "earn", 
  "description": "Earned points from Ticket #T-26-8091",
  "createdAt": "2026-06-14T18:41:00Z"
}
```

#### 2. Coupon Redemptions (`/coupon_redemptions/{id}`)
*Immutable checklist tracking which user claimed which discount code.*
```json
{
  "id": "red_k378s",
  "customerUid": "user_abc123",
  "couponCode": "TIKKA50",
  "redeemedAt": "2026-06-14T18:41:00Z"
}
```

#### 3. Order Audit Logs (`/order_audit_logs/{id}`)
*Immutable chronos parameters tracing order lifecycle events, price validations, and courier movements.*
```json
{
  "id": "audit_8s0a7fs",
  "orderId": "ord_x92k39",
  "action": "ORDER_CREATED",
  "details": "Calculated Total: 16.50 JOD. Client pricing calculations ignored in favor of core backend rules.",
  "timestamp": "2026-06-14T18:41:05Z"
}
```

#### 4. Admin Activity Logs (`/admin_activity_logs/{id}`)
*Immutable tracing lists recording all dashboard interactions.*
```json
{
  "id": "adminlog_47x89",
  "adminUid": "admin_user_991",
  "action": "UPDATE_PRODUCT_PRICE",
  "target": "product_shish_taouk - Updated pricing parameters to 7.50 JOD.",
  "timestamp": "2026-06-14T18:45:00Z"
}
```

---

## 5. Security Controls

Our production build integrates several multi-layered security controls:

1. **Firebase App Check Integration**
   * Configured on application startup inside `FirebaseService` mapping `AndroidProvider.playIntegrity` with strict API verification profiles. This blocks non-authorized scripts from calling Firebase database endpoints directly.

2. **Firestore Least-Privilege Deny-By-Default Rules**
   * Configured with a top-level catch-all statement: `match /{document=**} { allow read, write: if false; }`. Read and write permissions are only explicitly opened on targeted, validated collections under rigorous condition rules.

3. **Input Sanitization & Boundary Limits**
   * Phone values restrict inputs to valid Jordanian numbering syntax (at most 14 characters, starting with cellular prefixes). Firestore rules validate matching IDs to prevent path injection attacks.

4. **Soft Deletion Policies**
   * Crucial databases fields (menu items, customer profiles, coupon codes, and order cards) apply a soft-delete constraint (`isDeleted: true`). Hard deletions are completely prohibited (returning `false` on `delete` match gates) to maintain full logs of previous events.

5. **Adversarial Security Coverage Rules**
   * **Shadow Field Rejections**: Creating objects evaluates the exact schema size to detect unexpected fields injected during transmission.
   * **Immutability Protection**: Permanent indicators like `createdAt` or initial `customerUid` details are verified as unchangeable once created.

---

## 6. OWASP Mobile Top 10 Review & MASVS Alignment

We reviewed our Flutter Customer client and Web Admin codebase against the **OWASP Mobile Top 10 (2024)** criteria:

### M1: Improper Platform Usage
* **Review**: We enforce strict Platform and Firebase configuration bindings. Firebase key setups are secured behind App Check configuration policies, and sensitive state flags are restricted from standard local shared preferences.

### M2: Insecure Data Storage
* **Review**: Handled via integration of `flutter_secure_storage` to protect local cache tokens and sensitive variables. In-memory Riverpod provider state maps are kept isolated.

### M3: Insecure Communication
* **Review**: Firebase API endpoints communicate solely over encrypted HTTPS (TLS 1.3). Real production servers terminate connections with secure certificates, shielding credentials from local Wi-Fi eavesdropping.

### M4: Insecure Authentication
* **Review**: Completely solved. The backdoor OTP code `000000` is disabled in production mode, and `FakeAuthRepositoryImpl` is blocked. Authentication processes are governed by real, rate-limited SMS Firebase Phone Auth instances.

### M5: Insufficient Cryptography
* **Review**: Cryptographic signatures of the client app are verified using App Check. All Firestore communication applies high-grade transit encryption.

### M6: Insecure Authorization
* **Review**: Highly secure. There are zero assumptions that client-provided roles match reality. Client payloads are treated as untrusted; administrative claims must exist in `/admins` to view core administrative states.

### M7: Client Code Quality
* **Review**: Flutter lint rules (`flutter_lints`) are strictly applied to fix warnings. Compiling production binaries applies ProGuard and R8 obfuscation directives.

### M8: Code Tampering
* **Review**: App Check uses Play Integrity to verify the app's integrity, ensuring tampered APKs cannot access Firestore resources.

### M9: Reverse Engineering
* **Review**: Flutter compilation strips debug metrics and metadata flags. Obfuscated builds hide implementation paths from decompiler tools.

### M10: Extraneous Functionality
* **Review**: Completed. The bypass Sandbox cards, testing numbers records, and test shortcuts are completely disabled when `AppConfig.environment` transitions to production.

---

## 7. Security Checklist Verification

Prior to release, developers must verify our security controls:

- [x] Enforce `AppConfig.environment = AppEnvironment.production`.
- [x] Compile the final Android binary with `--obfuscate` flag.
- [x] Invalidate and remove any mock sandbox verification codes (`000000`) from client files.
- [x] Deploy the finalized production `firestore.rules` ruleset.
- [x] Configure Google Play Integrity developer credentials in the Google Cloud Console.
