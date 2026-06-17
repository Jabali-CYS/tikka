# Grill Chicken Tikka - Production-Ready Design Documentation

## 1. Design Tokens (JSON Format for Flutter)
These tokens map directly to `ThemeData` and `ColorScheme` in Flutter.

### Color Tokens
| Token | Hex | Flutter Color Code |
| :--- | :--- | :--- |
| `primary` | `#CDAA6D` | `Color(0xFFCDAA6D)` |
| `secondary` | `#C62828` | `Color(0xFFC62828)` |
| `background` | `#F8F4EA` | `Color(0xFFF8F4EA)` |
| `surface` | `#FFFFFF` | `Color(0xFFFFFFFF)` |
| `onPrimary` | `#FFFFFF` | `Color(0xFFFFFFFF)` |
| `onSurface` | `#1E1E1E` | `Color(0xFF1E1E1E)` |
| `onSurfaceVariant` | `#666666` | `Color(0xFF666666)` |
| `error` | `#B00020` | `Color(0xFFB00020)` |
| `success` | `#4CAF50` | `Color(0xFF4CAF50)` |

### Spacing & Shape
| Token | Value | Flutter Equivalent |
| :--- | :--- | :--- |
| `radius_lg` | 16px | `BorderRadius.circular(16)` |
| `radius_md` | 12px | `BorderRadius.circular(12)` |
| `radius_sm` | 8px | `BorderRadius.circular(8)` |
| `space_xs` | 8px | `SizedBox(height: 8)` |
| `space_md` | 16px | `SizedBox(height: 16)` |
| `space_lg` | 24px | `SizedBox(height: 24)` |

---

## 2. Component States & Flutter Naming
Use these structured names for widget classes.

### Button/Primary & Button/Secondary
- **Default:** Full opacity, brand color.
- **Hover/Pressed:** `scale(0.98)`, brightness `-10%`.
- **Disabled:** `opacity(0.4)`, `pointer-events: none`.
- **Loading:** Replace text with `CircularProgressIndicator(strokeWidth: 2)`.

### Input/Phone & Input/OTP
- **Default:** Soft cream border, hint text in `onSurfaceVariant`.
- **Focused:** 2px border `#CDAA6D`, subtle glow shadow.
- **Error:** 2px border `#C62828`, error text below.

### Card/Product
- **Default:** Elevated shadow `0px 4px 20px rgba(205, 170, 109, 0.08)`.
- **Pressed:** Elevation reduction, `scale(0.99)`.
- **Product Unavailable:** Grayscale filter, "Sold Out" badge overlay.

---

## 3. Form Validation & Edge States

| Scenario | Visual Indicator | Message (EN/AR) |
| :--- | :--- | :--- |
| **Invalid Phone** | Red border on input | "Enter a valid number" / "أدخل رقم هاتف صحيح" |
| **Invalid OTP** | Shake animation + Red text | "Incorrect code" / "الرمز غير صحيح" |
| **Network Error** | Full-screen overlay + Retry | "Check internet" / "تحقق من الاتصال" |
| **Outside Area** | Bottom sheet + Map icon | "We don't deliver here yet" / "لا نغطي هذه المنطقة حالياً" |

---

## 4. Admin Dashboard Flow
**Path:** `AdminLogin` → `DashboardOverview` (Sales/Charts) → `MenuManagement` (Categories/Products) → `OrderPipeline` (Live Feed/Details/Status Patch) → `CustomerCRM` → `PromoEngine` (Coupons/Banners) → `Reporting` (Analytics) → `SystemSettings` (Hours/Branch).

---

## 5. Accessibility & Responsive Guidelines
- **Touch Targets:** Minimum 48x48dp for all interactive elements (Flutter `kMinInteractiveDimension`).
- **One-Handed Use:** Primary CTAs (Add to Cart, Confirm Order) placed in the "Bottom Thumb Zone".
- **RTL/LTR:** All layouts use `Directionality` widgets; `Padding.only(start: 16)` instead of `left`.
- **Tablets:** Grid systems adapt from 1-column (Mobile) to 2-3 columns (Tablet) using `LayoutBuilder`.

---

## 6. AI-Assisted Development (Cursor/Claude)
Provide this `Design.md` as context to your AI assistant to generate:
1. `theme.dart` containing the `ThemeData`.
2. `widgets/` folder with `AppButton`, `AppInput`, and `ProductCard` classes.
3. `l10n/` for AR/EN translations.
