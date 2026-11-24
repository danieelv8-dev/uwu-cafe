local ESX = UwU.ESX

local validStatuses = {
    pending = true,
    accepted = true,
    preparing = true,
    ready = true,
    completed = true,
    cancelled = true
}

local statusTransitions = {
    pending = { accepted = true, cancelled = true },
    accepted = { preparing = true, cancelled = true },
    preparing = { ready = true, cancelled = true },
    ready = { cancelled = true },
    completed = {},
    cancelled = {}
}

local function normaliseCart(cart)
    if type(cart) ~= 'table' then return nil, 0 end
    local items, subtotal, totalCount, lineCount = {}, 0, 0, 0

    for itemName, quantity in pairs(cart) do
        local product = Config.Products[itemName]
        quantity = math.floor(tonumber(quantity) or 0)
        if product and quantity > 0 then
            lineCount = lineCount + 1
            if lineCount > Config.Security.maxOrderLineCount or quantity > Config.Security.maxOrderQuantityPerItem then return nil, 0 end
            local pricing = UwU.GetProductPricing(itemName)
            if not pricing then return nil, 0 end
            totalCount = totalCount + quantity
            subtotal = subtotal + pricing.price * quantity
            items[#items + 1] = {
                item = itemName,
                label = product.label,
                quantity = quantity,
                unitPrice = pricing.price,
                lineTotal = pricing.price * quantity
            }
        end
    end

    if totalCount <= 0 or subtotal <= 0 or subtotal > Config.Security.maxOrderValue then return nil, 0 end
    table.sort(items, function(a, b) return a.label < b.label end)
    return items, math.floor(subtotal)
end

local function takePayment(xPlayer, account, amount, reason)
    if not xPlayer or amount <= 0 then return false end
    if account == 'cash' then
        if xPlayer.getMoney() < amount then return false end
        xPlayer.removeMoney(amount, reason or 'UwU Cafe order')
        return true
    end
    local bank = xPlayer.getAccount('bank')
    if not bank or bank.money < amount then return false end
    xPlayer.removeAccountMoney('bank', amount, reason or 'UwU Cafe order')
    return true
end

local function queueRefund(order, reason)
    if not order or order.payment_status ~= 'paid' or order.order_type == 'npc' then return end
    local amount = tonumber(order.total) or 0
    if amount <= 0 then return end

    local target
    if order.customer_source then target = ESX.GetPlayerFromId(tonumber(order.customer_source)) end
    if not target then
        for _, player in pairs(ESX.GetExtendedPlayers() or {}) do
            if player.identifier == order.customer_identifier then target = player break end
        end
    end

    if target then
        if order.payment_method == 'cash' then target.addMoney(amount, reason or 'UwU Cafe refund')
        else target.addAccountMoney('bank', amount, reason or 'UwU Cafe refund') end
    else
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_refunds (identifier, amount, payment_method, reason)
            VALUES (?, ?, ?, ?)
        ]], { order.customer_identifier, amount, order.payment_method, reason or 'UwU Cafe refund' })
    end
    MySQL.update.await("UPDATE z_uwucafe_orders SET payment_status = 'refunded' WHERE id = ?", { order.id })
end

function UwU.ApplyPendingRefunds(xPlayer)
    if not xPlayer then return end
    local rows = MySQL.query.await("SELECT * FROM z_uwucafe_refunds WHERE identifier = ? AND status = 'pending'", { xPlayer.identifier }) or {}
    for _, refund in ipairs(rows) do
        local amount = tonumber(refund.amount) or 0
        if refund.payment_method == 'cash' then xPlayer.addMoney(amount, refund.reason)
        else xPlayer.addAccountMoney('bank', amount, refund.reason) end
        MySQL.update.await("UPDATE z_uwucafe_refunds SET status = 'paid', paid_at = NOW() WHERE id = ? AND status = 'pending'", { refund.id })
        UwU.Notify(xPlayer.source, ('A pending UwU Cafe refund of $%s was paid.'):format(amount), 'success')
    end
end

