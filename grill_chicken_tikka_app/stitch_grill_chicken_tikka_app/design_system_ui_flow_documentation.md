# Grill Chicken Tikka - Design System (Golden Hearth)

## 1. Visual Identity & Brand Voice
The design system, "Golden Hearth," is crafted to evoke a premium, warm, and authentic grilled food experience. It balances traditional warmth with modern minimalism.

## 2. Color Palette
| Token | Hex Code | Usage |
| :--- | :--- | :--- |
| **Primary (Gold)** | `#CDAA6D` | Primary buttons, active states, brand accents, loyalty points. |
| **Secondary (Red)** | `#C62828` | Emergency alerts, price highlights, "Confirm Order" actions, spicy indicators. |
| **Background (Cream)** | `#F8F4EA` | Page backgrounds, soft container fills. |
| **Surface** | `#FFFFFF` | Card backgrounds, elevated surfaces. |
| **On-Surface (Primary Text)** | `#1E1E1E` | Headings, main body text. |
| **On-Surface Variant (Secondary)** | `#666666` | Descriptions, timestamps, inactive labels. |

## 3. Typography (Manrope)
| Scale | Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display Large** | 32px | Bold | 40px | Hero headings, Splash screen. |
| **Headline Medium** | 24px | Bold | 32px | Section titles, Product names. |
| **Title Medium** | 18px | SemiBold | 24px | Card titles, Modal headers. |
| **Body Large** | 16px | Regular | 24px | Standard reading text. |
| **Label Large** | 14px | Medium | 20px | Navigation labels, Button text. |

## 4. Spacing System (8px Grid)
- **Base Unit:** 8px
- **Padding Small (sm):** 8px (Inner component spacing)
- **Padding Medium (md):** 16px (Standard screen margins)
- **Padding Large (lg):** 24px (Section separation)
- **Gap:** 12px/16px (List items/Grid gaps)

## 5. Shape & Elevation
- **Corner Radius:** 16px (Large cards), 12px (Buttons/Inputs), 8px (Small badges).
- **Elevation:** Soft shadows `0px 4px 20px rgba(205, 170, 109, 0.08)` to maintain a tactile, premium feel without looking cluttered.

---

# Reusable Components Library

## 1. Action Components
- **Primary Button:** Full-width, #CDAA6D background, white text, 12px radius.
- **Secondary/Ghost Button:** Outlined #CDAA6D or soft cream background.
- **Floating Action Button (FAB):** Circular, #C62828 background for immediate "Cart" or "Menu" access.

## 2. Navigation Components
- **Top Bar:** Center-aligned headline, leading icon (back/menu), trailing icon (notification).
- **Bottom Navigation:** 4-5 destinations (Home, Orders, Loyalty, Profile), icon + label, active state indicator.

## 3. Feedback & Selection
- **Heat Level Selector:** Segmented control (Mild, Medium, Hot) with #CDAA6D active fill.
- **Category Pill:** Horizontal scrollable list, rounded-full shape.
- **Progress Bar:** Loyalty tracking with #CDAA6D fill and #E0D9D1 track.

## 4. Cards
- **Product Card:** Image top, title/price/rating below, "Add to Cart" button.
- **Promo Card:** Large background image/color, bold headline, "Claim" CTA.
- **Order Card:** Status badge (Delivered/Preparing), item list summary, total price.

---

# UI Flow Diagram: Full User Journey

## 1. Onboarding & Auth
- **Splash Screen** -> **Language Selection** (AR/EN).
- **Language Selection** -> **Login Screen** (Phone Input).
- **Login Screen** -> **OTP Verification**.
- **OTP Verification** -> **Home Screen** (Authenticated).
- *Note: "Browse as Guest" bypasses login to Home Screen.*

## 2. Discovery & Selection
- **Home Screen** -> **Categories Listing** (View All).
- **Categories Listing** -> **Products Listing** (Filtered).
- **Products Listing** -> **Product Details**.
- **Product Details** -> **Shopping Cart** (Add to Cart).

## 3. Checkout & Fulfillment
- **Shopping Cart** -> **Address Picker** (Map/Saved).
- **Address Picker** -> **Checkout Screen**.
- **Checkout Screen** -> **Order Tracking** (Success).
- **Checkout Screen** (If Out of Range) -> **Delivery Unavailable Screen**.

## 4. Engagement & Profile
- **Home/Profile** -> **Loyalty & Rewards**.
- **Loyalty & Rewards** -> **Redeem Coupon**.
- **Profile** -> **Order History** -> **Reviews & Ratings** (For Completed Orders).
- **Profile** -> **Saved Addresses**.
- **Profile** -> **Language Settings**.

## 5. System States
- **Any Screen** -> **Restaurant Closed** (If outside 12 PM - 1 AM).
- **Cart** (If empty) -> **Empty Cart State**.
- **Home** (If no internet) -> **Offline State**.
