local ESX = exports.es_extended:getSharedObject()
local PlayerData = {}
local targetZones = {}
local employeeBlips = {}
local cafeBlip

UwU.Client.IsOnDuty = false
UwU.Client.ActiveLogistics = nil
UwU.Client.UiOpen = false

local function isEmployee()
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

local function hasGrade(minimum)
    return isEmployee() and (tonumber(PlayerData.job.grade) or 0) >= (minimum or 0)
end

UwU.Client.IsEmployee = isEmployee
UwU.Client.HasGrade = hasGrade
UwU.Client.GetPlayerData = function() return PlayerData end

local function employeeCanInteract() return isEmployee() end
local function onDutyCanInteract() return isEmployee() and UwU.Client.IsOnDuty end

local function addBoxZone(name, coords, size, rotation, options)
    local id = exports.ox_target:addBoxZone({
        name = ('z_uwucafe_%s'):format(name),
        coords = coords,
        size = size,
        rotation = rotation or 0.0,
        debug = Config.Debug,
        options = options
    })
    targetZones[#targetZones + 1] = id
end

local function createCafeBlip()
    if not Config.Blips.cafe.enabled then return end
    cafeBlip = AddBlipForCoord(Config.Blips.cafe.coords.x, Config.Blips.cafe.coords.y, Config.Blips.cafe.coords.z)
    SetBlipSprite(cafeBlip, Config.Blips.cafe.sprite)
    SetBlipColour(cafeBlip, Config.Blips.cafe.colour)
    SetBlipScale(cafeBlip, Config.Blips.cafe.scale)
    SetBlipAsShortRange(cafeBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blips.cafe.label)
    EndTextCommandSetBlipName(cafeBlip)
end

local function createTargets()
    addBoxZone('duty', Config.Locations.duty, Config.Zones.duty.size, Config.Zones.duty.rotation, {{
        name = 'z_uwucafe_duty', icon = 'fa-solid fa-user-clock', label = 'Clock In / Out',
        canInteract = employeeCanInteract, onSelect = function() TriggerEvent('z_uwucafe:client:toggleDuty') end
    }})

    addBoxZone('wardrobe', Config.Locations.wardrobe, Config.Zones.wardrobe.size, Config.Zones.wardrobe.rotation, {{
        name = 'z_uwucafe_wardrobe', icon = 'fa-solid fa-shirt', label = 'Employee Wardrobe',
        canInteract = employeeCanInteract, onSelect = function() TriggerEvent('z_uwucafe:client:openWardrobe') end
    }})

    addBoxZone('tablet', Config.Locations.employeeTablet, Config.Zones.employeeTablet.size, Config.Zones.employeeTablet.rotation, {{
        name = 'z_uwucafe_tablet', icon = 'fa-solid fa-tablet-screen-button', label = 'Open Employee Tablet',
        canInteract = onDutyCanInteract, onSelect = function() TriggerEvent('z_uwucafe:client:openEmployeeTablet') end
    }})

    addBoxZone('register', Config.Locations.register, Config.Zones.register.size, Config.Zones.register.rotation, {{
        name = 'z_uwucafe_register', icon = 'fa-solid fa-cash-register', label = 'Open Register',
        canInteract = function() return onDutyCanInteract() and hasGrade(UwU.GetTabletMinimumGrade('pages', 'register')) end,
        onSelect = function() TriggerEvent('z_uwucafe:client:openEmployeeTablet', 'register') end
    }})

    addBoxZone('customer_terminal', Config.Locations.customerTerminal, Config.Zones.customerTerminal.size, Config.Zones.customerTerminal.rotation, {{
        name = 'z_uwucafe_customer_menu', icon = 'fa-solid fa-cat', label = 'Browse UwU Menu',
        onSelect = function() TriggerEvent('z_uwucafe:client:openCustomerMenu', { orderType = 'terminal' }) end
    }})

    addBoxZone('pickup_counter', Config.Ordering.pickupCounter, Config.Zones.pickupCounter.size, Config.Zones.pickupCounter.rotation, {{
        name = 'z_uwucafe_pickup', icon = 'fa-solid fa-bag-shopping', label = 'Collect Ready Order',
        onSelect = function() TriggerEvent('z_uwucafe:client:collectReadyOrder') end
    }})

    addBoxZone('stock', Config.Locations.stock, Config.Zones.stock.size, Config.Zones.stock.rotation, {{
        name = 'z_uwucafe_stock', icon = 'fa-solid fa-boxes-stacked', label = 'Ingredient Storage',
        canInteract = onDutyCanInteract,
        onSelect = function() exports.ox_inventory:openInventory('stash', Config.Stock.stashId) end
    }})

    addBoxZone('management', Config.Locations.management, Config.Zones.management.size, Config.Zones.management.rotation, {{
        name = 'z_uwucafe_management', icon = 'fa-solid fa-chart-line', label = 'Management Dashboard',
        canInteract = function() return onDutyCanInteract() and hasGrade(UwU.GetTabletMinimumGrade('pages', 'business')) end,
        onSelect = function() TriggerEvent('z_uwucafe:client:openEmployeeTablet', 'business') end
    }})

    addBoxZone('catering_dispatch', Config.Locations.cateringDispatch, vec3(1.2, 1.2, 1.5), 0.0, {{
        name = 'z_uwucafe_catering_dispatch', icon = 'fa-solid fa-truck-fast', label = 'Catering Dispatch',
        canInteract = function() return onDutyCanInteract() and hasGrade(UwU.GetTabletMinimumGrade('pages', 'catering')) end,
        onSelect = function() TriggerEvent('z_uwucafe:client:openEmployeeTablet', 'catering') end
    }})

    for _, stationEntry in ipairs(Config.Stations) do
        local station = stationEntry
        addBoxZone(('station_%s'):format(station.id), station.coords, station.size, station.rotation, {{
            name = ('z_uwucafe_station_%s'):format(station.id), icon = station.icon, label = station.label,
            canInteract = onDutyCanInteract,
            onSelect = function() TriggerEvent('z_uwucafe:client:openStation', station.id) end
        }})
    end

    for _, spotEntry in ipairs(Config.CleaningSpots) do
        local spot = spotEntry
        addBoxZone(('clean_%s'):format(spot.id), spot.coords, vec3(1.2, 1.2, 1.8), 0.0, {{
            name = ('z_uwucafe_clean_%s'):format(spot.id), icon = 'fa-solid fa-broom', label = spot.label,
            canInteract = onDutyCanInteract,
            onSelect = function() TriggerEvent('z_uwucafe:client:cleanSpot', spot.id) end
        }})
    end

    if Config.Features.tableService then
        for _, tableEntry in ipairs(Config.Tables) do
            local tableData = tableEntry
            addBoxZone(('table_%s'):format(tableData.number), tableData.coords, tableData.size, 0.0, {
                {
                    name = ('z_uwucafe_table_order_%s'):format(tableData.number), icon = 'fa-solid fa-utensils',
                    label = ('Order at Table %s'):format(tableData.number),
                    onSelect = function() TriggerEvent('z_uwucafe:client:openCustomerMenu', { orderType = 'table', tableNumber = tableData.number }) end
                },
                {
                    name = ('z_uwucafe_table_call_%s'):format(tableData.number), icon = 'fa-solid fa-bell-concierge',
                    label = 'Call Staff',
                    onSelect = function() TriggerEvent('z_uwucafe:client:callStaff', tableData.number) end
                },
                {
                    name = ('z_uwucafe_table_serve_%s'):format(tableData.number), icon = 'fa-solid fa-hand-holding',
                    label = 'Serve Ready Order', canInteract = onDutyCanInteract,
                    onSelect = function() TriggerEvent('z_uwucafe:client:serveTable', tableData.number) end
                }
            })
        end
    end
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    Wait(500)
    UwU.Client.IsOnDuty = lib.callback.await('z_uwucafe:server:getDuty', false) == true
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    if job.name ~= Config.JobName then UwU.Client.IsOnDuty = false end
end)

