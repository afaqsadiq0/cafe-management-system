---
name: Premium Cafe Management
colors:
  surface: '#fff8f6'
  surface-dim: '#ffd0bf'
  surface-bright: '#fff8f6'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fff1ec'
  surface-container: '#ffe9e3'
  surface-container-high: '#ffe2d9'
  surface-container-highest: '#ffdbcf'
  on-surface: '#2e150b'
  on-surface-variant: '#504442'
  inverse-surface: '#46291e'
  inverse-on-surface: '#ffede7'
  outline: '#827472'
  outline-variant: '#d3c3c0'
  surface-tint: '#745853'
  primary: '#271310'
  on-primary: '#ffffff'
  primary-container: '#3e2723'
  on-primary-container: '#ae8d87'
  inverse-primary: '#e3beb8'
  secondary: '#625f4d'
  on-secondary: '#ffffff'
  secondary-container: '#e6e0c9'
  on-secondary-container: '#676351'
  tertiary: '#735c00'
  on-tertiary: '#ffffff'
  tertiary-container: '#cba72f'
  on-tertiary-container: '#4e3d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#e3beb8'
  on-primary-fixed: '#2b1613'
  on-primary-fixed-variant: '#5b403c'
  secondary-fixed: '#e9e2cc'
  secondary-fixed-dim: '#ccc6b1'
  on-secondary-fixed: '#1e1c0e'
  on-secondary-fixed-variant: '#4a4737'
  tertiary-fixed: '#ffe088'
  tertiary-fixed-dim: '#e9c349'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#574500'
  background: '#fff8f6'
  on-background: '#2e150b'
  surface-variant: '#ffdbcf'
typography:
  display-lg:
    fontFamily: EB Garamond
    fontSize: 48px
    fontWeight: '600'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: EB Garamond
    fontSize: 32px
    fontWeight: '500'
    lineHeight: 40px
  headline-md:
    fontFamily: EB Garamond
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  headline-sm:
    fontFamily: EB Garamond
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 8px
  container-padding-mobile: 16px
  container-padding-desktop: 40px
  gutter: 24px
  section-gap: 48px
---

## Brand & Style

The design system is anchored in the concept of "Artisanal Precision." It targets cafe owners and managers who view their business as a craft. The aesthetic is a fusion of **Modern Professionalism** and **Tactile Luxury**, evoking the sensory experience of a high-end espresso bar—the smell of roasted beans, the warmth of steamed milk, and the gleam of polished brass.

The UI avoids the clinical coldness of typical SaaS products, opting instead for a "Digital Concierge" feel. It balances functional efficiency with an editorial layout style, utilizing generous whitespace (Cream), deep grounding elements (Brown), and moments of prestige (Gold). The emotional response should be one of calm control, reliability, and sophistication.

## Colors

This design system utilizes a high-contrast, warm-toned palette to establish a premium atmosphere.

*   **Primary (Deep Brown - #3E2723):** Used for primary navigation, headings, and high-emphasis containers. It provides the "weight" and authority of the brand.
*   **Secondary (Cream - #FFF8E1):** The primary surface color. It reduces eye strain compared to pure white and reinforces the cafe aesthetic.
*   **Tertiary (Gold Accents - #D4AF37):** Reserved for interactive highlights, "Active" states, and subtle decorative borders. It should be used sparingly to maintain its perceived value.
*   **Neutrals:** Derived from the primary brown, using desaturated and lightened tones to handle borders, secondary text, and disabled states.

## Typography

The typography strategy pairs the classical elegance of **EB Garamond** with the technical clarity of **Hanken Grotesk**. 

*   **Headlines (Serif):** Use EB Garamond for all major titles, section headers, and "prestige" numbers (like total revenue). This creates an editorial, high-end feel.
*   **Body & UI (Sans-Serif):** Use Hanken Grotesk for all functional text, data tables, and inputs. Its clean, geometric nature ensures readability in fast-paced cafe environments.
*   **Labels:** Labels and small metadata should use Hanken Grotesk with increased letter spacing and uppercase styling to denote hierarchy without needing excessive bolding.

## Layout & Spacing

The layout philosophy follows a **Fixed-Fluid Hybrid** model. On desktop, content is centered within a 1280px max-width container to maintain the "boutique" feel. On mobile, elements reflow to a single column with a 16px safe margin.

A strict 8px grid governs all spacing. 
*   **Margins:** Use larger margins (40px+) between major sections to emphasize the "Cream" space and prevent the UI from feeling cluttered.
*   **Cards:** Group related data in cards with 24px internal padding.
*   **Density:** While the overall style is spacious, data-heavy views (like Inventory or Orders) transition to a "Compact" mode where vertical padding is halved to 4px or 8px.

## Elevation & Depth

Depth in this design system is achieved through "Soft Skeuomorphism." Rather than harsh drop shadows, we use layered tonal surfaces and gold-tinted outlines.

1.  **Base Layer:** The Cream (#FFF8E1) surface serves as the foundation.
2.  **Raised Layer (Cards/Buttons):** Elements use a very soft, diffused shadow (Blur: 15px, Opacity: 4%, Color: #3E2723) and a 1px solid or gradient border.
3.  **The "Gold Rim":** High-priority interactive elements (like the 'Place Order' button or active navigation items) feature a subtle 1px inner or outer gold outline (#D4AF37) to suggest a metallic inlay.
4.  **Pressed State:** Interactive elements should appear to sink slightly into the surface, achieved by removing the shadow and adding a subtle inner shadow.

## Shapes

The design system uses **Soft (0.25rem)** roundedness to maintain a sense of architectural structure and professional rigor. 

*   **Standard Components:** Buttons, inputs, and small cards use a 4px (0.25rem) radius.
*   **Large Containers:** Main content areas or modal overlays may use `rounded-lg` (8px) to soften the presence of large blocks.
*   **Icons:** Icons should feature consistent stroke weights (1.5px) and slightly rounded caps to match the "Soft" shape language. Avoid sharp 90-degree corners on custom iconography.

## Components

### Buttons
Primary buttons are Deep Brown (#3E2723) with Cream text. They feature a 1px Gold (#D4AF37) bottom border that simulates a "weighted" physical button. Secondary buttons are outlined in Deep Brown with no fill.

### Cards
Cards are white (#FFFFFF) with the standard soft shadow and a 1px border in a very light neutral (#EFEBE9). For featured items, the border color changes to Gold.

### Input Fields
Inputs use a "Floating Label" style. The background is a slightly darker cream than the base. When focused, the border transitions to Gold and the label shrinks.

### Lists & Tables
Lists use horizontal dividers in a thin, low-opacity Deep Brown. The first column of any table (the "Key") should be styled in the Serif font to reinforce the premium branding.

### Navigation
The sidebar uses the Deep Brown background with Gold for the "Active" state indicator—a vertical 4px bar on the left edge of the menu item. Icons in the navigation are consistently Gold or lightened Brown.

### Additional Components
*   **Status Badges:** Pill-shaped with low-opacity backgrounds (e.g., light green fill with dark green text) for 'In Stock' or 'Completed' statuses.
*   **Digital Receipt:** A specialized card component with a "serrated" bottom edge and serif typography for high-end order summaries.