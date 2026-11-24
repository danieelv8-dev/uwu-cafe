local npcs = {}

local function requestControl(entity, timeoutMs)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) or NetworkHasControlOfEntity(entity) then return true end

    local expiresAt = GetGameTimer() + (timeoutMs or 2000)
    NetworkRequestControlOfEntity(entity)
    while DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) and GetGameTimer() < expiresAt do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end
    return DoesEntityExist(entity) and NetworkHasControlOfEntity(entity)
end

local function fadePedOut(ped, durationMs)
    local departure = Config.NPC.departure or {}
    if departure.fadeOut == false or not DoesEntityExist(ped) then return end

    local duration = math.max(100, tonumber(durationMs or departure.fadeDurationMs) or 800)
    local startedAt = GetGameTimer()
    while DoesEntityExist(ped) do
        local elapsed = GetGameTimer() - startedAt
        if elapsed >= duration then break end
        local alpha = math.floor(255 * (1.0 - (elapsed / duration)))
        SetEntityAlpha(ped, math.max(0, alpha), false)
        Wait(0)
    end
end

local function deleteNpc(npcId, useFade)
    local npc = npcs[npcId]
    if not npc then return end

    local ped = npc.ped
    if ped and DoesEntityExist(ped) then
        requestControl(ped, 2000)
        if useFade then fadePedOut(ped) end
        SetEntityAsMissionEntity(ped, true, true)
        DeletePed(ped)
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end

    npcs[npcId] = nil
end

local function sendNpcAway(npcId)
    local npc = npcs[npcId]
    if not npc or npc.departing then return end
    if not npc.ped or not DoesEntityExist(npc.ped) then
        npcs[npcId] = nil
        return
    end

    npc.departing = true
    npc.completing = false

    local departure = Config.NPC.departure or {}
    local exit = npc.exit or Config.NPC.exit
    local ped = npc.ped
    local despawnDelay = math.max(0, tonumber(departure.despawnDelayMs) or 1000)

    CreateThread(function()
        requestControl(ped, 2000)
        ClearPedTasksImmediately(ped)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedKeepTask(ped, true)

        if departure.enabled == false or departure.walkToExit == false or not exit then
            Wait(despawnDelay)
            deleteNpc(npcId, departure.fadeOut ~= false)
            return
        end

        local speed = tonumber(departure.walkSpeed) or 1.0
        local arrivalDistance = math.max(0.5, tonumber(departure.arrivalDistance) or 1.75)
        local maxWalkTime = math.max(5000, tonumber(departure.maxWalkTimeMs) or 30000)
        local repathInterval = math.max(1000, tonumber(departure.repathIntervalMs) or 5000)
        local startedAt = GetGameTimer()
        local nextRepathAt = 0

        local function walkToExit()
            if not DoesEntityExist(ped) then return end
            if departure.useNavMesh == false then
                TaskGoStraightToCoord(ped, exit.x, exit.y, exit.z, speed, maxWalkTime, exit.w or 0.0, arrivalDistance)
            else
                TaskFollowNavMeshToCoord(ped, exit.x, exit.y, exit.z, speed, maxWalkTime, arrivalDistance, false, exit.w or 0.0)
            end
            SetPedKeepTask(ped, true)
            nextRepathAt = GetGameTimer() + repathInterval
        end

        walkToExit()

        while npcs[npcId] and DoesEntityExist(ped) and GetGameTimer() - startedAt < maxWalkTime do
            local coords = GetEntityCoords(ped)
            local distance = #(coords - vec3(exit.x, exit.y, exit.z))
            if distance <= arrivalDistance then break end

            if GetGameTimer() >= nextRepathAt and IsPedStopped(ped) then
                walkToExit()
            end
            Wait(250)
        end

        if not npcs[npcId] then return end
        if DoesEntityExist(ped) then ClearPedTasks(ped) end
        Wait(despawnDelay)
        deleteNpc(npcId, departure.fadeOut ~= false)
    end)
end

local function completeNpc(npcId)
    local npc = npcs[npcId]
    if not npc or npc.completing or npc.departing then return end
    npc.completing = true

    CreateThread(function()
        if DoesEntityExist(npc.ped) then
            TaskTurnPedToFaceCoord(npc.ped, Config.NPC.queue.x, Config.NPC.queue.y, Config.NPC.queue.z, 1000)
            Wait(1200)
            TaskStartScenarioInPlace(npc.ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
        end

        Wait(2500)
        local response = lib.callback.await('z_uwucafe:server:completeNpcCustomer', false, npcId)
        if response and response.success then
            local tipText = response.tip > 0 and _L('npc_rating_tip', response.rating, response.tip) or _L('npc_rating', response.rating)
            lib.notify({
                title = _L('npc_rated_cafe', npc.name),
                description = tipText,
                type = response.rating >= 4 and 'success' or response.rating >= 3 and 'inform' or 'warning'
            })
            sendNpcAway(npcId)
        elseif npcs[npcId] then
            npc.completing = false
        end
    end)
end

RegisterNetEvent('z_uwucafe:client:spawnNpcCustomer', function(data)
    deleteNpc(data.npcId, false)

    local model = joaat(data.model)
    lib.requestModel(model, 10000)
    local spawn = data.spawn
    local ped = CreatePed(4, model, spawn.x, spawn.y, spawn.z - 1.0, spawn.w, true, true)
    if not DoesEntityExist(ped) then return end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetModelAsNoLongerNeeded(model)

    npcs[data.npcId] = {
        ped = ped,
        name = data.name,
        orderId = data.orderId,
        exit = data.exit or Config.NPC.exit,
        completing = false,
        departing = false
    }

    TaskFollowNavMeshToCoord(ped, data.queue.x, data.queue.y, data.queue.z, 1.0, 30000, 0.5, false, data.queue.w or 0.0)
    SetTimeout(18000, function()
        local npc = npcs[data.npcId]
        if npc and not npc.departing and DoesEntityExist(npc.ped) then
            TaskStartScenarioInPlace(npc.ped, 'WORLD_HUMAN_STAND_MOBILE', 0, true)
            if data.ready then completeNpc(data.npcId) end
        end
    end)
end)

RegisterNetEvent('z_uwucafe:client:npcOrderReady', function(npcId)
    completeNpc(npcId)
end)

RegisterNetEvent('z_uwucafe:client:removeNpcCustomer', function(npcId)
    sendNpcAway(npcId)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for npcId in pairs(npcs) do deleteNpc(npcId, false) end
end)