RegisterNetEvent('z_uwucafe:client:setDuty', function(state, reason)
    UwU.Client.IsOnDuty = state == true
    if not state and reason == 'afk' then
        lib.notify({ title = Config.JobLabel, description = 'You were clocked out for inactivity.', type = 'error' })
    end
end)

RegisterNetEvent('z_uwucafe:client:updateEmployeeBlips', function(sources)
    local keep = {}
    for _, serverId in ipairs(sources or {}) do
        if serverId ~= GetPlayerServerId(PlayerId()) then
            local player = GetPlayerFromServerId(serverId)
            if player ~= -1 then
                keep[serverId] = true
                if not employeeBlips[serverId] or not DoesBlipExist(employeeBlips[serverId]) then
                    local blip = AddBlipForEntity(GetPlayerPed(player))
                    SetBlipSprite(blip, Config.Blips.employees.sprite)
                    SetBlipColour(blip, Config.Blips.employees.colour)
                    SetBlipScale(blip, Config.Blips.employees.scale)
                    SetBlipDisplay(blip, 2)
                    ShowHeadingIndicatorOnBlip(blip, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString(('UwU Employee [%s]'):format(serverId))
                    EndTextCommandSetBlipName(blip)
                    employeeBlips[serverId] = blip
                end
            end
        end
    end
    for serverId, blip in pairs(employeeBlips) do
        if not keep[serverId] then
            if DoesBlipExist(blip) then RemoveBlip(blip) end
            employeeBlips[serverId] = nil
        end
    end
end)

RegisterNetEvent('z_uwucafe:client:staffCall', function(tableNumber)
    lib.notify({ title = Config.JobLabel, description = _L('staff_called', tableNumber), type = 'warning', duration = 8000 })
end)

RegisterNetEvent('z_uwucafe:client:businessAlert', function(message, notificationType)
    lib.notify({ title = Config.JobLabel, description = message, type = notificationType or 'warning', duration = 10000 })
end)

lib.callback.register('z_uwucafe:client:confirmBill', function(summary)
    local lines = {}
    for _, item in ipairs(summary.items or {}) do lines[#lines + 1] = ('%sx %s — $%s'):format(item.quantity, item.label, item.lineTotal) end
    lines[#lines + 1] = ''
    lines[#lines + 1] = ('Subtotal: $%s'):format(summary.subtotal or 0)
    if (summary.tip or 0) > 0 then lines[#lines + 1] = ('Tip: $%s'):format(summary.tip) end
    lines[#lines + 1] = ('Total: $%s'):format(summary.total or 0)
    local result = lib.alertDialog({
        header = ('Bill from %s'):format(summary.employee or Config.JobLabel),
        content = table.concat(lines, '\n'),
        centered = true,
        cancel = true,
        labels = { confirm = 'Pay', cancel = 'Decline' }
    })
    return result == 'confirm'
end)

CreateThread(function()
    while not ESX.IsPlayerLoaded() do Wait(250) end
    PlayerData = ESX.GetPlayerData()
    createTargets()
    createCafeBlip()
    UwU.Client.IsOnDuty = lib.callback.await('z_uwucafe:server:getDuty', false) == true
end)

RegisterCommand('uwutablet', function()
    if onDutyCanInteract() then TriggerEvent('z_uwucafe:client:openEmployeeTablet') end
end, false)

RegisterCommand('uwuduty', function()
    if isEmployee() then TriggerEvent('z_uwucafe:client:toggleDuty') end
end, false)

RegisterCommand('uwuorder', function()
    TriggerEvent('z_uwucafe:client:openCustomerMenu', { orderType = 'delivery' })
end, false)

RegisterCommand('uwumenu', function()
    TriggerEvent('z_uwucafe:client:openCustomerMenu', { orderType = 'terminal', remoteBrowse = true })
end, false)

exports('OpenDeliveryMenu', function() TriggerEvent('z_uwucafe:client:openCustomerMenu', { orderType = 'delivery' }) end)
exports('OpenCafeMenu', function(context) TriggerEvent('z_uwucafe:client:openCustomerMenu', context or { orderType = 'terminal' }) end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    for _, zone in ipairs(targetZones) do exports.ox_target:removeZone(zone) end
    if cafeBlip and DoesBlipExist(cafeBlip) then RemoveBlip(cafeBlip) end
    for _, blip in pairs(employeeBlips) do if DoesBlipExist(blip) then RemoveBlip(blip) end end
end)
