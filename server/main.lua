local ESX = UwU.ESX

local function calculatePayroll(xPlayer, duty)
    local minutes = math.floor((os.time() - duty.startedAt) / 60)
    minutes = math.min(minutes, Config.Duty.maximumPaidHoursPerSession * 60)
    if not Config.Features.payroll or not Config.Duty.payOnClockOut or minutes < Config.Duty.minimumPaidMinutes then return minutes, 0, 'not_eligible' end
    local hourly = Config.Duty.hourlyWages[tonumber(xPlayer.job.grade) or 0] or 0
    local amount = math.floor(hourly * minutes / 60)
    if amount <= 0 then return minutes, 0, 'not_eligible' end
    local paid = UwU.RemoveBusinessMoney(amount, ('Payroll: %s'):format(xPlayer.getName()), xPlayer.identifier, { minutes = minutes, grade = xPlayer.job.grade })
    if paid then
        xPlayer.addAccountMoney('bank', amount, 'UwU Cafe payroll')
        return minutes, amount, 'paid'
    end
    return minutes, amount, 'unpaid'
end

local function setDuty(source, state, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    if state and (not xPlayer.job or xPlayer.job.name ~= Config.JobName) then return false end

    if state then
        if UwU.Server.Duty[source] then return true end
        local ped = GetPlayerPed(source)
        UwU.Server.Duty[source] = {
            startedAt = os.time(),
            identifier = xPlayer.identifier,
            employeeName = xPlayer.getName(),
            grade = tonumber(xPlayer.job.grade) or 0,
            lastActivity = os.time(),
            lastCoords = ped and ped > 0 and GetEntityCoords(ped) or vec3(0, 0, 0)
        }
        UwU.EnsureEmployee(xPlayer.identifier)
    else
        local duty = UwU.Server.Duty[source]
        if not duty then return true end
        local minutes, amount, payrollStatus = calculatePayroll(xPlayer, duty)
        UwU.AddDutyMinutes(xPlayer.identifier, minutes)
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_duty_sessions (identifier, started_at, ended_at, minutes, payroll_amount, payroll_status, end_reason)
            VALUES (?, FROM_UNIXTIME(?), NOW(), ?, ?, ?, ?)
        ]], { xPlayer.identifier, duty.startedAt, minutes, amount, payrollStatus, UwU.SanitizeText(reason or 'clock_out', 80) })
        UwU.Server.Duty[source] = nil
        if payrollStatus == 'paid' then UwU.Notify(source, _L('payroll_paid', amount, minutes), 'success')
        elseif payrollStatus == 'unpaid' then UwU.Notify(source, _L('payroll_unpaid', amount), 'error') end
    end

    local playerState = Player(source)
    if playerState then playerState.state:set('uwuDuty', state, true) end
    TriggerClientEvent('z_uwucafe:client:setDuty', source, state, reason)
    UwU.Log('duty', state and 'Clocked in' or 'Clocked out', ('%s [%s] - %s'):format(xPlayer.getName(), xPlayer.identifier, reason or 'manual'))
    return true
end

AddEventHandler('z_uwucafe:server:forceDutyOff', function(targetSource, reason)
    setDuty(tonumber(targetSource), false, reason or 'forced')
end)

lib.callback.register('z_uwucafe:server:getDuty', function(source)
    return UwU.Server.Duty[source] ~= nil
end)

lib.callback.register('z_uwucafe:server:toggleDuty', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then return nil end
    if not UwU.IsNear(source, Config.Locations.duty, 6.0) then return nil end
    local newState = UwU.Server.Duty[source] == nil
    if not setDuty(source, newState, 'manual') then return nil end
    return { onDuty = newState }
end)

lib.callback.register('z_uwucafe:server:getMyStats', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    return UwU.GetEmployeeStats(xPlayer.identifier)
end)