local function insertOrder(customer, items, details)
    local orderId = MySQL.insert.await([[
        INSERT INTO z_uwucafe_orders
            (customer_identifier, customer_name, customer_source, employee_identifier, order_type, status,
             payment_method, payment_status, subtotal, fee, tip, total, notes, table_number,
             delivery_x, delivery_y, delivery_z, delivery_status, paid_to_business)
        VALUES (?, ?, NULLIF(?, 0), NULLIF(?, ''), ?, 'pending', ?, ?, ?, ?, ?, ?, ?, NULLIF(?, 0), NULLIF(?, 0), NULLIF(?, 0), NULLIF(?, 0), ?, 0)
    ]], {
        customer.identifier,
        customer.name,
        tonumber(customer.source) or 0,
        details.employeeIdentifier or '',
        details.orderType,
        details.paymentMethod or 'bank',
        details.paymentStatus or 'paid',
        details.subtotal,
        details.fee or 0,
        details.tip or 0,
        details.total,
        UwU.SanitizeText(details.notes),
        tonumber(details.tableNumber) or 0,
        details.deliveryCoords and tonumber(details.deliveryCoords.x) or 0,
        details.deliveryCoords and tonumber(details.deliveryCoords.y) or 0,
        details.deliveryCoords and tonumber(details.deliveryCoords.z) or 0,
        details.orderType == 'delivery' and 'waiting_kitchen' or 'none'
    })
    if not orderId then return nil end

    for _, item in ipairs(items) do
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_order_items (order_id, item_name, item_label, quantity, unit_price)
            VALUES (?, ?, ?, ?, ?)
        ]], { orderId, item.item, item.label, item.quantity, item.unitPrice })
    end

    UwU.ChangeCleanliness(details.orderType == 'npc' and -Config.Business.cleanlinessLossPerNpcOrder or -Config.Business.cleanlinessLossPerOrder)
    MySQL.insert.await('INSERT INTO z_uwucafe_order_events (order_id, event_type, actor_identifier, details) VALUES (?, ?, ?, ?)', {
        orderId, 'created', details.employeeIdentifier or customer.identifier, json.encode({ orderType = details.orderType })
    })
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', orderId)
    return orderId
end

local function getOrderItems(orderId)
    return MySQL.query.await([[
        SELECT item_name AS item, item_label AS label, quantity, unit_price AS unitPrice
        FROM z_uwucafe_order_items WHERE order_id = ? ORDER BY id ASC
    ]], { orderId }) or {}
end

function UwU.GetOrder(orderId)
    local order = MySQL.single.await('SELECT *, UNIX_TIMESTAMP(created_at) AS created_epoch FROM z_uwucafe_orders WHERE id = ?', { tonumber(orderId) })
    if order then order.items = getOrderItems(order.id) end
    return order
end

