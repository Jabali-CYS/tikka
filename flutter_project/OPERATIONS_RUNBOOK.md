# Tandoor Grill: Systems Operations Runbook
**Administrative Incident Response, System Maintenance, Rollback Strategies, and Service Disaster Recovery Procedures**

---

## 1. System Maintenance & Config Updates

All crucial business parameters (tax, times, points, maintenance) are driven dynamically by the `/settings/system_settings` document in Firestore, eliminating the need to redeploy client-side binaries or cloud functions.

### 1.1 Toggling App Maintenance Mode
If the kitchen is undergoing emergency repairs, or if weather conditions prevent delivery, toggle Maintenance Mode to lock the client app:
1. Open the **Firebase Console -> Firestore Database** and browse to the collection `/settings` and document `system_settings`.
2. Locate the field `maintenanceMode` and set its boolean value to `true`.
3. The next time the client app fires or a service fetch occurs, the client app will display an elegant "Insulated Service Undergoing Maintenance" overlay.
4. Set back to `false` to instantly restore standard checkout capabilities.

### 1.2 Changing Operational Hours
Operational hours dictate delivery eligibility checks within Cloud Functions:
1. Browse to `/settings/system_settings` on the Firebase Console.
2. Edit `restaurantOpenTime` (e.g. `"11:00 AM"`) and `restaurantCloseTime` (e.g. `"11:30 PM"`).
3. These variables are formatted as strings and read by checkout checkers dynamically.

### 1.3 Updating Restaurant Sales Tax
Adjusting dynamic tax rates requires zero code adjustments:
1. Locate document `/settings/system_settings`.
2. To modify, set `taxEnabled` to `true` or `false` to bypass tax calculations entirely.
3. Edit the numerical value `taxRate` (e.g., set to `5` for a 5% standard restaurant sales tax, or to `16` if new Jordian taxation rates are introduced). Do not use decimal points like `0.05` here; specify as a whole percentage value.

---

## 2. Admin Operations: Managing Promo Coupons

To create seasonal coupon marketing codes, populate the `/coupons` structure directly:

```json
Collection Path: /coupons/{couponCode}
Document Content:
  {
    "code": "RAMADAN2026",                 // Uppercase, alphanumeric, matching document name
    "discountValue": 2.50,                 // Explicit value deduction in JOD
    "discountType": "Flat",                // Support "Flat" (absolute deduction) or "Percent"
    "minSubtotal": 10.00,                  // Minimum order sum to permit application
    "expiryDate": "2026-11-30T23:59:59Z",  // ISO 8601 UTC timestamp check
    "usageLimit": 500,                     // Total redemptions allowed across all users
    "usageCount": 18,                      // Increment track (updated by serverless checkouts)
    "userSpecific": false                  // Set true to restrict validity to a single customerUid
  }
```

---

## 3. Incident Management Strategy & Severity Triage

Establish immediate operational actions for various scenarios:

### Severity Level 1 (Catastrophic Blackout)
* **Indicators**: Checkout crashes completely, database queries timeout, users face endless loadings.
* **Immediate Mitigation Action**:
  - Open Firebase console -> Remote Config.
  - Set parameter `maintenance_mode` to `"true"`. This prevents database locks, halts cart checkout attempts, and blocks downstream API billing fees.
  - Direct engineers to examine Cloud Functions logs within GCP.

### Severity Level 2 (Specific Domain Breakdown)
* **Indicators**: SMS OTP registration codes are blocked or failing to drop on client devices.
* **Mitigation Operations**:
  - Confirm the billing status of the safety Blaze plan.
  - Check App Console stats: if SMS limits have hit Google Cloud daily boundaries, configure fallback **reCAPTCHA verification options** within the app configuration dashboard.

---

## 4. Rollback Strategies and Procedures

If a newly deployed code asset causes critical errors in production, trigger a rollback immediately.

### 4.1 Rolling Back Cloud Functions Deployments
In Google Cloud Functions (v2), each deploy is saved as an immutable revision image. To restore a known safe state:
1. Go to the **Google Cloud Console -> Cloud Run** (as Functions run on top of Cloud Run containers).
2. Locate the specific service (e.g., `validateAndPlaceOrder`).
3. Click the **Revisions** tab.
4. Select the previously working revision ID.
5. Click **Manage Traffic** and direct 100% of the runtime requests back to that stable revision. This takes less than 2 seconds and will resolve server-side crashes instantly.

### 4.2 Flutter Rollbacks (Android Client)
If a faulty update is uploaded to Google Play:
1. Log in to **Google Play Console**.
2. Navigate to your Release track (Production or Open Testing).
3. Under App Bundles, look up the revision history list.
4. Roll back or reject the current deployment track, selecting the stable, signed `.aab` asset from the build archives.
5. Publish a minor increment version (e.g., `v1.0.1` built from the stable git branch) to replace any buggy binaries downloaded by clients.

---

## 5. Daily Firestore Backup and Disaster Recovery

### 5.1 Restoring Database from Storage Bucket (Step-by-Step)
In the event of database corruption, restore from a verified snapshot:

```bash
# Step 1: Install and configure Google Cloud SDK (gcloud CLI)
gcloud components install beta

# Step 2: Authentication on administrative root
gcloud auth login

# Step 3: Link active terminal configurations with production ID
gcloud config set project tandoor-grill-prod

# Step 4: Run restoration from backup bucket path
# Make sure to replace the snapshot folder name with the target date
gcloud firestore import gs://tandoor-grill-prod-firestore-backups/2026-06-13T03:00:00_89230/
```

### 5.2 Post-Restoration Validation
Once the gcloud import process returns `Success`:
1. Log into your Firestore Database console.
2. Verify that the system's core collections (`/orders`, `/users`, `/loyalty_transactions`, `/settings`) have loaded the expected historic records.
3. Turn off Maintenance Mode by updating `system_settings` to activate order lines and services for clients.
