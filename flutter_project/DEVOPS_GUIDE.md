# Tandoor Grill: Firebase DevOps & Deployment Documentation
**Comprehensive DevOps Playbook for Firebase, Cloud Functions, Firestore, Remote Config, and Android Play Store Release**

---

## 1. Firebase Project Provisioning Guide

### 1.1 Project Creation
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `Tandoor Grill Production` (or your chosen brand name).
3. (Recommended) Enable **Google Analytics** for tracking user acquisitions and funnel events.
4. Set the native resource location region strictly to **`me-central1` (Doha, Qatar)** or **`europe-west2` (London)** as fallback.
   - **Regional Strategy**: `me-central1` is the absolute best candidate for Jordan-based customers to guarantee lowest round-trip latencies. Verify on the GCP status dashboard that all Firestore, Auth, and Cloud Functions (v2) products are locally available in `me-central1` before setup; otherwise, fall back on `europe-west2`, which is highly resilient and natively supported for all services.

### 1.2 Enable Required Services
From the Firebase sidebar, navigate through the initial configurations list and enable the following:
- **Authentication**: Enable the **Phone Numbers** sign-in provider.
- **Cloud Firestore**: Enable under **Production Mode** (which locks down direct read/writes default-deny).
- **Cloud Functions**: Upgrade your billing plan to the **Blaze (Pay-as-you-go) quota tier** (required for deploying Cloud Functions v2 and utilizing external HTTP networks/APIs).
- **Remote Config**: Create initial parameters to provide dynamic on-the-fly dashboard configurations.

---

## 2. Cloud Environment & Secrets Management

To secure database integrations and keep configuration clean, Cloud Functions do not require external API secrets or hardcoded passwords. They operate inside highly secure Google Cloud Service Accounts with IAM privileges. For the client applications and SDK initializations, we define a structured, multi-tier environment strategy to prevent hardcoding of secure client keys.

### 2.1 Client-Side Environment Files Structure (.env)
Never store API keys or configurations hardcoded within the class files. Implement the following files matching your build targets:

#### `.env.dev` (Development Targeting Sandbox / Emulators)
```env
APP_ENV=development
APP_VERSION=1.0.0
MIN_SUPPORTED_VERSION=1.0.0
FIREBASE_PROJECT_ID=tandoor-grill-dev
FIREBASE_API_KEY=AIzaSyA1...devKey
FIREBASE_APP_ID=1:123456789:android:abcdef123
FCM_SENDER_ID=123456789
GOOGLE_MAPS_API_KEY=AIzaSyMapsDev_KeyHere
```

#### `.env.staging` (Staging Environment / Client Testing)
```env
APP_ENV=staging
APP_VERSION=1.0.0
MIN_SUPPORTED_VERSION=1.0.0
FIREBASE_PROJECT_ID=tandoor-grill-staging
FIREBASE_API_KEY=AIzaSyA2...stagingKey
FIREBASE_APP_ID=1:987654321:android:abcdef987
FCM_SENDER_ID=987654321
GOOGLE_MAPS_API_KEY=AIzaSyMapsStg_KeyHere
```

#### `.env.prod` (Production / Real Business Operations)
```env
APP_ENV=production
APP_VERSION=1.0.0
MIN_SUPPORTED_VERSION=1.0.0
FIREBASE_PROJECT_ID=tandoor-grill-prod
FIREBASE_API_KEY=AIzaSyA3...prodKey
FIREBASE_APP_ID=1:555555555:android:abcdef555
FCM_SENDER_ID=555555555
GOOGLE_MAPS_API_KEY=AIzaSyMapsProd_KeyHere
```

### 2.2 Strict Google Maps API Security & Restrictions
Because Google Maps is charged on a pay-as-you-go format and the keys are embedded in client bundles, they are vulnerable to scrapping and drainage. Follow these mandatory security controls:
1. **Never Share Keys**: Do not use the same Google Maps key for development and production.
2. **Restrict by Package Name**: Within the **Google Cloud Console -> APIs & Services -> Credentials**:
   - Edit the specific development/production Maps key.
   - Under **Key restrictions**, choose **Android apps**.
   - Input your package name: `jo.grillchickentikka.app` (for production) and add the **SHA-1 fingerprint** of your signing key.
