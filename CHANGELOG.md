# Changelog

## 2.0.9

- Added configurable grade-based tablet page permissions.
- Added separate minimum grades for privileged tablet actions.
- Hidden inaccessible sidebar pages and added read-only controls where page and action access differ.
- Added server-side permission checks for register billing, order handling, deliveries, supply runs, catering, finances, equipment, promotions, staff management and business upgrades.
- Filtered employee bootstrap data so restricted financial, staff, equipment and logistics data is not sent to lower grades.
- Preserved the user-provided v2.0.8 coordinates and gameplay configuration.

## 2.0.8

- NPC customers now leave on foot after receiving their order.
- NPCs are despawned after reaching the configured exit.
- Added stuck-NPC timeout, route retry, optional fade-out, and immediate-cleanup configuration.
- Added localized NPC rating notifications.

## 2.0.7

- Replaced the temporary sidebar logo with the user-provided UwU Cafe Dishes & Desserts artwork.
- Cropped only transparent padding so the supplied logo remains clear at tablet-sidebar size.
- Bundled the logo locally as a transparent PNG with no external dependency.

## 2.0.6

- Replaced the shield-style sidebar mark with a bundled UwU Cat Café vector logo.
- Updated the top-left wordmark to UWU CAT CAFÉ.
- Kept the logo self-contained with no CDN or external image dependency.

## 2.0.5

- Standardized every internal interface corner to a 5px radius.
- Kept the tablet's exterior chassis and outer decorative ring rounded.
- Updated cards, controls, navigation, badges, fields, progress bars and scrollbars.

## 2.0.4

- Rebuilt the tablet sidebar to match a structured management-panel layout.
- Added a larger café identity block and portal mode label.
- Converted navigation into full-width bordered controls with a stronger active state.
- Moved employee identity into a clean footer separated by a divider.
- Preserved responsive collapsed navigation on smaller screens.

## 2.0.3

- Turned the iPad home indicator into the tablet close control.
- Removed the Refresh and close buttons from the top-right header.
- Removed the dark full-screen NUI overlay and blur so the game remains visible behind the tablet.
- Kept Escape as a secondary keyboard close control.

## 2.0.2

- Rebuilt the NUI inside a landscape iPad-style chassis with a metal bezel, camera and home indicator.
- Fixed the main content panel so mouse-wheel, trackpad and keyboard scrolling work reliably.
- Added independent scrolling for the sidebar, main content, tables and long register carts.
- Added visible custom scrollbars and preserved scroll position while changing product quantities or switching tabs.
- Improved responsive tablet layouts for lower resolutions and narrower aspect ratios.

## 2.0.1

- Replaced all NUI emoji glyphs with local inline SVG icons.
- Added vector icons for navigation, product categories, branding, refresh, close, and quantity controls.
- Removed external icon-library requirements; the interface remains fully self-contained.

## 2.0.0

- Added full table service, delivery ordering, catering and NPC customers.
- Added consent-based register billing and offline refunds.
- Added server-validated finished-product fulfillment with quality metadata.
- Added equipment condition, repair and upgrade systems.
- Added promotions, reputation tiers and business upgrades.
- Added payroll, AFK protection, employee blips and expanded progression.
- Added offline employee management and advanced business analytics.
- Added health inspections, staff calls and prepared-order expiry recovery.
- Added forty-two inventory icons and full deployment documentation.
