RegisterNetEvent('z_uwucafe:client:toggleDuty', function()
    local result = lib.callback.await('z_uwucafe:server:toggleDuty', false)
    if not result then return end
    UwU.Client.IsOnDuty = result.onDuty
    lib.notify({
        title = Config.JobLabel,
        description = result.onDuty and _L('clocked_in') or _L('clocked_out'),
        type = result.onDuty and 'success' or 'inform'
    })
end)

RegisterNetEvent('z_uwucafe:client:cleanSpot', function(spotId)
    local spot
    for _, entry in ipairs(Config.CleaningSpots) do if entry.id == spotId then spot = entry break end end
    if not spot then return end
    TaskStartScenarioInPlace(cache.ped, spot.scenario, 0, true)
    local completed = lib.progressCircle({
        duration = 7000,
        label = spot.label,
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    ClearPedTasks(cache.ped)
    if completed then
        local success, message = lib.callback.await('z_uwucafe:server:cleanSpot', false, spotId)
        lib.notify({ title = Config.JobLabel, description = message or 'Cleaning failed.', type = success and 'success' or 'error' })
    end
end)
