local ESX = exports.es_extended:getSharedObject()

UwU.Server.Duty = UwU.Server.Duty or {}
UwU.Server.RateLimits = UwU.Server.RateLimits or {}
UwU.Server.CraftTokens = UwU.Server.CraftTokens or {}
UwU.Server.ActiveLogistics = UwU.Server.ActiveLogistics or {}
UwU.Server.NPCs = UwU.Server.NPCs or {}
UwU.Server.NPCHosts = UwU.Server.NPCHosts or {}
UwU.Server.LastInspection = UwU.Server.LastInspection or 0

UwU.ESX = ESX

function UwU.Log(webhookType, title, description, color)
    if not Config.Webhooks.enabled then return end
    local webhook = Config.Webhooks[webhookType]
    if not webhook or webhook == '' then return end

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = Config.JobLabel,
        embeds = {{
            title = title,
            description = description,
            color = color or 16744619,
            footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

function UwU.Notify(source, description, notificationType)
    TriggerClientEvent('ox_lib:notify', source, {
        title = Config.JobLabel,
        description = description,
        type = notificationType or 'inform'
    })
end

function UwU.Token(prefix)
    return ('%s:%s:%s:%s'):format(prefix or 'uwu', os.time(), math.random(100000, 999999), math.random(100000, 999999))
end

function UwU.RateLimit(source, key, cooldownMs)
    local now = GetGameTimer()
    UwU.Server.RateLimits[source] = UwU.Server.RateLimits[source] or {}
    local expires = UwU.Server.RateLimits[source][key] or 0
    if now < expires then return false end
    UwU.Server.RateLimits[source][key] = now + (cooldownMs or Config.Security.actionRateLimitMs)
    return true
end

function UwU.IsNear(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if not ped or ped <= 0 then return false end
    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - coords) <= (maxDistance or Config.ServerValidationDistance)
end

function UwU.ArePlayersNear(sourceA, sourceB, maxDistance)
    local pedA, pedB = GetPlayerPed(sourceA), GetPlayerPed(sourceB)
    if not pedA or pedA <= 0 or not pedB or pedB <= 0 then return false end
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) <= (maxDistance or 5.0)
end

function UwU.GetPlayer(source)
    return ESX.GetPlayerFromId(tonumber(source))
end

function UwU.RequireEmployee(source, minimumGrade, requireDuty)
    local xPlayer = UwU.GetPlayer(source)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then return false end
    if (tonumber(xPlayer.job.grade) or 0) < (minimumGrade or 0) then return false end
    if requireDuty and not UwU.Server.Duty[source] then return false end
    return true
end

function UwU.TouchDuty(source)
    local duty = UwU.Server.Duty[source]
    if not duty then return end
    duty.lastActivity = os.time()
    local ped = GetPlayerPed(source)
    if ped and ped > 0 then duty.lastCoords = GetEntityCoords(ped) end
end

function UwU.FindStation(stationId)
    for _, station in ipairs(Config.Stations) do
        if station.id == stationId then return station end
    end
end

function UwU.FindTable(tableNumber)
    tableNumber = tonumber(tableNumber)
    for _, tableData in ipairs(Config.Tables) do
        if tableData.number == tableNumber then return tableData end
    end
end

function UwU.FindCleaningSpot(spotId)
    for _, spot in ipairs(Config.CleaningSpots) do
        if spot.id == spotId then return spot end
    end
end

function UwU.FindCateringDestination(destinationId)
    for _, destination in ipairs(Config.Catering.destinations) do
        if destination.id == destinationId then return destination end
    end
end

function UwU.GetOnlineEmployees(requireDuty)
    local employees = {}
    local players = ESX.GetExtendedPlayers('job', Config.JobName)
    for _, player in pairs(players or {}) do
        if not requireDuty or UwU.Server.Duty[player.source] then
            employees[#employees + 1] = player
        end
    end
    return employees
end

function UwU.GetOnDutyCount()
    local count = 0
    for source in pairs(UwU.Server.Duty) do
        if GetPlayerName(source) and UwU.RequireEmployee(source, 0, false) then count = count + 1 end
    end
    return count
end

function UwU.BroadcastEmployees(eventName, ...)
    for _, employee in ipairs(UwU.GetOnlineEmployees(true)) do
        TriggerClientEvent(eventName, employee.source, ...)
    end
end

function UwU.SanitizeText(value, maximumLength)
    value = tostring(value or '')
    value = value:gsub('[%c]', ' '):gsub('%s+', ' ')
    return value:sub(1, maximumLength or Config.Security.maxNotesLength)
end

function UwU.GetInventoryItemCount(inventory, item)
    return tonumber(exports.ox_inventory:Search(inventory, 'count', item)) or 0
end

function UwU.EnsureStashLoaded(stashId)
    exports.ox_inventory:GetInventory(stashId)
end

function UwU.GetGradeLabel(grade)
    local row = MySQL.single.await('SELECT label FROM job_grades WHERE job_name = ? AND grade = ?', { Config.JobName, grade })
    return row and row.label or ('Grade %s'):format(grade)
end

function UwU.RequireTabletAccess(source, group, key, requireDuty)
    local xPlayer = UwU.GetPlayer(source)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then return false end
    if requireDuty and not UwU.Server.Duty[source] then return false end
    return UwU.HasTabletAccess(xPlayer.job.grade, group, key)
end

function UwU.CheckTabletAccess(source, group, key)
    if not UwU.RequireEmployee(source, 0, true) then return false, _L('not_on_duty') end
    if not UwU.RequireTabletAccess(source, group, key, true) then return false, _L('no_permission') end

    if group == 'actions' then
        local page = Config.TabletAccess and Config.TabletAccess.actionPages and Config.TabletAccess.actionPages[key]
        if page and not UwU.RequireTabletAccess(source, 'pages', page, true) then
            return false, _L('no_permission')
        end
    end

    return true
end
