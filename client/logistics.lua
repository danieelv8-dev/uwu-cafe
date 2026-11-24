local function deleteVehicle(job)
    if job and job.vehicle and DoesEntityExist(job.vehicle) then
        SetEntityAsMissionEntity(job.vehicle, true, true)
        DeleteVehicle(job.vehicle)
    end
end

local function finishJob(message, notificationType)
    local job = UwU.Client.ActiveLogistics
    if job then deleteVehicle(job) end
    UwU.Client.ActiveLogistics = nil
    lib.hideTextUI()
    if message then lib.notify({ title = Config.JobLabel, description = message, type = notificationType or 'inform' }) end
end

local function spawnWorkVehicle(modelName)
    local model = joaat(modelName)
    lib.requestModel(model, 10000)
    local spawn = Config.SupplyDelivery.vehicleSpawn
    if IsAnyVehicleNearPoint(spawn.x, spawn.y, spawn.z, 3.0) then return nil end
    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    if not DoesEntityExist(vehicle) then return nil end
    SetVehicleNumberPlateText(vehicle, ('UWU%03d'):format(math.random(1, 999)))
    SetEntityAsMissionEntity(vehicle, true, true)
    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetModelAsNoLongerNeeded(model)
    return vehicle
end

RegisterNetEvent('z_uwucafe:client:beginLogistics', function(data)
    if UwU.Client.ActiveLogistics then return end
    local job = {
        token = data.token,
        type = data.type,
        orderId = data.orderId,
        contractId = data.contractId,
        packId = data.packId,
        stage = data.type == 'supply' and 'supplier' or 'destination',
        expiresAt = GetGameTimer() + ((data.type == 'supply' and Config.SupplyDelivery.timeoutMinutes or data.type == 'customer_delivery' and Config.Ordering.deliveryTimeoutMinutes or Config.Catering.acceptanceTimeoutMinutes) * 60000)
    }

    if data.type == 'supply' then
        job.vehicle = spawnWorkVehicle(Config.SupplyDelivery.vehicleModel)
        if not job.vehicle then
            TriggerServerEvent('z_uwucafe:server:cancelLogistics', data.token)
            return finishJob('The delivery vehicle could not be created.', 'error')
        end
        job.destination = Config.SupplyDelivery.supplier
    elseif data.type == 'customer_delivery' then
        if Config.CustomerDelivery.requireCafeVehicle then
            job.vehicle = spawnWorkVehicle(Config.CustomerDelivery.vehicleModel)
            if not job.vehicle then
                TriggerServerEvent('z_uwucafe:server:cancelLogistics', data.token)
                return finishJob('The delivery vehicle could not be created.', 'error')
            end
        end
        job.destination = vec3(data.destination.x, data.destination.y, data.destination.z)
    elseif data.type == 'catering' then
        job.destination = vec3(data.destination.coords.x, data.destination.coords.y, data.destination.coords.z)
        job.destinationLabel = data.destination.label
    end

    UwU.Client.ActiveLogistics = job
    SetNewWaypoint(job.destination.x, job.destination.y)
    lib.notify({ title = Config.JobLabel, description = data.message or 'Logistics job started.', type = 'inform' })
end)

RegisterCommand('uwucanceljob', function()
    local job = UwU.Client.ActiveLogistics
    if not job then return end
    TriggerServerEvent('z_uwucafe:server:cancelLogistics', job.token)
    finishJob('Logistics job cancelled.', 'error')
end, false)

CreateThread(function()
    while true do
        local job = UwU.Client.ActiveLogistics
        if not job then
            Wait(1000)
        else
            if GetGameTimer() > job.expiresAt then
                TriggerServerEvent('z_uwucafe:server:cancelLogistics', job.token)
                finishJob('The logistics job expired.', 'error')
            elseif job.vehicle and not DoesEntityExist(job.vehicle) then
                TriggerServerEvent('z_uwucafe:server:cancelLogistics', job.token)
                finishJob('The work vehicle was lost.', 'error')
            else
                local target = job.destination
                local distance = #(GetEntityCoords(cache.ped) - target)
                if distance < 30.0 then
                    DrawMarker(1, target.x, target.y, target.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 0.6, 255, 145, 190, 140, false, false, 2, false, nil, nil, false)
                end
                if distance < 3.5 then
                    local text
                    if job.type == 'supply' then text = job.stage == 'supplier' and '[E] Load supplies' or '[E] Deliver supplies'
                    elseif job.type == 'customer_delivery' then text = '[E] Hand order to customer'
                    else text = ('[E] Deliver catering to %s'):format(job.destinationLabel or 'destination') end
                    lib.showTextUI(text)
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        if job.type == 'supply' and job.stage == 'supplier' then
                            local ok = lib.progressCircle({ duration = 6500, label = 'Loading supplies', canCancel = true, disable = { move = true, car = true, combat = true } })
                            if ok then
                                local response = lib.callback.await('z_uwucafe:server:pickupSupplyRun', false, job.token)
                                if response and response.success then
                                    job.stage = 'return'
                                    job.destination = Config.Locations.deliveryReturn
                                    SetNewWaypoint(job.destination.x, job.destination.y)
                                    lib.notify({ title = Config.JobLabel, description = _L('supply_loaded'), type = 'success' })
                                else
                                    finishJob(response and response.message or 'Supply pickup failed.', 'error')
                                end
                            end
                        elseif job.type == 'supply' then
                            local health = job.vehicle and GetVehicleEngineHealth(job.vehicle) or 1000
                            local response = lib.callback.await('z_uwucafe:server:completeSupplyRun', false, job.token, health)
                            if response and response.success then finishJob(response.message, 'success')
                            else lib.notify({ title = Config.JobLabel, description = response and response.message or 'Delivery failed.', type = 'error' }) end
                        elseif job.type == 'customer_delivery' then
                            local response = lib.callback.await('z_uwucafe:server:completeCustomerDelivery', false, job.token)
                            if response and response.success then finishJob(response.message, 'success')
                            else lib.notify({ title = Config.JobLabel, description = response and response.message or 'Delivery failed.', type = 'error' }) end
                        elseif job.type == 'catering' then
                            local response = lib.callback.await('z_uwucafe:server:completeCatering', false, job.token)
                            if response and response.success then finishJob(('%s Business reward: $%s, bonus: $%s.'):format(response.message, response.reward, response.bonus), 'success')
                            else lib.notify({ title = Config.JobLabel, description = response and response.message or 'Catering failed.', type = 'error' }) end
                        end
                    end
                else
                    lib.hideTextUI()
                end
                Wait(0)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lib.hideTextUI()
    deleteVehicle(UwU.Client.ActiveLogistics)
end)
