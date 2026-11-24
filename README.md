# z_uwucafe v2.0.9

A complete player-operated UwU Cat Cafe job for **ESX Legacy** and the ox ecosystem.

## Required resources

- `es_extended`
- `ox_lib`
- `ox_target`
- `ox_inventory`
- `oxmysql`

Optional:

- `esx_status` for hunger and thirst effects
- `skinchanger` + `esx_skin` for the included wardrobe adapter

## Complete feature set

### Employees and progression

- Six job grades from Trainee to Owner
- Server-authoritative duty state
- Duty sessions, total work time and AFK clock-out
- Business-funded payroll calculated from real duty time
- Employee blips while on duty
- General XP, job levels and five skill categories
- Cooking, drinks, service, delivery and management statistics
- Uniform and civilian outfit switching
- Online hiring plus online/offline firing and grade changes
- Grade-based tablet pages and action permissions controlled from `Config.TabletAccess`

### Production and inventory

- Seven configurable workstations
- Multi-stage recipes and recipe unlocks
- Skill checks, progress animations and station validation
- Ingredient checks and atomic rollback on failed inventory operations
- Product quality based on skill, equipment and cleanliness
- Freshness metadata and expired-food protection
- Quality-scaled hunger and thirst effects
- Shared ingredient storage with grade access
- Low-stock monitoring
- Forty-two included inventory item icons

### Orders and service

- Public counter orders
- Table ordering and table service
- Remote delivery orders through `/uwuorder`
- Exportable delivery/menu entry points for phone resources
- Register billing with customer approval before payment
- Cash or bank payments, tips, fees and promotions
- Kitchen queue with controlled status transitions
- Exact finished products consumed when an order is marked ready
- Product quality preserved in fulfilled orders
- Pickup counter collection
- Offline and online refund handling
- Prepared-order expiry, refund and stock recovery
- Customer reconnect recovery
- Staff-call system for tables

### NPC customers

- Server-controlled NPC order generation
- Configurable staffing, cleanliness and capacity requirements
- Host reassignment if an employee disconnects
- Wait-time, quality and cleanliness-based ratings
- Tips affected by service and marketing upgrades
- Automatic timeout and reputation penalties

### Logistics and catering

- Supplier runs with company-funded supply packs
- Work vehicle, pickup and return stages
- Vehicle damage penalties
- Customer delivery assignments
- Customer-presence and destination validation
- Configurable catering contracts and destinations
- Required-item verification and rollback
- Employee bonuses, business rewards and progression
- Manual cancellation command and disconnect recovery

### Business management

- Private business account
- Deposits and owner-only withdrawals
- Revenue, expenses, orders, ratings and best-seller analytics
- Transaction history
- Reputation levels and premium menu unlocks
- Product/category/all-menu promotions
- Equipment condition, repair and four upgrade levels
- Marketing, service and logistics business upgrades
- Cleanliness, cleaning actions and health inspections
- Discord webhooks for duty, orders, management, security and deliveries

### Security

- All prices, rewards, payments and progression calculated server-side
- Job, grade, duty and distance checks
- Craft tokens and minimum craft-time validation
- Action rate limits
- Maximum order quantities, lines, tips and values
- Atomic item rollback where supported
- Duplicate order completion protection
- Consent-based register payments
- Offline refund queue
- Sanitized text inputs
- Server-side delivery and customer validation

## Fresh installation