3. **Restrict API Usage**: Restrict the key to only authorize calls to the specific APIs utilized by the app:
   - **Maps SDK for Android**
   - **Places API (New)**
   - **Directions API**
   - **Geocoding API**
   Any other API request attempting to use this token will be instantly rejected by Google's gateway.

### 2.3 Environmental variables config (`.env`) for Functions
If you require setting environment variables for Cloud Functions in the future, save them in `/functions/.env` (and add `.env` to `/functions/.gitignore` to avoid committing keys):

```env
# /functions/.env examples (if needed for third-party platforms)
SMS_AGGREGATOR_API_KEY=your_production_key_here
MAPS_GEOCODING_RESTRICTED_KEY=your_maps_key_here
```

### 2.4 Local Emulator Environment Variables
For local testing or offline environments, use the following local config inside `/functions/.env.local`:
```env
FUNCTIONS_EMULATOR=true
DATABASE_EMULATION=false
```

---

## 3. Firestore Rules & Composite Indexes Deployment

Both rules and index files are now declared at the root level of your project. This allows immediate deployment without manual copy-pasting into the Firebase Web Console.

### 3.1 Deploying Security Rules (Least-Privilege Guards)
Use the Firebase CLI to deploy security guidelines and prevent price or loyalty manipulation:
```bash
# From workspace root
firebase deploy --only firestore:rules
```

### 3.2 Deploying Composite Indexes
Firestore requires explicit indexes for complex sorted queries. Run this command to deploy our pre-configured indexes (covering user order history orders sorted by dates, active operations tracking, and transaction points records):
```bash
# From workspace root
firebase deploy --only firestore:indexes
```

---

## 4. Cloud Functions Deployment Instructions

Cloud Functions are written in TypeScript, ensuring static typing and safety prior to execution.

### 4.1 Deployment Commands
Run the command below from the workspace root (or inside `/functions` directory directly) to build and deploy:

```bash
# Step 1: Install dependencies
cd functions && npm install

# Step 2: Compile TS and deploy using Firebase CLI
firebase deploy --only functions
```

### 4.2 Verifying Deployed Cloud Functions
Log in to the **Google Cloud Console** or **Firebase Console** and ensure you see the following endpoints active:
1. `validateAndPlaceOrder`: HTTPS Callable for client-side zero-trust checkouts.
2. `awardLoyaltyPoints`: Firestore Document Trigger on `/orders/{orderId}` updates (fires on strict transitions to `delivered` status).
3. `redeemLoyaltyReward`: HTTPS Callable for turning accumulated user points into coupons.
4. `validateCoupon`: HTTPS Callable for checking promo integrity prior to client checkout.

---

## 5. Firebase Remote Config Configuration Template

Dynamically alter application logic on the fly without republishing Android or iOS binaries. Create the following parameters in the Firebase Console:

### 5.1 Remote Config Schema Defaults
Copy and paste this JSON mapping directly into your Firebase Remote Config console pane, or create these parameters manually:

```json
{
  "maintenance_mode": {
    "defaultValue": {
      "value": "false"
    },
    "description": "Toggles an absolute system-wide lockout screen. Useful during national holidays or emergency kitchen renovations."
  },
  "loyalty_enabled": {
    "defaultValue": {
      "value": "true"
    },
    "description": "Enables/disables the entire user-facing loyalty rewards dashboard and point accretion triggers globally."
  },
  "promo_banner_url": {
    "defaultValue": {
      "value": "https://images.unsplash.com/photo-1608897013039-887f21d8c804?auto=format&fit=crop&w=800&q=80"
    },
    "description": "Custom campaign visual banner shown on the customer dashboard home screen."
  },
  "force_update_minimum_version": {
    "defaultValue": {
      "value": "1.0.0"
    },
    "description": "Force update prompt trigger. If current client version is lower, lock app with Google Play download prompt."
  },
  "tax_rate_override": {
    "defaultValue": {
      "value": "5"
    },
    "description": "Dynamic tax % override. If settings collection document is missing, fallback uses this value."
  }
}
```

