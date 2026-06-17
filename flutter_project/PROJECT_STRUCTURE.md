# Tandoor Grill: Project Structure & System Architecture Map
**Comprehensive Technical Blueprint of the Flutter Application, Serverless Cloud Functions, and Firebase Configurations**

---

## 1. System Topology Overview

**Tandoor Grill (مطعم التندور)** is built using a modern, multi-tier tech stack optimized for performance, security, and lower network overhead:
* **Frontend**: Flutter Multiplatform (iOS/Android Client, Web Admin Console) using **Feature-First / Clean Architecture** principles, managed by the performance-driven **Riverpod** state library.
* **Backend Walls**: Google Cloud Functions (v2, Node.js + TypeScript) acting as an authoritative server framework. No secure calculations, prices, or points are altered by client code directly.
* **Database & Auth**: Google Cloud Firestore & Firebase SMS Authentication.

```
       ┌─────────────────────────────────────────────────────────────┐
       │                 FLUTTER CLIENT APPLICATION                  │
       │  (State Providers, Feature-First UI, Insulated Cart Logic)   │
       └──────────────┬───────────────────────────────▲──────────────┘
                      │                               │
            HTTPS Callable Triggers          Real-Time Listeners (Reactive)
                      │                               │
       ┌──────────────▼───────────────────────────────┴──────────────┐
       │                    CLOUD FUNCTIONS V2 API                   │
       │  (validateAndPlaceOrder, redeemLoyaltyReward, safety logic) │
       └──────────────┬───────────────────────────────▲──────────────┘
                      │                               │
               Reads official data             Writes ledger logs
                      │                               │
       ┌──────────────▼───────────────────────────────┴──────────────┐
       │                CLOUD FIRESTORE & SECURE DB                  │
       │  (Normalized schemas, locked collections, firestore.rules)  │
       └─────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Hierarchy and Responsibility Matrix

This diagram represents the authoritative structural file configuration across both repository segments:

```
├── /firebase.json                      # Master deployment manifest targeting rules/functions
├── /firestore.indexes.json             # Compiles required compound and collection-group sorting indexes
├── /functions                          # SERVER-SIDE SERVERLESS API APPLICATION
│   ├── package.json                    # Backend dependencies (express, cors, firebase-admin)
│   ├── tsconfig.json                   # TypeScript compiling configuration (target target: ES2022)
│   └── src
│       └── index.ts                    # Declarative Callable Actions and Document Trigger Listeners
└── /flutter_project                    # MOBILE/WEB MULTIPLATFORM CODESPACING
    ├── pubspec.yaml                    # Flutter dependencies (riverpod, flutter_riverpod, cloud_firestore)
    ├── firebase-blueprint.json         # Full physical JSON schema declaration mapping the database
    ├── firestore.rules                 # Immutable production Firestore data validation guidelines
    ├── SECURITY.md                     # Deep security diagrams, transaction tracks, and authorization checks
    ├── DEVOPS_GUIDE.md                 # Complete platform build, Maps restrictions, and Play Store release guide
    └── lib
        ├── main.dart                   # Root entry point initializing Firebase and local providers
        ├── core                        # APP-WIDE UTILITIES & SHARED LOGIC
        │   ├── constants
        │   │   └── colors_fonts.dart   # Brand theme styles (Coal Charcoal, Amber fire, Inter typography)
        │   └── services
        │       ├── localization.dart   # Interactive Arabic/English translation dictionary helper
        │       └── maps_service.dart   # Client-side map integration and address resolution wrapper
        └── features                    # MODERN MODULAR ENCAPSULATION MODULES
            ├── auth                    # SMS Verification logic and Firebase Token handling
            ├── login                   # Interactive screens for country-code phone submission
            ├── menu                    # Menu state, category sheets, and product catalog items
            ├── order                   # Cart State notifier, checkout workflows, and tracking
            ├── loyalty                 # Point balances, coupon scrap cards, and ledger histories
            └── admin                   # Cloud-based Kitchen Dashboard for order workflow tracking
