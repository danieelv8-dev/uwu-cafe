local ESX = UwU.ESX

local function getActive(source, token, expectedType)
    local job = UwU.Server.ActiveLogistics[source]
    if not job or job.token ~= token or (expectedType and job.type ~= expectedType) then return nil end
    if os.time() > job.expiresAt then
        if UwU.CancelActiveLogistics then UwU.CancelActiveLogistics(source, token) else UwU.Server.ActiveLogistics[source] = nil end
        return nil
    end
    return job
end

lib.callback.register('z_uwucafe:server:startSupplyRun', function(source, packId)
    local pack = Config.SupplyPacks[packId]
    if not pack then return { success = false, message = 'Invalid supply pack.' } end
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'startSupplyRun')
    if not allowed then return { success = false, message = deniedMessage } end
    if not UwU.RequireEmployee(source, pack.minimumGrade or 0, true) then return { success = false, message = _L('no_permission') } end
    if UwU.Server.ActiveLogistics[source] then return { success = false, message = _L('already_delivery') } end
    local business = UwU.GetBusiness()
    if business.reputation < (pack.minimumReputation or 0) then return { success = false, message = 'The business reputation is too low for this supplier.' } end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not UwU.RemoveBusinessMoney(pack.cost, ('Supply pack: %s'):format(pack.label), xPlayer.identifier, { pack = packId }) then
        return { success = false, message = _L('business_funds') }
    end
    local token = UwU.Token('supply')
    UwU.Server.ActiveLogistics[source] = {
        token = token, type = 'supply', packId = packId, stage = 'supplier',
        startedAt = os.time(), expiresAt = os.time() + Config.SupplyDelivery.timeoutMinutes * 60
    }
    MySQL.insert.await([[
        INSERT INTO z_uwucafe_deliveries (identifier, delivery_type, reference_id, pack_id, token, status, cost)
        VALUES (?, 'supply', NULL, ?, ?, 'started', ?)
    ]], { xPlayer.identifier, packId, token, pack.cost })
    UwU.TouchDuty(source)
    return { success = true, type = 'supply', token = token, packId = packId, message = _L('supply_started') }
end)

lib.callback.register('z_uwucafe:server:pickupSupplyRun', function(source, token)
    local job = getActive(source, token, 'supply')
    if not job or job.stage ~= 'supplier' then return { success = false, message = 'This supply run is no longer valid.' } end
    if not UwU.IsNear(source, Config.SupplyDelivery.supplier, Config.SupplyDelivery.pickupDistance + 2.0) then return { success = false, message = _L('too_far') } end
    job.stage = 'return'
    MySQL.update.await("UPDATE z_uwucafe_deliveries SET status = 'picked_up' WHERE token = ?", { token })
    UwU.TouchDuty(source)
    return { success = true }
end)