---

## 6. Android Play Store Release & Keystore Checklist

The Flutter mobile application should go through proper signing structures before submission to Google Play Console.

### 6.1 Recommended Android Package Naming
Ensure matching configurations across all platform assets:
* **Production Package Name**: `jo.grillchickentikka.app` (or your corporate domain prefix e.g., `com.qfix.grillchickentikka`).
* **Locations to Update**:
  * `/android/app/build.gradle` (change `applicationId`)
  * `/android/app/src/main/AndroidManifest.xml` (update package definition string)
  * Firebase Settings App Android Config

### 6.2 Generating the Production Keystore
Generate a secure upload key/keystore for signing the release application bundle (AAB):

```bash
# Run signature command
keytool -genkey -v -keystore production-upload-key.keystore -alias tandoor-grill-alias -keyalg RSA -keysize 2048 -validity 10000
```
*Keep this `.keystore` file extremely secure! If lost, you will not be able to push updates to Google Play.*

### 6.3 Flutter Signing Configuration
Create an `/android/key.properties` file locally on your build machine (add it to your `.gitignore` to prevent leaking passwords to git):

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=tandoor-grill-alias
storeFile=production-upload-key.keystore
```

Configure your `/android/app/build.gradle` to load these variables on production compilation:

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties['storeFile'])
                storePassword = keystoreProperties['storePassword']
                keyAlias = keystoreProperties['keyAlias']
                keyPassword = keystoreProperties['keyPassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

## 7. Google Play Release Sequence Checklist

### 7.1 Integrity & SHA Key Setup (Phone Auth Security)
- [ ] Log in to the Google Play Console and navigate to **App Signing**.
- [ ] Extract the **App signing key certificate SHA-1** and **SHA-256** fingerprints.
- [ ] Add both fingerprints to your **Firebase Project Settings** under your registered Android application card. If omitted, Phone authentication (SMS Verification) will crash of fail authentication in production.
- [ ] Configure Android Device Check API/Play Integrity API within Google Cloud Platform console to activate CAPTCHA/SafetyNet fallback verification.

### 7.2 Safety Measures & Test Data Wipe
- [ ] Delete the Dev Test Account registration document in Firestore (`+962791234567`).
- [ ] Ensure the sandbox number and bypass code (`000000`) are removed or disabled inside the Firebase Authentication settings dashboard.
- [ ] Compile the final release Flutter binary:
  ```bash
  flutter build appbundle --release
  ```
- [ ] Submit the compiled `.aab` file to the Google Play Console dynamic developer portal under "Closed Testing" or "Production Rollout".

---

## 8. Firestore Backup & Disaster Recovery Strategy

To safeguard the restaurant's operational orders ledger, coupon audits, and user loyalty points, we must deploy a daily automated Firestore data backup solution:

### 8.1 Automated Daily Export Schedule
Since Firestore doesn't have an automatic "one-click UI" backup schedule, we configure a periodic cloud trigger:
1. **Cloud Storage Bucket Setup**: Create a dedicated Google Cloud Storage bucket (e.g., `gs://tandoor-grill-prod-firestore-backups`) with a lifecycle policy set to **automatically delete files older than 30 days** to limit storage fees.
2. **Cloud Scheduler & Pub/Sub Task**:
   - Establish an automated cron job inside **Cloud Scheduler**: `0 3 * * *` (Runs every day at 3:00 AM Amman time when operations are closed).
   - Configure the Cloud Scheduler task to call a lightweight Admin Cloud Function or target the Google Cloud Firestore API endpoint:
     `https://firestore.googleapis.com/v1/projects/tandoor-grill-prod/databases/(default):exportDocuments`
