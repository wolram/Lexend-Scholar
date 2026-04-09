# Lexend Scholar Design System

### 1. Overview & Creative North Star
**Creative North Star: The Academic Architect**

Lexend Scholar is a design system built for clarity, institutional trust, and high-density information management. It moves away from the "app-like" playfulness of consumer tools toward a "high-end editorial" workspace. By utilizing the geometric precision of the Lexend typeface and a restrained "Fidelity" color palette, the system creates a sense of focused calm. 

The design breaks traditional grid rigidity through intentional vertical rhythm and the use of "Lateral Anchoring"—where the sidebar provides a solid structural weight against a fluid, airy content canvas.

### 2. Colors
The palette is rooted in a professional Azure Primary (#137fec) complemented by a sophisticated range of cool grays.

*   **The "No-Line" Rule:** Sectioning is primarily achieved through background shifts. For example, the transition from `surface` (white) to `surface_container_low` (#f6f7f8) defines the header and sidebar areas without the need for harsh 1px borders.
*   **Surface Hierarchy:**
    *   **Lowest:** Pure white (#ffffff) for card backgrounds and main content containers.
    *   **Low:** Light gray (#f6f7f8) for the global background.
    *   **Container:** Subtle blue-tinted gray (#f1f3fd) for hover states and secondary active elements.
*   **Signature Textures:** Interactive elements like the "Add New Student" button utilize a subtle box-shadow (shadow-sm) rather than gradients, maintaining a flat, modern editorial aesthetic.

### 3. Typography
Lexend Scholar uses a singular typeface, **Lexend**, across all scales to ensure maximum readability and a unified brand voice.

*   **Display/Headline:** 1.875rem (30px) for Page Titles. 1.25rem (20px) for Section Headers.
*   **Body:** 0.875rem (14px) for general text to maintain high information density without sacrificing legibility.
*   **Label/Mono:** 0.75rem (12px) for table headers and metadata. Mono-styled IDs use the same size but with increased tracking.
*   **Rhythm:** The system uses a tight line-height (leading-tight) for headings to create a compact, professional look.

### 4. Elevation & Depth
Depth is expressed through layering rather than intense shadows.

*   **The Layering Principle:** The sidebar and header exist on a higher "logical" plane than the background content, defined by the `outline` variant at the edges.
*   **Ambient Shadows:** The system exclusively uses "shadow-sm" (a very soft, 1-2px blur) to lift cards and primary action buttons.
*   **Glassmorphism:** While restricted in high-data areas, the notification badges and floating tooltips use semi-transparent backgrounds to maintain context.

### 5. Components
*   **Buttons:** Primary buttons are solid #137fec with white text. Secondary buttons use an outline or ghost style with `text-secondary` (#617589).
*   **Status Chips:** Use a high-contrast pairing of light background and dark text (e.g., Green-100/800 for Active) to provide instant visual scanning.
*   **Tables:** High-density layout with 16px horizontal padding. The header row is distinguished by `surface_container_low` and uppercase, semi-bold labels.
*   **Inputs:** Large, accessible search bars with 10px vertical padding and integrated icons to reduce cognitive load.

### 6. Do's and Don'ts
*   **Do:** Use 0.5rem (lg) corner radius for cards and 0.75rem (xl) for containers to maintain a soft but professional feel.
*   **Do:** Use `primary/10` (10% opacity) for active navigation states to show selection without overwhelming the user.
*   **Don't:** Use pure black for text; use `text-main` (#111418) to avoid harsh contrast.
*   **Don't:** Overuse borders. Let the whitespace and background shifts create the structure.