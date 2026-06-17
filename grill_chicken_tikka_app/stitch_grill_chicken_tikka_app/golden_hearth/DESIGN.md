---
name: Golden Hearth
colors:
  surface: '#fff8f3'
  surface-dim: '#e0d9d1'
  surface-bright: '#fff8f3'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#faf2eb'
  surface-container: '#f5ede5'
  surface-container-high: '#efe7df'
  surface-container-highest: '#e9e1da'
  on-surface: '#1e1b17'
  on-surface-variant: '#4e463a'
  inverse-surface: '#33302b'
  inverse-on-surface: '#f7efe8'
  outline: '#7f7668'
  outline-variant: '#d1c5b5'
  surface-tint: '#765a25'
  primary: '#765a25'
  on-primary: '#ffffff'
  primary-container: '#cdaa6d'
  on-primary-container: '#563e0a'
  inverse-primary: '#e6c182'
  secondary: '#b51a1e'
  on-secondary: '#ffffff'
  secondary-container: '#d93633'
  on-secondary-container: '#fffbff'
  tertiary: '#4c5e84'
  on-tertiary: '#ffffff'
  tertiary-container: '#9dafd9'
  on-tertiary-container: '#304266'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdea8'
  primary-fixed-dim: '#e6c182'
  on-primary-fixed: '#271900'
  on-primary-fixed-variant: '#5b420f'
  secondary-fixed: '#ffdad6'
  secondary-fixed-dim: '#ffb4ac'
  on-secondary-fixed: '#410003'
  on-secondary-fixed-variant: '#93000e'
  tertiary-fixed: '#d8e2ff'
  tertiary-fixed-dim: '#b4c6f2'
  on-tertiary-fixed: '#051b3d'
  on-tertiary-fixed-variant: '#35466b'
  background: '#fff8f3'
  on-background: '#1e1b17'
  surface-variant: '#e9e1da'
typography:
  display-lg:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Manrope
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-ar:
    fontFamily: IBM Plex Sans Arabic
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  xxl: 64px
  container-max: 1200px
  gutter: 24px
---

## Brand & Style

The design system for this high-end Amman-based restaurant is anchored in **Modern Elegance** with a **Tactile** touch. It targets a discerning audience that appreciates the intersection of traditional culinary craftsmanship and contemporary luxury. 

The visual style is defined by a sophisticated "warm minimalism." By utilizing a soft cream canvas and rich golden accents, the UI avoids the coldness of typical tech products, instead evoking the hospitality of a premium dining room. The aesthetic balances structured grid layouts with "squishy," organic card shapes (squircles) to create a premium digital concierge experience that feels both professional and inviting. 

Key attributes include:
- **Sophistication:** Subtle use of depth and gradients over flat fills.
- **Bilingual Fluidity:** Seamless transition between LTR and RTL layouts.
- **Appetite Appeal:** Generous whitespace and high-contrast photography surfaces.

## Colors

This palette uses a warm, monochromatic base of creams and golds, punctuated by a deep, appetite-stimulating red.

### Palette Roles
- **Primary (#CDAA6D):** Used for interactive elements, key iconography, and brand-defining borders.
- **Secondary (#C62828):** Reserved for "Call to Action" buttons (e.g., "Order Now"), price tags, and urgent notifications. It provides a striking contrast against the gold.
- **Background (#F8F4EA):** A soft cream that reduces eye strain compared to pure white, enhancing the premium feel.
- **Surface:** A slightly lighter or tinted version of the cream used for elevated cards to create subtle depth.
- **Text:** Primary text (#1E1E1E) is a soft charcoal for high legibility, while secondary text (#666666) handles descriptions and metadata.

## Typography

The typography system uses **Manrope** for Latin characters and **IBM Plex Sans Arabic** for Arabic content. This combination ensures a modern, geometric clarity that feels cohesive across both scripts.

### Implementation Rules
- **Hierarchy:** Use Display sizes for hero sections and signature dish titles. Body-md is the default for descriptions.
- **Bilingual Support:** When displaying English and Arabic together, ensure the Arabic text is scaled roughly 10-15% larger than the English to maintain perceived visual weight.
- **Case:** Use Uppercase sparingly for English labels (Label-lg) to evoke luxury branding. Arabic text should never be artificially bolded or condensed.

## Layout & Spacing

The design system utilizes a **Fluid Grid** with a 12-column structure for desktop and a 4-column structure for mobile. 

### Spacing Philosophy
- **Rhythm:** All spacing is based on a 4px base unit. 
- **Density:** Use generous "xl" (40px) padding within card containers and sections to maintain an airy, premium feel. 
- **Safe Areas:** On mobile, a minimum 16px (md) margin is required on both sides.
- **RTL Transition:** In Arabic mode, the grid columns and layout direction are mirrored. Iconography that suggests direction (arrows, progress bars) must be flipped.

## Elevation & Depth

To achieve the "Modern Elegant" look, depth is communicated through **Ambient Shadows** and **Tonal Layering**.

- **Level 0 (Base):** Background color (#F8F4EA). No shadow.
- **Level 1 (Cards):** Surface color is #FFFFFF or a subtle #FDFCF8. Shadow: `0px 4px 20px rgba(205, 170, 109, 0.08)`. This uses a faint tint of the primary gold to create a glow rather than a grey shadow.
- **Level 2 (Modals/Overlays):** Surface color #FFFFFF. Shadow: `0px 12px 32px rgba(30, 30, 30, 0.12)`.
- **Glassmorphism:** Navigation bars use a backdrop blur (12px) with 80% opacity of the background color to maintain context during scrolling.

## Shapes

The design system follows a **Squircle (Super-ellipse)** philosophy. This avoids the harshness of sharp corners and the generic feel of standard circles.

- **Standard Elements:** Buttons and small input fields use `rounded-md` (0.5rem).
- **Featured Cards:** Menu items and category cards use `rounded-xl` (1.5rem) to emphasize their tactile, premium nature.
- **Buttons:** CTA buttons can transition to pill-shaped (3) if they contain only text, but the standard for the restaurant is the elegant squircle.

## Components

### Buttons
- **Primary:** Background #CDAA6D, Text #FFFFFF. Squircle shape. Subtle gradient from top-left (Primary) to bottom-right (Accent Gold Dark).
- **CTA (Order):** Background #C62828, Text #FFFFFF. High elevation (Level 1).
- **Secondary:** Outlined with 1.5px Primary Gold border, transparent background.

### Cards (Menu Items)
- White surface with squircle corners.
- Images should be top-aligned with a subtle inner-shadow to make food pop.
- Pricing in Secondary Red, positioned at the bottom right (LTR) or bottom left (RTL).

### Input Fields
- Soft cream background (#F2EEE3) with a 1px border that turns Primary Gold on focus.
- Labels use Label-lg typography in Primary Text.

### Chips & Tags
- Used for dietary preferences (e.g., "Spicy," "Gluten-Free"). 
- Low-contrast background (Primary Gold at 10% opacity) with Primary Gold text.

### Navigation
- Top navigation should be minimal with a centered logo.
- In Arabic view, the "Cart" icon and "Profile" icon switch places to occupy the primary visual corner (Top Left).