1. Copy the `z_uwucafe` folder into your FiveM resources directory.
2. Import `sql/install.sql` into the same database used by ESX.
3. Paste all entries from `install/ox_inventory_items.lua` into `ox_inventory/data/items.lua`.
4. Copy every PNG from `install/images/` into `ox_inventory/web/images/`.
5. Review all coordinates and gameplay values in `config.lua`. The defaults target the common Gabz UwU Cafe MLO.
6. Restart `ox_inventory` after adding the items.
7. Start the resources in this order:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure ox_target
ensure ox_inventory
ensure z_uwucafe
```

8. Assign the owner job for testing:

```sql
UPDATE users
SET job = 'uwucafe', job_grade = 5
WHERE identifier = 'YOUR_ESX_IDENTIFIER';
```

See `docs/INSTALLATION.md` for detailed deployment steps.

## Upgrade from v1.x

1. Back up the database and the old resource.
2. Run `sql/migrate_v1_to_v2.sql` once.
3. Run `sql/install.sql` afterward.
4. Replace the resource files and inventory items.
5. Copy the included icons and restart the dependencies.

Do not run the migration on a fresh installation.

## Commands

| Command | Purpose |
|---|---|
| `/uwuduty` | Clock in or out near the duty point |
| `/uwutablet` | Open the employee tablet while on duty |
| `/uwuorder` | Open a remote customer delivery order |
| `/uwumenu` | Browse the menu remotely; counter purchases still require the terminal |
| `/uwucanceljob` | Cancel the active supply, customer-delivery or catering job |

## Client exports

```lua
-- Open remote delivery ordering from a phone or another resource.
exports.z_uwucafe:OpenDeliveryMenu()

-- Open the menu with a custom context.
exports.z_uwucafe:OpenCafeMenu({ orderType = 'terminal' })
exports.z_uwucafe:OpenCafeMenu({ orderType = 'table', tableNumber = 2 })
```

See `docs/INTEGRATIONS.md` for phone, wardrobe and status adapters.

## Main configuration sections

- `Config.Features` — independently enable advanced systems
- `Config.TabletAccess` — minimum grade for every tablet page and privileged action
- `Config.Locations`, `Config.Zones`, `Config.Stations`, `Config.Tables`
- `Config.Duty`, `Config.Progression`, `Config.Security`
- `Config.Products`, `Config.Recipes`, `Config.SupplyPacks`
- `Config.NPC`, `Config.Catering`, `Config.Promotions`
- `Config.Equipment`, `Config.BusinessUpgrades`, `Config.ReputationLevels`
- `Config.Webhooks`, `Config.Wardrobe`, `Config.Blips`

## Verification performed on this package

- Every loaded Lua file was compiled with LuaTeX's Lua parser.
- `web/app.js` passed Node's syntax checker.
- All registered callbacks and internal events were cross-checked against their callers.
- Every referenced custom database table exists in `sql/install.sql`.
- Every product, recipe result, ingredient, supply item and catering item has an `ox_inventory` definition.
- Every inventory item has a matching included PNG icon.

A FiveM resource cannot be guaranteed to behave identically on every server without running it against that server's exact ESX build, database schema, MLO, appearance resource and dependency versions. Use `docs/TEST_CHECKLIST.md` for the final live-server acceptance test.


## Interface icons

The NUI uses bundled inline SVG icons. It contains no emoji-based navigation or product-category graphics and does not require an external icon CDN.


## NPC departure configuration

After receiving an order, an NPC walks to `Config.NPC.exit` and is then removed. The behavior is controlled through `Config.NPC.departure`, including walking speed, arrival distance, route retry interval, despawn delay, fade-out, and a maximum walk timeout for stuck NPCs.


## Tablet grade permissions

Tablet access is configured in `Config.TabletAccess`. Each page and action has its own minimum job grade. Restricted pages are removed from the sidebar, read-only pages hide unavailable controls, and the server validates the permission again for every action.

Default access:

| Grade | Tablet access |
|---:|---|
| 0 — Trainee | Kitchen orders, deliveries, stock, personal progress |
| 1 — Employee | Trainee access plus register and catering |
| 2 — Senior | Employee access plus supply runs |
| 3 — Supervisor | Senior access plus business dashboard and equipment repairs |
| 4 — Manager | Supervisor access plus equipment upgrades, promotions and staff management |
| 5 — Owner | Full access, including withdrawals and business upgrades |

See `docs/TABLET_PERMISSIONS.md` for every configurable key.
