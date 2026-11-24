local uiOpen = false
local currentMode
local currentContext = {}
local refreshQueued = false

local employeeTabOrder = {
    'orders', 'deliveries', 'register', 'catering', 'supplies',
    'stock', 'profile', 'business', 'equipment', 'promotions', 'staff'
}

local function resolveEmployeeTab(data, requestedTab)
    local pages = data and data.permissions and data.permissions.pages or {}
    if requestedTab and pages[requestedTab] then return requestedTab end

    local defaultTab = (data and data.defaultTab) or (Config.TabletAccess and Config.TabletAccess.defaultPage)
    if defaultTab and pages[defaultTab] then return defaultTab end

    for _, tab in ipairs(employeeTabOrder) do
        if pages[tab] then return tab end
    end
end

local function fetchBootstrap()
    local endpoint = currentMode == 'employee' and 'z_uwucafe:server:getEmployeeBootstrap' or 'z_uwucafe:server:getCustomerBootstrap'
    return lib.callback.await(endpoint, false, currentMode == 'customer' and currentContext or nil)
end

local function closeUi()
    uiOpen = false
    UwU.Client.UiOpen = false
    currentMode = nil
    currentContext = {}
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function setUi(state, mode, selectedTab, context)
    if not state then return closeUi() end
    currentMode = mode
    currentContext = context or {}
    local data = fetchBootstrap()
    if not data then return end
    if mode == 'employee' then
        selectedTab = resolveEmployeeTab(data, selectedTab)
        if not selectedTab then
            lib.notify({ title = Config.JobLabel, description = _L('no_permission'), type = 'error' })
            return
        end
    end
    uiOpen = true
    UwU.Client.UiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', mode = mode, selectedTab = selectedTab, payload = data })
end

local function refreshUi()
    if not uiOpen then return end
    local response = fetchBootstrap()
    if response then SendNUIMessage({ action = 'data', payload = response }) end
end

RegisterNetEvent('z_uwucafe:client:openCustomerMenu', function(context)
    context = context or { orderType = 'terminal' }
    setUi(true, 'customer', 'menu', context)
end)

RegisterNetEvent('z_uwucafe:client:openEmployeeTablet', function(selectedTab)
    if not UwU.Client.IsEmployee() or not UwU.Client.IsOnDuty then
        lib.notify({ title = Config.JobLabel, description = _L('not_on_duty'), type = 'error' })
        return
    end
    setUi(true, 'employee', selectedTab or 'orders')
end)

RegisterNetEvent('z_uwucafe:client:ordersChanged', function()
    if not uiOpen or refreshQueued then return end
    refreshQueued = true
    SetTimeout(500, function()
        refreshQueued = false
        refreshUi()
    end)
end)