lib.callback.register('z_uwucafe:server:beginCraft', function(source, recipeId, stationId)
    if not UwU.RequireEmployee(source, 0, true) then return { success = false, message = _L('not_on_duty') } end
    if not UwU.RateLimit(source, 'beginCraft', Config.Security.craftRateLimitMs) then return { success = false, message = _L('cooldown') } end
    local recipe, station = Config.Recipes[recipeId], UwU.FindStation(stationId)
    if not recipe or not station or station.station ~= recipe.station then
        UwU.Log('security', 'Invalid craft request', ('Player %s requested %s at %s'):format(source, tostring(recipeId), tostring(stationId)))
        return { success = false, message = 'Invalid recipe or station.' }
    end
    if not UwU.IsNear(source, station.coords, Config.ServerValidationDistance) then return { success = false, message = _L('too_far') } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local stats = UwU.GetEmployeeStats(xPlayer.identifier)
    local skill = stats.skills[recipe.skill or 'cooking'] or { level = 1 }
    if recipe.minimumLevel and skill.level < recipe.minimumLevel then return { success = false, message = ('You need %s level %s.'):format(recipe.skill or 'cooking', recipe.minimumLevel) } end
    if UwU.GetBusiness().reputation < (recipe.minimumReputation or 0) then return { success = false, message = 'The cafe reputation is too low for this recipe.' } end
    local equipment = UwU.GetCraftModifiers(stationId)
    if not equipment or not equipment.usable then return { success = false, message = _L('equipment_broken') } end
    for item, amount in pairs(recipe.ingredients) do
        if UwU.GetInventoryItemCount(source, item) < amount then return { success = false, message = _L('missing_ingredients') } end
    end
    if not exports.ox_inventory:CanCarryItem(source, recipe.result.item, recipe.result.amount) then return { success = false, message = _L('inventory_full') } end

    local duration = math.max(1500, math.floor((recipe.duration or 5000) * equipment.durationMultiplier))
    local token = UwU.Token('craft')
    UwU.Server.CraftTokens[source] = {
        token = token, recipeId = recipeId, stationId = stationId,
        startedAt = GetGameTimer(), duration = duration,
        expiresAt = os.time() + Config.Security.craftTokenLifetimeSeconds
    }
    UwU.TouchDuty(source)
    return {
        success = true, token = token, duration = duration, difficulty = recipe.difficulty or {'easy'},
        label = recipe.label, equipmentCondition = equipment.condition, equipmentLevel = equipment.level
    }
end)

