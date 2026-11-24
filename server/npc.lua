local customerNames = { 'Mia', 'Noah', 'Ava', 'Liam', 'Sofia', 'Ethan', 'Luna', 'Leo', 'Chloe', 'Kai', 'Emma', 'Oliver' }

local function chooseHost(exclude)
    local candidates = {}
    for _, employee in ipairs(UwU.GetOnlineEmployees(true)) do
        if employee.source ~= exclude then candidates[#candidates + 1] = employee.source end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(#candidates)]
end

local function availableNpcProducts()
    local products = {}
    local reputation = UwU.GetBusiness().reputation
    for itemName, product in pairs(Config.Products) do
        if reputation >= (product.minimumReputation or 0) then products[#products + 1] = itemName end
    end
    return products
end

local function buildNpcCart()
    local available = availableNpcProducts()
    if #available == 0 then return nil, 0 end
    local lineCount = math.random(Config.NPC.orderItemCount.min, Config.NPC.orderItemCount.max)
    local cart = {}
    for _ = 1, lineCount do
        local item = available[math.random(#available)]
        cart[item] = math.min((cart[item] or 0) + 1, 3)
    end
    local items, total = {}, 0
    for itemName, quantity in pairs(cart) do
        local product = Config.Products[itemName]
        local pricing = UwU.GetProductPricing(itemName)
        if product and pricing then
            items[#items + 1] = { item = itemName, label = product.label, quantity = quantity, unitPrice = pricing.price, lineTotal = pricing.price * quantity }
            total = total + pricing.price * quantity
        end
    end
    return items, total
end

local function spawnNpcCustomer()
    if not Config.Features.npcCustomers or not Config.NPC.enabled then return end
    if UwU.GetOnDutyCount() < Config.NPC.minimumOnDuty then return end
    if UwU.TableCount(UwU.Server.NPCs) >= Config.NPC.maximumActive then return end
    local business = UwU.GetBusiness()
    if business.cleanliness <= Config.Business.inspectionThreshold then return end

    local host = chooseHost()
    if not host then return end
    local items, total = buildNpcCart()
    if not items or #items == 0 then return end
    local npcId = UwU.Token('npc')
    local name = customerNames[math.random(#customerNames)]
    local model = Config.NPC.models[math.random(#Config.NPC.models)]
    local orderId = UwU.CreateNpcOrder(name, items, total, npcId)
    if not orderId then return end

    UwU.Server.NPCs[npcId] = {
        id = npcId,
        orderId = orderId,
        host = host,
        name = name,
        model = model,
        createdAt = os.time(),
        expiresAt = os.time() + Config.NPC.maximumWaitMinutes * 60,
        stage = 'waiting'
    }
    UwU.Server.NPCHosts[host] = UwU.Server.NPCHosts[host] or {}
    UwU.Server.NPCHosts[host][npcId] = true
    TriggerClientEvent('z_uwucafe:client:spawnNpcCustomer', host, {
        npcId = npcId, orderId = orderId, name = name, model = model, items = items,
        spawn = Config.NPC.spawn, queue = Config.NPC.queue, exit = Config.NPC.exit
    })
end

local function removeNpc(npcId, reason)
    local npc = UwU.Server.NPCs[npcId]
    if not npc then return end
    if npc.host and UwU.Server.NPCHosts[npc.host] then UwU.Server.NPCHosts[npc.host][npcId] = nil end
    if npc.host then TriggerClientEvent('z_uwucafe:client:removeNpcCustomer', npc.host, npcId, reason) end
    UwU.Server.NPCs[npcId] = nil
end

function UwU.ReassignNpcHosts(disconnectedSource)
    local hosted = UwU.Server.NPCHosts[disconnectedSource]
    if not hosted then return end
    for npcId in pairs(hosted) do
        local npc = UwU.Server.NPCs[npcId]
        if npc then
            local newHost = chooseHost(disconnectedSource)
            if newHost then
                npc.host = newHost
                UwU.Server.NPCHosts[newHost] = UwU.Server.NPCHosts[newHost] or {}
                UwU.Server.NPCHosts[newHost][npcId] = true
                TriggerClientEvent('z_uwucafe:client:spawnNpcCustomer', newHost, {
                    npcId = npc.id, orderId = npc.orderId, name = npc.name, model = npc.model, items = (UwU.GetOrder(npc.orderId) or { items = {} }).items,
                    spawn = Config.NPC.spawn, queue = Config.NPC.queue, exit = Config.NPC.exit,
                    ready = npc.stage == 'ready'
                })
            else
                local order = UwU.GetOrder(npc.orderId)
                if order and order.status ~= 'completed' and order.status ~= 'cancelled' then
                    MySQL.update.await("UPDATE z_uwucafe_orders SET status = 'cancelled' WHERE id = ?", { order.id })
                end
                UwU.Server.NPCs[npcId] = nil
            end
        end
    end
    UwU.Server.NPCHosts[disconnectedSource] = nil
end

AddEventHandler('z_uwucafe:server:npcOrderReady', function(orderId)
    for npcId, npc in pairs(UwU.Server.NPCs) do
        if npc.orderId == tonumber(orderId) then
            npc.stage = 'ready'
            TriggerClientEvent('z_uwucafe:client:npcOrderReady', npc.host, npcId, npc.orderId)
            return
        end
    end
end)

lib.callback.register('z_uwucafe:server:completeNpcCustomer', function(source, npcId)
    local npc = UwU.Server.NPCs[npcId]
    if not npc or npc.host ~= source or npc.stage ~= 'ready' then return { success = false } end
    local order = UwU.GetOrder(npc.orderId)
    if not order or order.status ~= 'ready' then return { success = false } end
    if not UwU.IsNear(source, vec3(Config.NPC.queue.x, Config.NPC.queue.y, Config.NPC.queue.z), 35.0) then return { success = false } end

    local business = UwU.GetBusiness()
    local waitMinutes = math.floor((os.time() - npc.createdAt) / 60)
    local quality = tonumber(order.quality_score) or 60
    local rating = 5
    if waitMinutes > 8 then rating = rating - 2 elseif waitMinutes > 5 then rating = rating - 1 end
    if quality < 45 then rating = rating - 2 elseif quality < 75 then rating = rating - 1 end
    if business.cleanliness < Config.Business.lowCleanlinessThreshold then rating = rating - 1 end
    rating = UwU.Clamp(rating, 1, 5)

    local _, upgrades = UwU.GetBusinessUpgrades()
    local tipChance = Config.NPC.baseTipChance + (upgrades.marketing or 0) * 10 + math.max(0, rating - 3) * 8
    local tip = math.random(1, 100) <= tipChance and math.random(5, Config.NPC.maxTip + (upgrades.marketing or 0) * 5) or 0
    if tip > 0 then MySQL.update.await('UPDATE z_uwucafe_orders SET tip = tip + ?, total = total + ? WHERE id = ?', { tip, tip, order.id }) end
    local completed = UwU.CompleteNpcOrder(order.id, rating, source)
    if not completed then return { success = false } end
    removeNpc(npcId, 'completed')
    return { success = true, rating = rating, tip = tip }
end)

CreateThread(function()
    while true do
        local _, upgradeLevels = UwU.GetBusinessUpgrades()
        local reputation = UwU.GetReputationLevel()
        local base = math.random(Config.NPC.spawnInterval.min, Config.NPC.spawnInterval.max)
        local multiplier = (reputation.npcMultiplier or 1.0) * (1 + (upgradeLevels.marketing or 0) * 0.15)
        Wait(math.floor(base / multiplier) * 1000)
        spawnNpcCustomer()
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for npcId, npc in pairs(UwU.Server.NPCs) do
            if now > npc.expiresAt then
                local order = UwU.GetOrder(npc.orderId)
                if order and order.status ~= 'completed' and order.status ~= 'cancelled' then
                    MySQL.update.await("UPDATE z_uwucafe_orders SET status = 'cancelled' WHERE id = ?", { order.id })
                    UwU.ChangeReputation(-Config.Business.reputationLossCancelledNpc)
                end
                removeNpc(npcId, 'timeout')
                UwU.BroadcastEmployees('z_uwucafe:client:ordersChanged', npc.orderId)
            end
        end
    end
end)