```

---

## 3. Deep-Dive Module Breakdown

### 3.1 The `lib/core` Directory (Shared Utilities)
* **`core/constants/`**: Holds core static variables. Isolates layout assets, colors, and border widths from functional state files to streamline overall branding revisions.
* **`core/services/localization.dart`**: Implements localized language switching (English <-> Arabic). Eliminates hardcoding by matching semantic string dictionaries on demand.
* **`core/services/maps_service.dart`**: Wraps GPS coordinates capture and integrates with Google Maps and Geocoding APIs. Resolves client lat/long data cleanly into human-readable destination addresses.

### 3.2 The `lib/features` Directory (Modular Business Capabilities)

We utilize a modern **Feature-First** structure. Each directory inside `lib/features` represents a distinct operational chunk containing its own folder segments (`screens/` or `widgets/` for presentation layouts, and `models/` or `providers/` for state logic):

#### (A) `features/auth/` & `features/login/` (Identity Management)
* **Goal**: Provides clean user discovery and high-speed OTP validations.
* **State Providers**: Manages authentication persistence across app lifecycle stages.
* **View Layers**: Simple phone submission forms integrated with localized Jordan (+962) country tags.

#### (B) `features/menu/` (Delivering the Gastronomic Core)
* **Goal**: Displays raw restaurant offerings, customized choices (skewers sizing, additional dips), and category navigation tabs.
* **Data Flow**: Hooks up to `/products` collection snapshots to capture real-time availability details (such as stock toggles, promotional icons, and ingredient modifiers).

#### (C) `features/order/` (Basket and Shipment Lifecycle)
* **Goal**: Powers checkout processes and real-time delivery status tracking.
* **Insulated State**:
  - `cart_provider.dart`: Client-side cart item collection (quantities, notes, chosen parameters). Employs local safety state.
  - `order_tracking_provider.dart`: Listens to live `/orders/{orderId}` changes of the client-auth account via streams.
* **State Model (`OrderStatus`)**: Enforces the comprehensive transitional states:
  `pending` -> `accepted` -> `preparing` -> `ready` -> `out_for_delivery` -> `delivered` / `canceled`.

#### (D) `features/loyalty/` (Incentives and Repeat Acquisitions)
* **Goal**: Promotes client loyalty through gamified scratch cards, points meters (where 1.00 JOD Spent = 1,000 points earned), and coupon code catalogs.
* **UI Features**: Visual progress circle indicators checking current points against reward target lines (such as a Free Meal Coupon costing 20,000 points).
* **Security Guard**: Reads ledger reports directly from `/loyalty_transactions` and `/coupon_redemptions` dynamically. Points balances cannot be modified manually through the client.

#### (E) `features/admin/` (Kitchen Operations Hub)
* **Goal**: Tailored specifically for staff tablets and managerial dashboards.
* **Capabilities**:
  - Displays real-time operational lines.
  - Generates audible warnings and visual alerts for new orders.
  - Enables easy state modification: marking tickets as `accepted` (approving order), `preparing` (grilling on oak charcoal), `ready` (insulated thermal packing), `out_for_delivery` (rider hand-off), or `delivered` (finishing the transaction and automatically triggering loyalty points allocation).

---

## 4. Server-Side Framework: `/functions` (Cloud Architecture)

The `/functions` directory implements a serverless paradigm using TypeScript to enforce reliable backend logic:

* **`/functions/src/index.ts` Entrypoint**: Contains isolated trigger pathways executing on Google Cloud:
  1. `validateAndPlaceOrder` (HTTPS Callable API): Resolves real price records inside Firestore, tallies taxes dynamically from `/settings/system_settings`, subtracts validated coupon amounts, verifies geographical delivery distances, and creates the definitive order entry using a highly consistent atomic Database Transaction.
  2. `awardLoyaltyPoints` (Firestore Trigger): Monitors updates to `/orders/{id}` documents. If the status shifts to `delivered`, it reads the transactional JOD total, performs the authoritative conversion of `1.00 JOD = 1,000 points`, and updates the user's point balance profile atomically.
  3. `redeemLoyaltyReward` (HTTPS Callable API): Checks if a user has sufficient points to unlock catalog coupons (such as code `free_meal` for 20,000 points or coupon `cash_5` for 5,000 points), deducts points atomically, and registers an official single-use coupon ledger entry.
  4. `validateCoupon` (HTTPS Callable API): Executes backend checkups targeting validity limits, subtotal requirements, and single-use constraints.

---

## 5. Security Perimeter Configuration: `firestore.rules`

Data mutations cannot bypass validation rules:
- **Write Prevention**: Directly writing blocks to `/orders`, `/loyalty_transactions`, or `/coupons` from the client app is strictly disabled. All mutations must go through the Cloud Functions API.
- **Identity Restriction**: Users can only query directories and tracking records matching their own Firebase `auth.uid` credentials.
- **Admin Isolation**: Fields like managerial dashboard components and system parameters (`/settings/{id}`) require high-level admin authorization checks, blocking raw access for public app instances.