lib.callback.register('z_uwucafe:server:completeSupplyRun', function(source, token, vehicleHealth)
    local job = getActive(source, token, 'supply')
    if not job or job.stage ~= 'return' then return { success = false, message = 'This supply run is no longer valid.' } end
    if not UwU.IsNear(source, Config.Locations.deliveryReturn, Config.SupplyDelivery.returnDistance) then return { success = false, message = _L('too_far') } end
    local pack = Config.SupplyPacks[job.packId]
    if not pack then return { success = false, message = 'Supply pack configuration is missing.' } end

    UwU.EnsureStashLoaded(Config.Stock.stashId)
    local inserted = {}
    for item, amount in pairs(pack.items) do
        local success = exports.ox_inventory:AddItem(Config.Stock.stashId, item, amount)
        if success then
            inserted[#inserted + 1] = { item = item, amount = amount }
        else
            for _, entry in ipairs(inserted) do exports.ox_inventory:RemoveItem(Config.Stock.stashId, entry.item, entry.amount) end
            return { success = false, message = 'The stock storage is full. Clear space and try again.' }
        end
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local health = UwU.Clamp(tonumber(vehicleHealth) or 1000, 0, 1000)
    local penalty = math.floor((1000 - health) / 1000 * Config.SupplyDelivery.damagePenaltyMaximum)
    if penalty > 0 then UwU.RemoveBusinessMoney(penalty, ('Supply vehicle damage: %s'):format(pack.label), xPlayer.identifier, { token = token }) end
    UwU.AddProgress(xPlayer.identifier, Config.Progression.generalXp.supplyDelivery, 'supply_deliveries', 'delivery', Config.Progression.skillXp.supplyDelivery)
    MySQL.update.await("UPDATE z_uwucafe_deliveries SET status = 'completed', damage_penalty = ?, completed_at = NOW() WHERE token = ?", { penalty, token })
    UwU.Server.ActiveLogistics[source] = nil
    UwU.TouchDuty(source)
    UwU.Log('deliveries', 'Supply completed', ('%s delivered %s. Damage penalty: $%s'):format(xPlayer.getName(), pack.label, penalty))
    return { success = true, message = _L('supply_complete'), penalty = penalty }
end)

lib.callback.register('z_uwucafe:server:acceptCustomerDelivery', function(source, orderId)
    if not Config.Features.customerDelivery then return { success = false, message = 'Customer delivery is disabled.' } end
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'acceptDelivery')
    if not allowed then return { success = false, message = deniedMessage } end
    if not UwU.RequireEmployee(source, Config.CustomerDelivery.minimumGrade, true) then return { success = false, message = _L('no_permission') } end
    if UwU.Server.ActiveLogistics[source] then return { success = false, message = _L('already_delivery') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local order = UwU.GetOrder(orderId)
    if not order or order.order_type ~= 'delivery' or order.status ~= 'ready' or order.delivery_status ~= 'ready_for_driver' then
        return { success = false, message = 'This order is not available for delivery.' }
    end
    local changed = MySQL.update.await([[
        UPDATE z_uwucafe_orders SET delivery_status = 'assigned', delivery_identifier = ?, updated_at = NOW()
        WHERE id = ? AND status = 'ready' AND delivery_status = 'ready_for_driver'
    ]], { xPlayer.identifier, order.id })
    if not changed or changed < 1 then return { success = false, message = 'Another employee accepted this delivery.' } end

    local token = UwU.Token('customer-delivery')
    UwU.Server.ActiveLogistics[source] = {
        token = token, type = 'customer_delivery', orderId = order.id,
        expiresAt = os.time() + Config.Ordering.deliveryTimeoutMinutes * 60
    }
    MySQL.insert.await([[
        INSERT INTO z_uwucafe_deliveries (identifier, delivery_type, reference_id, token, status, cost)
        VALUES (?, 'customer', ?, ?, 'assigned', 0)
    ]], { xPlayer.identifier, order.id, token })
    UwU.TouchDuty(source)
    return {
        success = true, type = 'customer_delivery', token = token, orderId = order.id,
        destination = { x = tonumber(order.delivery_x), y = tonumber(order.delivery_y), z = tonumber(order.delivery_z) },
        message = _L('delivery_started')
    }
end)

lib.callback.register('z_uwucafe:server:completeCustomerDelivery', function(source, token)
    local job = getActive(source, token, 'customer_delivery')
    if not job then return { success = false, message = 'This delivery is no longer active.' } end
    local success, message = UwU.CompleteDeliveryOrder(source, job.orderId)
    if not success then return { success = false, message = message } end
    MySQL.update.await("UPDATE z_uwucafe_deliveries SET status = 'completed', completed_at = NOW() WHERE token = ?", { token })
    UwU.Server.ActiveLogistics[source] = nil
    return { success = true, message = message }
end)

function UwU.GenerateCateringContracts()
    if not Config.Features.catering then return end
    local available = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM z_uwucafe_catering WHERE status = 'available' AND expires_at > NOW()")) or 0
    local needed = math.max(0, Config.Catering.maximumAvailable - available)
    if needed <= 0 then return end

    local templateKeys = {}
    for key in pairs(Config.CateringTemplates) do templateKeys[#templateKeys + 1] = key end
    for _ = 1, needed do
        local key = templateKeys[math.random(#templateKeys)]
        local template = Config.CateringTemplates[key]
        local destination = Config.Catering.destinations[math.random(#Config.Catering.destinations)]
        local reward = math.random(template.reward.min, template.reward.max)
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_catering
                (template_key, label, destination_id, destination_label, items_json, reward, minimum_reputation, status, expires_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'available', DATE_ADD(NOW(), INTERVAL ? MINUTE))
        ]], {
            key, template.label, destination.id, destination.label, json.encode(template.items), reward,
            template.minimumReputation or 0, Config.Catering.refreshMinutes * 3
        })
    end
end

function UwU.GetCateringContracts(identifier)
    UwU.GenerateCateringContracts()
    local rows = MySQL.query.await([[
        SELECT * FROM z_uwucafe_catering
        WHERE (status = 'available' AND expires_at > NOW()) OR (status = 'accepted' AND accepted_by = ?)
        ORDER BY FIELD(status, 'accepted', 'available'), reward DESC LIMIT 20
    ]], { identifier or '' }) or {}
    for _, row in ipairs(rows) do row.items = json.decode(row.items_json or '{}') or {} end
    return rows
end

lib.callback.register('z_uwucafe:server:acceptCatering', function(source, contractId)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'acceptCatering')
    if not allowed then return { success = false, message = deniedMessage } end
    if not UwU.RequireEmployee(source, Config.Catering.minimumGrade, true) then return { success = false, message = _L('no_permission') } end
    if UwU.Server.ActiveLogistics[source] then return { success = false, message = _L('already_delivery') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local contract = MySQL.single.await("SELECT * FROM z_uwucafe_catering WHERE id = ? AND status = 'available' AND expires_at > NOW()", { contractId })
    if not contract then return { success = false, message = 'This contract is no longer available.' } end
    if UwU.GetBusiness().reputation < tonumber(contract.minimum_reputation) then return { success = false, message = 'The business reputation is too low.' } end
    local changed = MySQL.update.await([[
        UPDATE z_uwucafe_catering SET status = 'accepted', accepted_by = ?, accepted_at = NOW(),
            due_at = DATE_ADD(NOW(), INTERVAL ? MINUTE)
        WHERE id = ? AND status = 'available'
    ]], { xPlayer.identifier, Config.Catering.acceptanceTimeoutMinutes, contract.id })
    if not changed or changed < 1 then return { success = false, message = 'Another employee accepted this contract.' } end
    UwU.TouchDuty(source)
    return { success = true, message = _L('catering_started') }
end)

local function removeContractItems(source, items)
    for item, amount in pairs(items) do
        if UwU.GetInventoryItemCount(source, item) < tonumber(amount) then return false, ('Missing %sx %s.'):format(amount, item) end
    end
    local removed = {}
    for item, amount in pairs(items) do
        local success = exports.ox_inventory:RemoveItem(source, item, tonumber(amount))
        if not success then
            for _, entry in ipairs(removed) do exports.ox_inventory:AddItem(source, entry.item, entry.amount) end
            return false, 'The catering items could not be removed.'
        end
        removed[#removed + 1] = { item = item, amount = tonumber(amount) }
    end
    return true, removed
end

lib.callback.register('z_uwucafe:server:startCateringDelivery', function(source, contractId)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'startCateringDelivery')
    if not allowed then return { success = false, message = deniedMessage } end
    if not UwU.RequireEmployee(source, Config.Catering.minimumGrade, true) then return { success = false, message = _L('no_permission') } end
    if UwU.Server.ActiveLogistics[source] then return { success = false, message = _L('already_delivery') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local contract = MySQL.single.await("SELECT * FROM z_uwucafe_catering WHERE id = ? AND status = 'accepted' AND accepted_by = ? AND due_at > NOW()", { contractId, xPlayer.identifier })
    if not contract then return { success = false, message = 'This catering contract is not active.' } end
    if not UwU.IsNear(source, Config.Locations.cateringDispatch, 8.0) then return { success = false, message = _L('too_far') } end
    local items = json.decode(contract.items_json or '{}') or {}
    local success, removed = removeContractItems(source, items)
    if not success then return { success = false, message = removed } end
    local destination = UwU.FindCateringDestination(contract.destination_id)
    if not destination then
        for _, entry in ipairs(removed) do exports.ox_inventory:AddItem(source, entry.item, entry.amount) end
        return { success = false, message = 'Catering destination is missing from config.' }
    end
    local token = UwU.Token('catering')
    UwU.Server.ActiveLogistics[source] = {
        token = token, type = 'catering', contractId = contract.id, removedItems = removed, identifier = xPlayer.identifier,
        expiresAt = os.time() + Config.Catering.acceptanceTimeoutMinutes * 60
    }
    MySQL.update.await("UPDATE z_uwucafe_catering SET status = 'in_transit', token = ? WHERE id = ?", { token, contract.id })
    return { success = true, type = 'catering', token = token, contractId = contract.id, destination = destination, message = 'Catering loaded. Deliver it to the marked destination.' }
end)

lib.callback.register('z_uwucafe:server:completeCatering', function(source, token)
    local job = getActive(source, token, 'catering')
    if not job then return { success = false, message = 'This catering run is no longer active.' } end
    local contract = MySQL.single.await("SELECT * FROM z_uwucafe_catering WHERE id = ? AND status = 'in_transit' AND token = ?", { job.contractId, token })
    if not contract then return { success = false, message = 'This catering contract is no longer valid.' } end
    local destination = UwU.FindCateringDestination(contract.destination_id)
    if not destination or not UwU.IsNear(source, destination.coords, 12.0) then return { success = false, message = _L('too_far') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local changed = MySQL.update.await("UPDATE z_uwucafe_catering SET status = 'completed', completed_at = NOW() WHERE id = ? AND status = 'in_transit'", { contract.id })
    if not changed or changed < 1 then return { success = false, message = 'Contract state changed.' } end
    local reward = tonumber(contract.reward) or 0
    UwU.AddBusinessMoney(reward, ('Catering contract #%s'):format(contract.id), xPlayer.identifier, { template = contract.template_key })
    local employeeBonus = math.min(350, math.floor(reward * 0.10))
    if UwU.RemoveBusinessMoney(employeeBonus, ('Catering bonus #%s'):format(contract.id), xPlayer.identifier) then
        xPlayer.addAccountMoney('bank', employeeBonus, 'UwU Cafe catering bonus')
    end
    UwU.ChangeReputation(math.max(2, math.floor(reward / 500)))
    UwU.AddProgress(xPlayer.identifier, Config.Progression.generalXp.catering, 'catering_completed', 'delivery', Config.Progression.skillXp.catering)
    UwU.Server.ActiveLogistics[source] = nil
    UwU.TouchDuty(source)
    return { success = true, message = _L('catering_complete'), reward = reward, bonus = employeeBonus }
end)

function UwU.CancelActiveLogistics(source, token)
    local job = UwU.Server.ActiveLogistics[source]
    if not job or (token and job.token ~= token) then return false end
    local xPlayer = ESX.GetPlayerFromId(source)
    if job.type == 'supply' then
        MySQL.update.await("UPDATE z_uwucafe_deliveries SET status = 'cancelled' WHERE token = ?", { job.token })
    elseif job.type == 'customer_delivery' then
        MySQL.update.await("UPDATE z_uwucafe_orders SET delivery_status = 'ready_for_driver', delivery_identifier = NULL WHERE id = ? AND delivery_status = 'assigned'", { job.orderId })
        MySQL.update.await("UPDATE z_uwucafe_deliveries SET status = 'cancelled' WHERE token = ?", { job.token })
    elseif job.type == 'catering' then
        if xPlayer then
            for _, entry in ipairs(job.removedItems or {}) do exports.ox_inventory:AddItem(source, entry.item, entry.amount) end
        else
            UwU.EnsureStashLoaded(Config.Stock.stashId)
            for _, entry in ipairs(job.removedItems or {}) do exports.ox_inventory:AddItem(Config.Stock.stashId, entry.item, entry.amount) end
        end
        MySQL.update.await("UPDATE z_uwucafe_catering SET status = 'accepted', token = NULL WHERE id = ? AND accepted_by = ?", { job.contractId, job.identifier or (xPlayer and xPlayer.identifier or '') })
    end
    UwU.Server.ActiveLogistics[source] = nil
    return true
end

RegisterNetEvent('z_uwucafe:server:cancelLogistics', function(token)
    UwU.CancelActiveLogistics(source, token)
end)
