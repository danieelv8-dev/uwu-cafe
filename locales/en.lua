Locales = Locales or {}
Locales.en = {
    not_employee = 'You do not work at UwU Cat Cafe.',
    not_on_duty = 'You must be clocked in.',
    clocked_in = 'You clocked in.',
    clocked_out = 'You clocked out.',
    no_permission = 'You do not have permission to do that.',
    too_far = 'You are too far away.',
    missing_ingredients = 'You do not have the required ingredients.',
    inventory_full = 'Your inventory cannot hold the result.',
    crafted = 'You prepared %sx %s.',
    invalid_order = 'That order is invalid.',
    payment_failed = 'The payment could not be completed.',
    order_created = 'Order #%s was created.',
    order_updated = 'Order #%s was updated.',
    order_ready = 'Order #%s is ready.',
    order_collected = 'Order #%s was collected.',
    order_not_ready = 'That order is not ready.',
    order_missing_items = 'You need all prepared products before marking this order ready.',
    supply_started = 'Supply run started. Drive to the supplier.',
    supply_loaded = 'Supplies loaded. Return to UwU Cat Cafe.',
    supply_complete = 'Supply delivery completed.',
    already_delivery = 'You already have an active logistics job.',
    business_funds = 'The business does not have enough money.',
    cleaned = 'The area is clean again.',
    cooldown = 'Slow down and try again.',
    equipment_broken = 'This equipment needs to be repaired.',
    customer_declined = 'The customer declined the bill.',
    delivery_started = 'Delivery accepted. Follow the GPS route.',
    delivery_complete = 'Customer delivery completed.',
    catering_started = 'Catering contract accepted.',
    catering_complete = 'Catering contract completed.',
    staff_called = 'A customer at table %s needs assistance.',
    npc_rated_cafe = '%s rated the cafe',
    npc_rating = '%s/5 stars',
    npc_rating_tip = '%s/5 stars • $%s tip',
    payroll_paid = 'You received $%s for %s minutes of work.',
    payroll_unpaid = 'The business could not cover your $%s payroll.'
}

function _L(key, ...)
    local language = Locales[Config.Locale] or Locales.en
    local value = language[key] or key
    if select('#', ...) > 0 then return value:format(...) end
    return value
end