lib.callback.register('z_uwucafe:server:completeCraft', function(source, token)
    local craft = UwU.Server.CraftTokens[source]
    UwU.Server.CraftTokens[source] = nil
    if not craft or craft.token ~= token or os.time() > craft.expiresAt then return { success = false, message = 'Crafting session expired.' } end
    if not UwU.RequireEmployee(source, 0, true) then return { success = false, message = _L('not_on_duty') } end
    local elapsed = GetGameTimer() - craft.startedAt
    if elapsed < craft.duration * Config.Security.minimumCraftElapsedPercent then
        UwU.Log('security', 'Craft completed too quickly', ('Player %s completed token %s in %sms.'):format(source, token, elapsed))
        return { success = false, message = 'Crafting completed too quickly.' }
    end
    local recipe, station = Config.Recipes[craft.recipeId], UwU.FindStation(craft.stationId)
    if not recipe or not station or not UwU.IsNear(source, station.coords, Config.ServerValidationDistance) then return { success = false, message = _L('too_far') } end
    for item, amount in pairs(recipe.ingredients) do
        if UwU.GetInventoryItemCount(source, item) < amount then return { success = false, message = _L('missing_ingredients') } end
    end
    if not exports.ox_inventory:CanCarryItem(source, recipe.result.item, recipe.result.amount) then return { success = false, message = _L('inventory_full') } end

    local removed = {}
    for item, amount in pairs(recipe.ingredients) do
        local success = exports.ox_inventory:RemoveItem(source, item, amount)
        if not success then
            for _, entry in ipairs(removed) do exports.ox_inventory:AddItem(source, entry.item, entry.amount) end
            return { success = false, message = _L('missing_ingredients') }
        end
        removed[#removed + 1] = { item = item, amount = amount }
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    local stats = UwU.GetEmployeeStats(xPlayer.identifier)
    local skillLevel = (stats.skills[recipe.skill or 'cooking'] or { level = 1 }).level
    local equipment = UwU.GetCraftModifiers(craft.stationId)
    local cleanliness = UwU.GetBusiness().cleanliness
    local score = math.random(38, 70) + math.floor(skillLevel * 1.6) + (equipment and equipment.qualityBonus or 0) + math.floor((cleanliness - 50) / 8)
    score = UwU.Clamp(score, 20, 100)
    local metadata = {
        quality = UwU.QualityLabel(score),
        qualityScore = score,
        preparedBy = xPlayer.getName(),
        preparedByIdentifier = xPlayer.identifier,
        preparedAt = os.time(),
        expiresAt = os.time() + (recipe.shelfLifeMinutes or 180) * 60,
        recipe = craft.recipeId
    }
    local success = exports.ox_inventory:AddItem(source, recipe.result.item, recipe.result.amount, metadata)
    if not success then
        for _, entry in ipairs(removed) do exports.ox_inventory:AddItem(source, entry.item, entry.amount) end
        return { success = false, message = _L('inventory_full') }
    end

    UwU.DegradeEquipment(craft.stationId)
    UwU.AddProgress(xPlayer.identifier, Config.Progression.generalXp.craft, 'crafts', recipe.skill or 'cooking', Config.Progression.skillXp.craft)
    UwU.TouchDuty(source)
    return { success = true, message = _L('crafted', recipe.result.amount, recipe.label), quality = metadata.quality, qualityScore = score }
end)

lib.callback.register('z_uwucafe:server:cleanSpot', function(source, spotId)
    if not UwU.RequireEmployee(source, 0, true) then return false, _L('not_on_duty') end
    if not UwU.RateLimit(source, ('clean:%s'):format(spotId), 30000) then return false, _L('cooldown') end
    local spot = UwU.FindCleaningSpot(spotId)
    if not spot or not UwU.IsNear(source, spot.coords, 4.0) then return false, _L('too_far') end
    local xPlayer = ESX.GetPlayerFromId(source)
    UwU.ChangeCleanliness(Config.Business.cleaningReward)
    UwU.AddProgress(xPlayer.identifier, Config.Progression.generalXp.cleaning, 'cleaning_actions', 'service', Config.Progression.skillXp.cleaning)
    UwU.TouchDuty(source)
    return true, _L('cleaned')
end)

local function buildTabletDashboard(permissions)
    local pages = permissions.pages or {}
    if not pages.stock and not pages.business and not pages.promotions then return {} end

    local full = UwU.GetDashboard()
    local dashboard = {}

    if pages.stock then dashboard.lowStock = full.lowStock end
    if pages.promotions then dashboard.promotions = full.promotions end

    if pages.business then
        for _, key in ipairs({
            'balance', 'cleanliness', 'reputation', 'reputationLevel', 'averageRating',
            'todayIncome', 'todayExpenses', 'todayOrders', 'todayRevenue', 'todayRating',
            'recentTransactions', 'bestSellers', 'upgrades'
        }) do
            dashboard[key] = full[key]
        end
    end

    return dashboard
end

lib.callback.register('z_uwucafe:server:getEmployeeBootstrap', function(source)
    if not UwU.RequireEmployee(source, 0, true) then return nil end
    local xPlayer = ESX.GetPlayerFromId(source)
    local grade = tonumber(xPlayer.job.grade) or 0
    local permissions = UwU.GetTabletPermissions(grade)
    local pages = permissions.pages
    local tabletOrders = {}

    if pages.orders then
        tabletOrders = UwU.GetActiveOrders()
    elseif pages.deliveries then
        for _, order in ipairs(UwU.GetActiveOrders()) do
            if order.order_type == 'delivery' and order.status == 'ready' then
                tabletOrders[#tabletOrders + 1] = order
            end
        end
    end

    return {
        products = (pages.register or pages.promotions) and UwU.GetProductsForUi() or {},
        orders = tabletOrders,
        dashboard = buildTabletDashboard(permissions),
        profile = pages.profile and UwU.GetEmployeeStats(xPlayer.identifier) or {},
        employees = pages.staff and UwU.GetEmployeesForManagement() or {},
        supplyPacks = pages.supplies and Config.SupplyPacks or {},
        catering = pages.catering and UwU.GetCateringContracts(xPlayer.identifier) or {},
        equipment = pages.equipment and UwU.GetAllEquipment() or {},
        activeLogistics = UwU.Server.ActiveLogistics[source],
        permissions = permissions,
        defaultTab = Config.TabletAccess.defaultPage,
        player = { source = source, name = xPlayer.getName(), grade = grade, gradeLabel = xPlayer.job.grade_label }
    }
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(playerId)
    if xPlayer then CreateThread(function() Wait(1500) UwU.ApplyPendingRefunds(xPlayer) end) end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local duty = UwU.Server.Duty[source]
    if duty then
        local minutes = math.floor((os.time() - duty.startedAt) / 60)
        local identifier = (xPlayer and xPlayer.identifier) or duty.identifier
        UwU.AddDutyMinutes(identifier, minutes)
        MySQL.insert.await([[
            INSERT INTO z_uwucafe_duty_sessions (identifier, started_at, ended_at, minutes, payroll_amount, payroll_status, end_reason)
            VALUES (?, FROM_UNIXTIME(?), NOW(), ?, 0, 'disconnected', 'disconnect')
        ]], { identifier, duty.startedAt, minutes })
    end
    UwU.CancelActiveLogistics(source)
    UwU.ReassignNpcHosts(source)
    UwU.Server.Duty[source] = nil
    UwU.Server.RateLimits[source] = nil
    UwU.Server.CraftTokens[source] = nil
end)

CreateThread(function()
    while true do
        Wait(Config.Duty.checkIntervalSeconds * 1000)
        local now = os.time()
        for source, duty in pairs(UwU.Server.Duty) do
            local ped = GetPlayerPed(source)
            if not ped or ped <= 0 or not UwU.RequireEmployee(source, 0, false) then
                setDuty(source, false, 'invalid_employee')
            else
                local coords = GetEntityCoords(ped)
                if #(coords - duty.lastCoords) >= Config.Duty.movementThreshold then
                    duty.lastActivity = now
                    duty.lastCoords = coords
                elseif now - duty.lastActivity >= Config.Duty.afkMinutes * 60 then
                    UwU.Notify(source, 'You were clocked out for inactivity.', 'error')
                    setDuty(source, false, 'afk')
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        if Config.Features.employeeBlips and Config.Blips.employees.enabled then
            local sources = {}
            for source in pairs(UwU.Server.Duty) do if GetPlayerName(source) then sources[#sources + 1] = source end end
            for _, employee in ipairs(UwU.GetOnlineEmployees(true)) do
                TriggerClientEvent('z_uwucafe:client:updateEmployeeBlips', employee.source, sources)
            end
        end
    end
end)


CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        local expired = {}
        for source, job in pairs(UwU.Server.ActiveLogistics) do
            if now > job.expiresAt then expired[#expired + 1] = source end
        end
        for _, source in ipairs(expired) do
            UwU.CancelActiveLogistics(source)
            if GetPlayerName(source) then UwU.Notify(source, 'Your logistics job expired.', 'error') end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10 * 60 * 1000)
        local business = UwU.GetBusiness()
        if business.cleanliness <= Config.Business.inspectionThreshold
            and os.time() - UwU.Server.LastInspection >= Config.Business.inspectionCooldownMinutes * 60
            and math.random(1, 100) <= Config.Business.inspectionChancePercent then
            UwU.Server.LastInspection = os.time()
            UwU.RemoveBusinessMoney(Config.Business.inspectionPenalty, 'Failed health inspection', nil, { cleanliness = business.cleanliness })
            UwU.ChangeReputation(-5)
            UwU.BroadcastEmployees('z_uwucafe:client:businessAlert', ('Health inspection failed. The cafe was fined $%s.'):format(Config.Business.inspectionPenalty), 'error')
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        local expiryMinutes = math.max(1, math.floor(tonumber(Config.Ordering.readyExpiryMinutes) or 30))
        local rows = MySQL.query.await(([=[
            SELECT * FROM z_uwucafe_orders
            WHERE status = 'ready' AND order_type <> 'npc'
              AND updated_at < DATE_SUB(NOW(), INTERVAL %d MINUTE)
        ]=]):format(expiryMinutes)) or {}
        for _, order in ipairs(rows) do
            local changed = MySQL.update.await("UPDATE z_uwucafe_orders SET status = 'cancelled' WHERE id = ? AND status = 'ready'", { order.id })
            if changed and changed > 0 then
                local fulfillment = json.decode(order.fulfillment_json or '[]') or {}
                UwU.EnsureStashLoaded(Config.Stock.stashId)
                for _, entry in ipairs(fulfillment) do exports.ox_inventory:AddItem(Config.Stock.stashId, entry.item, entry.quantity, entry.metadata) end
                if order.payment_status == 'paid' then
                    local fullOrder = UwU.GetOrder(order.id)
                    if fullOrder then
                        local target
                        for _, player in pairs(ESX.GetExtendedPlayers() or {}) do if player.identifier == fullOrder.customer_identifier then target = player break end end
                        if target then
                            if fullOrder.payment_method == 'cash' then target.addMoney(fullOrder.total, 'Expired UwU order refund') else target.addAccountMoney('bank', fullOrder.total, 'Expired UwU order refund') end
                            MySQL.update.await("UPDATE z_uwucafe_orders SET payment_status = 'refunded' WHERE id = ?", { fullOrder.id })
                        else
                            MySQL.insert.await('INSERT INTO z_uwucafe_refunds (identifier, amount, payment_method, reason) VALUES (?, ?, ?, ?)', {
                                fullOrder.customer_identifier, fullOrder.total, fullOrder.payment_method, ('Expired order #%s'):format(fullOrder.id)
                            })
                            MySQL.update.await("UPDATE z_uwucafe_orders SET payment_status = 'refunded' WHERE id = ?", { fullOrder.id })
                        end
                    end
                end
            end
        end
        MySQL.update.await("UPDATE z_uwucafe_promotions SET active = 0 WHERE active = 1 AND ends_at <= NOW()")
        MySQL.update.await("UPDATE z_uwucafe_catering SET status = 'expired' WHERE status = 'available' AND expires_at <= NOW()")
        UwU.InvalidatePromotionCache()
        UwU.GenerateCateringContracts()
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(750)
    exports.ox_inventory:RegisterStash(
        Config.Stock.stashId,
        Config.Stock.label,
        Config.Stock.slots,
        Config.Stock.weight,
        false,
        { [Config.JobName] = Config.Stock.minimumGrade },
        Config.Locations.stock
    )
    UwU.GetBusiness()
    UwU.EnsureAllEquipment()
    UwU.GenerateCateringContracts()
    MySQL.update.await(('DELETE FROM z_uwucafe_orders WHERE created_at < DATE_SUB(NOW(), INTERVAL %s DAY) AND status IN (\'completed\', \'cancelled\')'):format(math.floor(Config.OrderRetentionDays)))
    print(('[%s] Complete UwU Cat Cafe v%s loaded.'):format(GetCurrentResourceName(), Config.Version))
end)
