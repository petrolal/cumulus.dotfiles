# Theme Engine Design Specification

## 1. Neutral Base Specification (Constant across all themes)
- **Canvas (Monolith Base):** `#0F1117`
- **Surface / Pill Container:** `#191C24`
- **Border / Divider:** `#2B303C`
- **Foreground Text:** `#F8FAFC`
- **Subdued / Muted Text:** `#64748B`

These tokens form the immutable foundation for every theme variant. All UI components reference these constants, ensuring layout stability and visual consistency regardless of accent changes.

## 2. Theme Variant Token Matrix
| Variant | Primary Accent | Secondary Accent |
|---------|----------------|-----------------|
| **Matriz** (Default / Cube) | `#EBB434` (Gold) | `#00D2D3` (Teal) |
| **Encruza** (Obsidian & Carmine) | `#EE5253` (Carmine Red) | `#3A3F4D` (Slate Graphite) |
| **Caravela** (Atlantic Coast) | `#0984E3` (Deep Ocean) | `#00CEC9` (Maré Teal) |
| **Aruanda** (Forest & Sunlight) | `#10AC84` (Mata Green) | `#F5CD79` (Warm Amber) |

Each variant swaps only the **Primary** and **Secondary** accent tokens while keeping the neutral base unchanged. The UI references these tokens via CSS custom properties (e.g., `--accent-primary`, `--accent-secondary`).

## 3. Wallpaper Pairing Guide
- **Matriz:** `assets/wallpapers/matriz.jpg` – golden sunrise over geometric landscape.
- **Encruza:** `assets/wallpapers/encruza.jpg` – deep red obsidian cliffs at dusk.
- **Caravela:** `assets/wallpapers/caravela.jpg` – turquoise Atlantic horizon with sailing ships.
- **Aruanda:** `assets/wallpapers/aruanda.jpg` – lush forest canopy with sunbeams.

Each wallpaper is chosen to complement its accent palette, providing visual cohesion while keeping the underlying layout untouched.

## 4. Token Injection & Dynamic Switching
- The file `~/.config/polyomino/theme.css` defines all custom properties using the neutral base and current accent tokens.
- `scripts/polyomino-theme` updates the linked `theme.css` and triggers a wallpaper change via `swaybg`.
- Waybar imports `theme.css` with `@import "theme.css"`; Sway sources the same token variables via an included snippet.
- Changing the token file does **not** affect layout rules, gaps, or border radii, guaranteeing a DRY, single‑source‑of‑truth styling system.