RegisterNetEvent('z_uwucafe:client:collectReadyOrder', function()
    local data = lib.callback.await('z_uwucafe:server:getCustomerBootstrap', false, { orderType = 'terminal' })
    local options = {}
    for _, order in ipairs(data and data.orders or {}) do
        if order.status == 'ready' and order.order_type ~= 'delivery' and order.order_type ~= 'npc' then
            options[#options + 1] = {
                title = ('Order #%s'):format(order.id),
                description = table.concat((function()
                    local lines = {}
                    for _, item in ipairs(order.items or {}) do lines[#lines + 1] = ('%sx %s'):format(item.quantity, item.label) end
                    return lines
                end)(), ', '),
                icon = 'bag-shopping',
                onSelect = function()
                    local response = lib.callback.await('z_uwucafe:server:collectOrder', false, order.id)
                    lib.notify({ title = Config.JobLabel, description = response.message, type = response.success and 'success' or 'error' })
                end
            }
        end
    end
    if #options == 0 then options[1] = { title = 'No ready orders', disabled = true, icon = 'clock' } end
    lib.registerContext({ id = 'z_uwucafe_collect_orders', title = 'Order Collection', options = options })
    lib.showContext('z_uwucafe_collect_orders')
end)

RegisterNetEvent('z_uwucafe:client:serveTable', function(tableNumber)
    local orders = lib.callback.await('z_uwucafe:server:getReadyTableOrders', false, tableNumber) or {}
    local options = {}
    for _, order in ipairs(orders) do
        local orderId = order.id
        options[#options + 1] = {
            title = ('Serve Order #%s to %s'):format(order.id, order.customer_name),
            description = ('Table %s • $%s'):format(tableNumber, order.total),
            icon = 'hand-holding',
            onSelect = function()
                local response = lib.callback.await('z_uwucafe:server:serveTableOrder', false, tableNumber, orderId)
                lib.notify({ title = Config.JobLabel, description = response.message, type = response.success and 'success' or 'error' })
            end
        }
    end
    if #options == 0 then options[1] = { title = 'No ready orders for this table', disabled = true, icon = 'clock' } end
    lib.registerContext({ id = ('z_uwucafe_table_%s_orders'):format(tableNumber), title = ('Table %s'):format(tableNumber), options = options })
    lib.showContext(('z_uwucafe_table_%s_orders'):format(tableNumber))
end)

RegisterNetEvent('z_uwucafe:client:callStaff', function(tableNumber)
    local response = lib.callback.await('z_uwucafe:server:callStaff', false, tableNumber)
    lib.notify({ title = Config.JobLabel, description = response.message, type = response.success and 'success' or 'error' })
end)

RegisterNUICallback('close', function(_, cb) closeUi() cb({ ok = true }) end)
RegisterNUICallback('refresh', function(_, cb) cb(fetchBootstrap() or { error = true }) end)

RegisterNUICallback('placeOrder', function(data, cb)
    data.orderType = currentContext.orderType or data.orderType
    data.tableNumber = currentContext.tableNumber or data.tableNumber
    cb(lib.callback.await('z_uwucafe:server:placeOrder', false, data) or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('cancelMyOrder', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:cancelMyOrder', false, tonumber(data.orderId)) or { success = false })
end)

RegisterNUICallback('updateOrder', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:updateOrder', false, tonumber(data.orderId), data.status) or { success = false })
end)

RegisterNUICallback('createRegisterOrder', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:createRegisterOrder', false, data) or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('startSupply', function(data, cb)
    local response = lib.callback.await('z_uwucafe:server:startSupplyRun', false, data.packId)
    if response and response.success then TriggerEvent('z_uwucafe:client:beginLogistics', response) end
    cb(response or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('acceptDelivery', function(data, cb)
    local response = lib.callback.await('z_uwucafe:server:acceptCustomerDelivery', false, tonumber(data.orderId))
    if response and response.success then TriggerEvent('z_uwucafe:client:beginLogistics', response) end
    cb(response or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('acceptCatering', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:acceptCatering', false, tonumber(data.contractId)) or { success = false })
end)

RegisterNUICallback('startCateringDelivery', function(data, cb)
    local response = lib.callback.await('z_uwucafe:server:startCateringDelivery', false, tonumber(data.contractId))
    if response and response.success then TriggerEvent('z_uwucafe:client:beginLogistics', response) end
    cb(response or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('employeeAction', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:employeeAction', false, data) or { success = false, message = 'No response from server.' })
end)

RegisterNUICallback('withdrawBusiness', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:withdrawBusiness', false, tonumber(data.amount)) or { success = false })
end)

RegisterNUICallback('depositBusiness', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:depositBusiness', false, tonumber(data.amount)) or { success = false })
end)

RegisterNUICallback('equipmentAction', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:equipmentAction', false, data) or { success = false })
end)

RegisterNUICallback('createPromotion', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:createPromotion', false, data) or { success = false })
end)

RegisterNUICallback('disablePromotion', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:disablePromotion', false, tonumber(data.promotionId)) or { success = false })
end)

RegisterNUICallback('buyUpgrade', function(data, cb)
    cb(lib.callback.await('z_uwucafe:server:buyBusinessUpgrade', false, data.key) or { success = false })
end)

CreateThread(function()
    while true do
        if uiOpen and IsControlJustReleased(0, 200) then closeUi() end
        Wait(uiOpen and 0 or 500)
    end
end)
