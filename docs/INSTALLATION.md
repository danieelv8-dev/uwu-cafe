# Installation and Deployment

## 1. Back up first

Back up your database, `server.cfg`, current inventory item file and any previous `z_uwucafe` resource.

## 2. Install the database

### Fresh server

Import:

```text
sql/install.sql
```

### Existing z_uwucafe v1.x server

Import in this order:

```text
sql/migrate_v1_to_v2.sql
sql/install.sql
```

The migration is intended for the original v1 schema and should only be run once.

## 3. Install inventory items

Open:

```text
ox_inventory/data/items.lua
```

Paste every entry from:

```text
z_uwucafe/install/ox_inventory_items.lua
```

inside the main item table. Do not paste the surrounding comments into another item definition.

Copy all files from:

```text
z_uwucafe/install/images/
```

to:

```text
ox_inventory/web/images/
```

Restart `ox_inventory` after changing its item registry.

## 4. Configure coordinates

The supplied coordinates target the common Gabz UwU Cafe MLO. Check every location in:

- `Config.Locations`
- `Config.Ordering.pickupCounter`
- `Config.Stations`
- `Config.CleaningSpots`
- `Config.Tables`
- `Config.SupplyDelivery`
- `Config.NPC`
- `Config.Catering.destinations`

Turn `Config.Debug = true` temporarily to see target zones while aligning a different MLO.

## 5. Start order

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure ox_target
ensure ox_inventory
ensure z_uwucafe
```

Do not start the cafe before its dependencies.

## 6. Give an owner job

Use the identifier format already stored in your ESX `users` table:

```sql
UPDATE users
SET job = 'uwucafe', job_grade = 5
WHERE identifier = 'license:REPLACE_ME';
```

Log out and back in, or use your server's supported job command, after updating the database directly.

## 7. Optional resources

### Food status

Start `esx_status` before the cafe to apply hunger and thirst. Products can still be consumed without it.

### Wardrobe

The included adapter supports `skinchanger` and `esx_skin`. For another appearance system, replace only `client/wardrobe.lua`; the rest of the resource does not depend on it.

### Discord logs

Set `Config.Webhooks.enabled = true` and fill the individual webhook URLs. Never expose those URLs in a client file.

## 8. First boot checks

The server console should print:

```text
[z_uwucafe] Complete UwU Cat Cafe v2.0.1 loaded.
```

Confirm there are no missing-item warnings from `ox_inventory`, no SQL errors, and no duplicate item keys.