local function hydrateOrders(rows)
    if #rows == 0 then return rows end
    local ids, placeholders, lookup = {}, {}, {}
    for _, row in ipairs(rows) do
        ids[#ids + 1] = row.id
        placeholders[#placeholders + 1] = '?'
        row.items = {}
        row.fulfillment = row.fulfillment_json and json.decode(row.fulfillment_json) or nil
        lookup[row.id] = row
    end
    local itemRows = MySQL.query.await(([[
        SELECT order_id, item_name AS item, item_label AS label, quantity, unit_price AS unitPrice
        FROM z_uwucafe_order_items WHERE order_id IN (%s) ORDER BY id ASC
    ]]):format(table.concat(placeholders, ',')), ids) or {}
    for _, item in ipairs(itemRows) do
        local order = lookup[item.order_id]
        if order then order.items[#order.items + 1] = item end
    end
    return rows
end

function UwU.GetActiveOrders()
    local rows = MySQL.query.await([[
        SELECT * FROM z_uwucafe_orders
        WHERE status IN ('pending', 'accepted', 'preparing', 'ready')
        ORDER BY FIELD(status, 'ready', 'preparing', 'accepted', 'pending'), id ASC
        LIMIT 100
    ]]) or {}
    return hydrateOrders(rows)
end

function UwU.GetCustomerOrders(identifier)
    local rows = MySQL.query.await([[
        SELECT * FROM z_uwucafe_orders
        WHERE customer_identifier = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        ORDER BY id DESC LIMIT 50
    ]], { identifier }) or {}
    return hydrateOrders(rows)
end

local function inventoryProductSlots(source, itemName)
    local slots = exports.ox_inventory:Search(source, 'slots', itemName) or {}
    local result = {}
    for _, slot in pairs(slots) do
        local metadata = slot.metadata or {}
        local expiresAt = tonumber(metadata.expiresAt)
        if not expiresAt or expiresAt > os.time() then
            result[#result + 1] = {
                slot = slot.slot,
                count = tonumber(slot.count) or 0,
                metadata = metadata,
                qualityScore = tonumber(metadata.qualityScore) or UwU.QualityScore(metadata.quality)
            }
        end
    end
    table.sort(result, function(a, b)
        if a.qualityScore == b.qualityScore then return a.slot < b.slot end
        return a.qualityScore > b.qualityScore
    end)
    return result
end

local function removePreparedProducts(source, items)
    local plan, qualityTotal, qualityUnits = {}, 0, 0
    for _, item in ipairs(items) do
        local required = tonumber(item.quantity) or 0
        local slots = inventoryProductSlots(source, item.item)
        local available = 0
        for _, slot in ipairs(slots) do available = available + slot.count end
        if available < required then return nil, _L('order_missing_items') end

        local remaining = required
        for _, slot in ipairs(slots) do
            if remaining <= 0 then break end
            local take = math.min(remaining, slot.count)
            plan[#plan + 1] = {
                item = item.item,
                label = item.label,
                count = take,
                slot = slot.slot,
                metadata = slot.metadata,
                qualityScore = slot.qualityScore
            }
            qualityTotal = qualityTotal + slot.qualityScore * take
            qualityUnits = qualityUnits + take
            remaining = remaining - take
        end
    end

    local removed = {}
    for _, entry in ipairs(plan) do
        local success = exports.ox_inventory:RemoveItem(source, entry.item, entry.count, nil, entry.slot)
        if not success then
            for _, rollback in ipairs(removed) do
                exports.ox_inventory:AddItem(source, rollback.item, rollback.count, rollback.metadata)
            end
            return nil, _L('order_missing_items')
        end
        removed[#removed + 1] = entry
    end

    local grouped = {}
    for _, entry in ipairs(removed) do
        local key = entry.item
        grouped[key] = grouped[key] or { item = entry.item, label = entry.label, quantity = 0, qualityTotal = 0 }
        grouped[key].quantity = grouped[key].quantity + entry.count
        grouped[key].qualityTotal = grouped[key].qualityTotal + entry.qualityScore * entry.count
    end
    local fulfillment = {}
    for _, entry in pairs(grouped) do
        local average = math.floor(entry.qualityTotal / math.max(1, entry.quantity))
        fulfillment[#fulfillment + 1] = {
            item = entry.item,
            label = entry.label,
            quantity = entry.quantity,
            metadata = { quality = UwU.QualityLabel(average), qualityScore = average, fulfilledAt = os.time() }
        }
    end
    table.sort(fulfillment, function(a, b) return a.label < b.label end)
    return fulfillment, math.floor(qualityTotal / math.max(1, qualityUnits))
end

local function canReceiveFulfillment(source, fulfillment)
    for _, entry in ipairs(fulfillment or {}) do
        if not exports.ox_inventory:CanCarryItem(source, entry.item, entry.quantity, entry.metadata) then return false end
    end
    return true
end

local function giveFulfillment(source, fulfillment)
    if not canReceiveFulfillment(source, fulfillment) then return false, _L('inventory_full') end
    local added = {}
    for _, entry in ipairs(fulfillment or {}) do
        local success = exports.ox_inventory:AddItem(source, entry.item, entry.quantity, entry.metadata)
        if not success then
            for _, rollback in ipairs(added) do
                exports.ox_inventory:RemoveItem(source, rollback.item, rollback.quantity, rollback.metadata, nil, false, false)
            end
            return false, _L('inventory_full')
        end
        added[#added + 1] = entry
    end
    return true
end

local function creditCompletedOrder(order, actorIdentifier, rating)
    local changed = MySQL.update.await([[
        UPDATE z_uwucafe_orders
        SET paid_to_business = 1, status = 'completed', payment_status = 'settled', rating = ?, updated_at = NOW()
        WHERE id = ? AND paid_to_business = 0 AND status = 'ready'
    ]], { rating or 0, order.id })
    if not changed or changed < 1 then return false end

    UwU.AddBusinessMoney(tonumber(order.total) or 0, ('Completed %s order #%s'):format(order.order_type, order.id), actorIdentifier, {
        orderType = order.order_type,
        customer = order.customer_name
    })
    local quality = tonumber(order.quality_score) or 60
    local reputation = Config.Business.reputationPerCompletedOrder
    if quality >= 92 then reputation = reputation + Config.Business.reputationPerPerfectOrder end
    local _, upgradeLevels = UwU.GetBusinessUpgrades()
    reputation = reputation + math.floor((upgradeLevels.service or 0) / 2)
    UwU.ChangeReputation(reputation)
    if rating and rating > 0 then UwU.AddRating(rating) end
    return true
end

function UwU.CompleteNpcOrder(orderId, rating, hostSource)
    local order = UwU.GetOrder(orderId)
    if not order or order.order_type ~= 'npc' or order.status ~= 'ready' then return false end
    rating = UwU.Clamp(math.floor(tonumber(rating) or 3), 1, 5)
    local success = creditCompletedOrder(order, ('npc-host:%s'):format(hostSource or 0), rating)
    if success then
        UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
        UwU.Log('orders', 'NPC order completed', ('Order #%s completed with %s stars.'):format(order.id, rating))
    end
    return success
end

local function notifyOrderCustomer(order, message, notificationType)
    local target = tonumber(order.customer_source)
    if target and GetPlayerName(target) then UwU.Notify(target, message, notificationType) end
end

lib.callback.register('z_uwucafe:server:getCustomerBootstrap', function(source, context)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    context = context or {}
    return {
        products = UwU.GetProductsForUi(),
        orders = UwU.GetCustomerOrders(xPlayer.identifier),
        player = { name = xPlayer.getName(), identifier = xPlayer.identifier },
        context = {
            orderType = context.orderType or 'terminal',
            tableNumber = tonumber(context.tableNumber),
            fees = {
                terminal = Config.Ordering.terminalServiceFee,
                table = Config.Ordering.tableServiceFee,
                delivery = Config.Ordering.deliveryFee
            }
        },
        business = {
            cleanliness = UwU.GetBusiness().cleanliness,
            reputation = UwU.GetBusiness().reputation,
            reputationLevel = UwU.GetReputationLevel()
        }
    }
end)

lib.callback.register('z_uwucafe:server:placeOrder', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not UwU.RateLimit(source, 'placeOrder', Config.Security.orderRateLimitMs) then
        return { success = false, message = _L('cooldown') }
    end
    data = data or {}
    local orderType = data.orderType
    if orderType ~= 'table' and orderType ~= 'delivery' then orderType = 'terminal' end

    local tableNumber
    if orderType == 'terminal' then
        if not UwU.IsNear(source, Config.Locations.customerTerminal, 8.0) then return { success = false, message = _L('too_far') } end
    elseif orderType == 'table' then
        tableNumber = tonumber(data.tableNumber)
        local tableData = UwU.FindTable(tableNumber)
        if not tableData or not UwU.IsNear(source, tableData.coords, 6.0) then return { success = false, message = _L('too_far') } end
    elseif orderType == 'delivery' and not Config.Features.customerDelivery then
        return { success = false, message = 'Customer delivery is disabled.' }
    end

    local items, subtotal = normaliseCart(data.cart)
    if not items then return { success = false, message = _L('invalid_order') } end
    local fee = orderType == 'delivery' and Config.Ordering.deliveryFee or orderType == 'table' and Config.Ordering.tableServiceFee or Config.Ordering.terminalServiceFee
    local tip = UwU.Clamp(math.floor(tonumber(data.tip) or 0), 0, math.floor(subtotal * Config.Ordering.tipMaximumPercent / 100))
    local total = subtotal + fee + tip
    if total > Config.Security.maxOrderValue then return { success = false, message = _L('invalid_order') } end

    local paymentMethod = data.paymentMethod == 'cash' and 'cash' or 'bank'
    if not takePayment(xPlayer, paymentMethod, total) then return { success = false, message = _L('payment_failed') } end

    local coords
    if orderType == 'delivery' then coords = GetEntityCoords(GetPlayerPed(source)) end
    local orderId = insertOrder({ identifier = xPlayer.identifier, name = xPlayer.getName(), source = source }, items, {
        orderType = orderType,
        paymentMethod = paymentMethod,
        paymentStatus = 'paid',
        subtotal = subtotal,
        fee = fee,
        tip = tip,
        total = total,
        notes = data.notes,
        tableNumber = tableNumber,
        deliveryCoords = coords
    })

    if not orderId then
        if paymentMethod == 'cash' then xPlayer.addMoney(total, 'UwU Cafe refund') else xPlayer.addAccountMoney('bank', total, 'UwU Cafe refund') end
        return { success = false, message = 'The order could not be saved. Your payment was refunded.' }
    end
    UwU.Log('orders', 'Customer order', ('%s created %s order #%s for $%s'):format(xPlayer.getName(), orderType, orderId, total))
    return { success = true, message = _L('order_created', orderId), orderId = orderId }
end)

lib.callback.register('z_uwucafe:server:createRegisterOrder', function(source, data)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'createRegisterOrder')
    if not allowed then return { success = false, message = deniedMessage } end
    if not UwU.RateLimit(source, 'registerOrder', Config.Security.orderRateLimitMs) then return { success = false, message = _L('cooldown') } end
    if not UwU.IsNear(source, Config.Locations.register, 7.0) then return { success = false, message = _L('too_far') } end

    data = data or {}
    local employee = ESX.GetPlayerFromId(source)
    local targetId = tonumber(data.targetId)
    local customer = targetId and ESX.GetPlayerFromId(targetId)
    if not customer then return { success = false, message = 'Customer is not online.' } end
    if not UwU.ArePlayersNear(source, targetId, 5.0) then return { success = false, message = _L('too_far') } end

    local items, subtotal = normaliseCart(data.cart)
    if not items then return { success = false, message = _L('invalid_order') } end
    local tip = UwU.Clamp(math.floor(tonumber(data.tip) or 0), 0, math.floor(subtotal * Config.Ordering.tipMaximumPercent / 100))
    local total = subtotal + tip
    local summary = { employee = employee.getName(), items = items, subtotal = subtotal, tip = tip, total = total }
    local accepted = lib.callback.await('z_uwucafe:client:confirmBill', targetId, summary)
    if not accepted then return { success = false, message = _L('customer_declined') } end
    if not UwU.ArePlayersNear(source, targetId, 5.0) then return { success = false, message = _L('too_far') } end

    local paymentMethod = data.paymentMethod == 'cash' and 'cash' or 'bank'
    if not takePayment(customer, paymentMethod, total) then return { success = false, message = _L('payment_failed') } end
    local orderId = insertOrder({ identifier = customer.identifier, name = customer.getName(), source = targetId }, items, {
        orderType = 'register', employeeIdentifier = employee.identifier, paymentMethod = paymentMethod,
        paymentStatus = 'paid', subtotal = subtotal, fee = 0, tip = tip, total = total, notes = data.notes
    })
    if not orderId then
        if paymentMethod == 'cash' then customer.addMoney(total, 'UwU Cafe refund') else customer.addAccountMoney('bank', total, 'UwU Cafe refund') end
        return { success = false, message = 'The order could not be saved. Payment was refunded.' }
    end
    UwU.TouchDuty(source)
    UwU.Notify(targetId, _L('order_created', orderId), 'success')
    return { success = true, message = _L('order_created', orderId), orderId = orderId }
end)

lib.callback.register('z_uwucafe:server:updateOrder', function(source, orderId, newStatus)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'updateOrder')
    if not allowed then return { success = false, message = deniedMessage } end
    if not validStatuses[newStatus] then return { success = false, message = 'Invalid status.' } end
    if not UwU.RateLimit(source, ('order:%s'):format(orderId), Config.Security.actionRateLimitMs) then return { success = false, message = _L('cooldown') } end

    local order = UwU.GetOrder(orderId)
    if not order then return { success = false, message = 'Order not found.' } end
    if not statusTransitions[order.status] or not statusTransitions[order.status][newStatus] then
        return { success = false, message = ('Cannot change %s to %s.'):format(order.status, newStatus) }
    end
    local xPlayer = ESX.GetPlayerFromId(source)

    if newStatus == 'cancelled' then
        if order.status == 'ready' then
            if not UwU.RequireTabletAccess(source, 'actions', 'cancelReadyOrder', true) then
                return { success = false, message = _L('no_permission') }
            end
            local fulfillment = order.fulfillment_json and json.decode(order.fulfillment_json) or {}
            UwU.EnsureStashLoaded(Config.Stock.stashId)
            for _, entry in ipairs(fulfillment) do
                exports.ox_inventory:AddItem(Config.Stock.stashId, entry.item, entry.quantity, entry.metadata)
            end
        end
        MySQL.update.await("UPDATE z_uwucafe_orders SET status = 'cancelled', updated_at = NOW() WHERE id = ?", { order.id })
        if Config.Ordering.refundOnCancellation then queueRefund(order, ('Cancelled order #%s'):format(order.id)) end
        if order.order_type == 'npc' then UwU.ChangeReputation(-Config.Business.reputationLossCancelledNpc) end
    elseif newStatus == 'ready' then
        local fulfillment, quality = removePreparedProducts(source, order.items)
        if not fulfillment then return { success = false, message = quality } end
        local deliveryStatus = order.order_type == 'delivery' and 'ready_for_driver' or order.delivery_status
        local changed = MySQL.update.await([[
            UPDATE z_uwucafe_orders
            SET status = 'ready', employee_identifier = COALESCE(employee_identifier, ?),
                fulfillment_json = ?, quality_score = ?, delivery_status = ?, updated_at = NOW()
            WHERE id = ? AND status = 'preparing'
        ]], { xPlayer.identifier, json.encode(fulfillment), quality, deliveryStatus, order.id })
        if not changed or changed < 1 then
            for _, entry in ipairs(fulfillment) do exports.ox_inventory:AddItem(source, entry.item, entry.quantity, entry.metadata) end
            return { success = false, message = 'Order state changed. Products were returned.' }
        end
        notifyOrderCustomer(order, _L('order_ready', order.id), 'success')
        if order.order_type == 'npc' then TriggerEvent('z_uwucafe:server:npcOrderReady', order.id) end
    else
        MySQL.update.await([[
            UPDATE z_uwucafe_orders
            SET status = ?, employee_identifier = COALESCE(employee_identifier, ?), updated_at = NOW()
            WHERE id = ?
        ]], { newStatus, xPlayer.identifier, order.id })
        notifyOrderCustomer(order, _L('order_updated', order.id), 'inform')
    end

    MySQL.insert.await('INSERT INTO z_uwucafe_order_events (order_id, event_type, actor_identifier, details) VALUES (?, ?, ?, ?)', {
        order.id, newStatus, xPlayer.identifier, '{}'
    })
    UwU.TouchDuty(source)
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
    return { success = true, message = _L('order_updated', order.id) }
end)

lib.callback.register('z_uwucafe:server:cancelMyOrder', function(source, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local order = UwU.GetOrder(orderId)
    if not xPlayer or not order or order.customer_identifier ~= xPlayer.identifier then return { success = false, message = 'Order not found.' } end
    if not Config.Ordering.allowCustomerCancellationBeforeAccepted or order.status ~= 'pending' then return { success = false, message = 'This order can no longer be cancelled.' } end
    MySQL.update.await("UPDATE z_uwucafe_orders SET status = 'cancelled', updated_at = NOW() WHERE id = ? AND status = 'pending'", { order.id })
    queueRefund(order, ('Cancelled order #%s'):format(order.id))
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
    return { success = true, message = 'Order cancelled and refunded.' }
end)

local function collectOrderForPlayer(source, order, serviceType, employeeIdentifier)
    local fulfillment = order.fulfillment_json and json.decode(order.fulfillment_json) or {}
    local success, message = giveFulfillment(source, fulfillment)
    if not success then return false, message end

    local rating = 5
    local elapsedMinutes = math.floor((os.time() - (tonumber(order.created_epoch) or os.time())) / 60)
    if tonumber(order.quality_score) < 45 then rating = rating - 2 elseif tonumber(order.quality_score) < 75 then rating = rating - 1 end
    if serviceType == 'delivery' then rating = math.max(1, rating - (elapsedMinutes > Config.Ordering.deliveryTimeoutMinutes and 1 or 0)) end
    rating = UwU.Clamp(rating, 1, 5)

    if not creditCompletedOrder(order, employeeIdentifier or order.customer_identifier, rating) then
        for _, entry in ipairs(fulfillment) do exports.ox_inventory:RemoveItem(source, entry.item, entry.quantity, entry.metadata, nil, false, false) end
        return false, 'Order state changed. Try again.'
    end
    return true, rating
end

lib.callback.register('z_uwucafe:server:collectOrder', function(source, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local order = UwU.GetOrder(orderId)
    if not xPlayer or not order or order.customer_identifier ~= xPlayer.identifier or order.status ~= 'ready' then return { success = false, message = _L('order_not_ready') } end
    if order.order_type == 'delivery' or order.order_type == 'npc' then return { success = false, message = 'This order cannot be collected here.' } end
    if not UwU.IsNear(source, Config.Ordering.pickupCounter, Config.Ordering.customerCollectionDistance) then return { success = false, message = _L('too_far') } end
    local success, result = collectOrderForPlayer(source, order, 'pickup')
    if not success then return { success = false, message = result } end
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
    return { success = true, message = _L('order_collected', order.id) }
end)

lib.callback.register('z_uwucafe:server:serveTableOrder', function(source, tableNumber, orderId)
    if not UwU.RequireEmployee(source, 0, true) then return { success = false, message = _L('not_on_duty') } end
    local tableData = UwU.FindTable(tableNumber)
    local order = UwU.GetOrder(orderId)
    if not tableData or not order or order.order_type ~= 'table' or tonumber(order.table_number) ~= tonumber(tableNumber) or order.status ~= 'ready' then
        return { success = false, message = _L('order_not_ready') }
    end
    if not UwU.IsNear(source, tableData.coords, Config.Ordering.tableServiceDistance) then return { success = false, message = _L('too_far') } end
    local customerSource = tonumber(order.customer_source)
    local customer = customerSource and ESX.GetPlayerFromId(customerSource)
    if not customer or customer.identifier ~= order.customer_identifier then
        for _, player in pairs(ESX.GetExtendedPlayers() or {}) do
            if player.identifier == order.customer_identifier then
                customer = player
                customerSource = player.source
                break
            end
        end
    end
    if not customer or not UwU.ArePlayersNear(source, customerSource, 8.0) then
        return { success = false, message = 'The customer is not at the table.' }
    end
    local employee = ESX.GetPlayerFromId(source)
    local success, result = collectOrderForPlayer(customerSource, order, 'table', employee.identifier)
    if not success then return { success = false, message = result } end
    UwU.AddProgress(employee.identifier, Config.Progression.generalXp.tableService, 'table_orders', 'service', Config.Progression.skillXp.tableService)
    UwU.TouchDuty(source)
    UwU.Notify(customerSource, _L('order_collected', order.id), 'success')
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
    return { success = true, message = 'Table order served.' }
end)

lib.callback.register('z_uwucafe:server:getReadyTableOrders', function(source, tableNumber)
    if not UwU.RequireEmployee(source, 0, true) then return {} end
    local tableData = UwU.FindTable(tableNumber)
    if not tableData or not UwU.IsNear(source, tableData.coords, 8.0) then return {} end
    local rows = MySQL.query.await([[
        SELECT * FROM z_uwucafe_orders WHERE order_type = 'table' AND table_number = ? AND status = 'ready' ORDER BY id ASC
    ]], { tableNumber }) or {}
    return hydrateOrders(rows)
end)

lib.callback.register('z_uwucafe:server:callStaff', function(source, tableNumber)
    local tableData = UwU.FindTable(tableNumber)
    if not tableData or not UwU.IsNear(source, tableData.coords, 6.0) then return { success = false, message = _L('too_far') } end
    if not UwU.RateLimit(source, ('staffCall:%s'):format(tableNumber), 60000) then return { success = false, message = _L('cooldown') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.insert.await('INSERT INTO z_uwucafe_staff_calls (table_number, customer_identifier, customer_name) VALUES (?, ?, ?)', {
        tableNumber, xPlayer and xPlayer.identifier or '', xPlayer and xPlayer.getName() or 'Customer'
    })
    UwU.BroadcastEmployees('z_uwucafe:client:staffCall', tableNumber)
    return { success = true, message = 'A staff member has been called.' }
end)

function UwU.CreateNpcOrder(customerName, items, total, npcId)
    return insertOrder({ identifier = ('npc:%s'):format(npcId), name = customerName, source = nil }, items, {
        orderType = 'npc', paymentMethod = 'npc', paymentStatus = 'unpaid', subtotal = total,
        fee = 0, tip = 0, total = total, notes = 'NPC customer order'
    })
end

function UwU.CompleteDeliveryOrder(employeeSource, orderId)
    if not UwU.RequireEmployee(employeeSource, Config.CustomerDelivery.minimumGrade, true) then return false, _L('not_on_duty') end
    local employee = ESX.GetPlayerFromId(employeeSource)
    local order = UwU.GetOrder(orderId)
    if not order or order.order_type ~= 'delivery' or order.status ~= 'ready' or order.delivery_status ~= 'assigned' then
        return false, 'This delivery is no longer active.'
    end
    if order.delivery_identifier ~= employee.identifier then return false, 'This delivery is assigned to another employee.' end
    local destination = vec3(tonumber(order.delivery_x) or 0.0, tonumber(order.delivery_y) or 0.0, tonumber(order.delivery_z) or 0.0)
    if not UwU.IsNear(employeeSource, destination, Config.Ordering.deliveryCompletionDistance) then return false, _L('too_far') end

    local customer
    for _, player in pairs(ESX.GetExtendedPlayers() or {}) do
        if player.identifier == order.customer_identifier then customer = player break end
    end
    if not customer then return false, 'The customer is offline.' end
    if #(GetEntityCoords(GetPlayerPed(customer.source)) - destination) > Config.Ordering.deliveryCompletionDistance then
        return false, 'The customer is not at the delivery location.'
    end

    local fulfillment = order.fulfillment_json and json.decode(order.fulfillment_json) or {}
    local success, message = giveFulfillment(customer.source, fulfillment)
    if not success then return false, message end
    local quality = tonumber(order.quality_score) or 60
    local rating = quality >= 92 and 5 or quality >= 75 and 4 or quality >= 45 and 3 or 2
    if not creditCompletedOrder(order, employee.identifier, rating) then
        for _, entry in ipairs(fulfillment) do exports.ox_inventory:RemoveItem(customer.source, entry.item, entry.quantity, entry.metadata, nil, false, false) end
        return false, 'Order state changed. Try again.'
    end
    MySQL.update.await("UPDATE z_uwucafe_orders SET delivery_status = 'delivered' WHERE id = ?", { order.id })

    local _, upgrades = UwU.GetBusinessUpgrades()
    local bonus = Config.Ordering.deliveryEmployeeBonus + ((upgrades.logistics or 0) * 5)
    if UwU.RemoveBusinessMoney(bonus, ('Delivery bonus #%s'):format(order.id), employee.identifier) then
        employee.addAccountMoney('bank', bonus, 'UwU Cafe delivery bonus')
    end
    UwU.AddProgress(employee.identifier, Config.Progression.generalXp.customerDelivery, 'customer_deliveries', 'delivery', Config.Progression.skillXp.customerDelivery)
    UwU.TouchDuty(employeeSource)
    UwU.Notify(customer.source, _L('order_collected', order.id), 'success')
    UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', order.id)
    return true, _L('delivery_complete')
end