3. **IAM Permissions**: Grant the Cloud Scheduler service account the `Cloud Datastore Import Export Admin` and `Storage Admin` roles to allow writing snapshots.

### 8.2 Disaster Recovery & Restore Action (Emergency Run)
In the worst-case scenario where database mutation occurs due to catastrophic bugs, follow this step-by-step restoration model:
1. **Put App in Maintenance Mode**: Set `maintenance_mode` to `true` instantly in Remote Config (locking clients) to prevent active basket submissions or credit state adjustments.
2. **Retrieve the Snapshot Metadata**: Find the latest successful export folder name in your backup bucket (e.g., `2026-06-13T03:00:00_89230`).
3. **Execute gcloud Import Command**: Restore the database to its exact status at the backup point:
   ```bash
   gcloud firestore import gs://tandoor-grill-prod-firestore-backups/2026-06-13T03:00:00_89230/
   ```
4. **Validation Check**: Verify data consistency (Orders, Customer loyalty balances, settings) in the database browser before releasing the App from Maintenance Mode.

---

## 9. Observability & Monitoring (Monitoring & Alerting)

Ensure operational downtime is caught and fixed before it impacts customers or kitchen staff.

### 9.1 Essential Firebase SDK Integration
Configure and initialize the following modules in your Flutter app:
* **Firebase Crashlytics**:
  - Automatically captures uncaught Dart exceptions and native crashes.
  - Generates instant notifications for fatal/frequent errors.
* **Firebase Performance Monitoring**:
  - Tracks client-side HTTP request latency (especially response speeds of callable HTTP functions).
  - Meaures app startup render frames and screen transition lags.

### 9.2 Server-Side Google Cloud Logging (Cloud Functions Logging)
All serverless functions write persistent logs accessible in GCP **Logs Explorer**:
* Add strict trace points inside your API code: `console.log()` for information steps, `console.warn()` for low-risk anomalies, and `console.error()` for checkout process failures.
* Log all transaction rejections with explicit diagnostic tags (e.g., `[PAYMENT_ERROR]`, `[INVALID_COUPON]`).

### 9.3 Custom GCP Alerting Rules
Configure alert conditions on the Google Cloud Monitoring console to trigger instant emails or SMS notifications when:
1. **Cloud Functions Failures**: The error rate of `validateAndPlaceOrder` or `awardLoyaltyPoints` surpasses **1% of total executions over a 5-minute rolling window**.
2. **OTP Authentication Abuse**: Authentication failure rates in Firebase Auth spike anomalously (indicates potential brute-force or SMS gateway billing drain attacks).
3. **Unauthorized Firestore Reads/Writes**: A sudden wave of rejected transactions logged via `security_rules` rejections (indicates database cracking attempts).

---

## 10. Firebase App Check Security Enforcement

To protect your cloud infrastructure from automated bot traffic, custom scripts, and fake order floods, **App Check** must be activated.

### 10.1 Platform-Specific App Attestations
Register and configure the appropriate attestation providers based on client platforms:
- **Android Mobile Client**: Integrate with **Play Integrity** (Google's production attestation tool, verifying that the binary is certified, unchanged, and running on a safe physical Android device).
- **Web Admin Portal**: Register the administration web dashboard with **reCAPTCHA Enterprise** or **reCAPTCHA v3** to check browser actions against malicious bot scraping profiles.

### 10.2 Enforcement Status Policy
1. Deploy your Flutter application with the App Check SDK integrated, using local debug providers during the testing phase.
2. Review app consumption metrics under the Firebase App Check Dashboard for 4-7 days to verify that all legitimate app instances are obtaining verified tokens.
3. Toggle the status from "Monitoring" to **"Enforced"** on the following secure assets:
   - **Cloud Firestore**: Any request without a valid App Check token will be blocked at the edge before scanning database resources.
   - **Cloud Functions**: Block callables instantly from execution if a valid Play Integrity attestation is not present on the payload.
   - **Firebase Storage** (if applicable).

