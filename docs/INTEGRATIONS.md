# Integrations

## Phone and external menu resources

The cafe intentionally exposes generic client exports so it does not hard-depend on one phone resource:

```lua
exports.z_uwucafe:OpenDeliveryMenu()
exports.z_uwucafe:OpenCafeMenu({ orderType = 'terminal' })
```

Call `OpenDeliveryMenu` from a phone app button, radial menu or command. Delivery coordinates are captured and validated server-side when the order is placed.

Example client event bridge:

```lua
RegisterNetEvent('my_phone:client:openUwuCafe', function()
    exports.z_uwucafe:OpenDeliveryMenu()
end)
```

A native custom app UI for LB Phone, QS Smartphone or YSeries must be registered using that phone's own current app API. Keep the cafe resource unchanged and call the export above from the adapter.

## Appearance resources

`client/wardrobe.lua` supports `skinchanger`. To support Illenium Appearance, fivem-appearance or another system, preserve these events while replacing their internal implementation:

```text
z_uwucafe:client:openWardrobe
```

## Hunger and thirst

`client/consumables.lua` applies effects through `esx_status` when that resource is running. Adapt that one file for another status resource.

## Other resources

Use the exported customer menu instead of firing internal server callbacks. Prices and payments must remain server-authoritative.
