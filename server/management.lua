local ESX = UwU.ESX
local userColumns

local function loadUserColumns()
    if userColumns then return userColumns end
    userColumns = {}
    local rows = MySQL.query.await('SHOW COLUMNS FROM users') or {}
    for _, row in ipairs(rows) do userColumns[row.Field] = true end
    return userColumns
end

local function employeeNameExpression()
    local columns = loadUserColumns()
    if columns.firstname and columns.lastname then return "TRIM(CONCAT(COALESCE(firstname, ''), ' ', COALESCE(lastname, '')))" end
    if columns.name then return 'name' end
    return 'identifier'
end

function UwU.GetEmployeesForManagement()
    local query = ('SELECT identifier, job_grade, %s AS display_name FROM users WHERE job = ? ORDER BY job_grade DESC, display_name ASC'):format(employeeNameExpression())
    local rows = MySQL.query.await(query, { Config.JobName }) or {}
    local online = {}
    for _, player in pairs(ESX.GetExtendedPlayers('job', Config.JobName) or {}) do online[player.identifier] = player end
    for _, row in ipairs(rows) do
        row.grade = tonumber(row.job_grade) or 0
        row.name = row.display_name ~= '' and row.display_name or row.identifier
        local player = online[row.identifier]
        row.source = player and player.source or nil
        row.online = player ~= nil
        row.onDuty = player and UwU.Server.Duty[player.source] ~= nil or false
        row.gradeLabel = player and player.job.grade_label or UwU.GetGradeLabel(row.grade)
    end
    return rows
end

local function findTarget(data)
    local targetId = tonumber(data.targetId)
    if targetId then
        local player = ESX.GetPlayerFromId(targetId)
        if player then return player.identifier, player end
    end
    local identifier = UwU.SanitizeText(data.identifier or '', 80)
    if identifier ~= '' then return identifier, nil end
    return nil, nil
end

lib.callback.register('z_uwucafe:server:employeeAction', function(source, data)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'employeeAction')
    if not allowed then return { success = false, message = deniedMessage } end
    data = data or {}
    local manager = ESX.GetPlayerFromId(source)
    local identifier, target = findTarget(data)

    if data.action == 'hire' then
        target = ESX.GetPlayerFromId(tonumber(data.targetId))
        if not target then return { success = false, message = 'Player is not online.' } end
        if not UwU.ArePlayersNear(source, target.source, 6.0) then return { success = false, message = _L('too_far') } end
        target.setJob(Config.JobName, 0)
        identifier = target.identifier
        UwU.EnsureEmployee(identifier)
    elseif data.action == 'fire' then
        if not identifier then return { success = false, message = 'Employee not found.' } end
        if target and target.source == source then return { success = false, message = 'You cannot fire yourself.' } end
        local grade = target and target.job.grade or tonumber(MySQL.scalar.await('SELECT job_grade FROM users WHERE identifier = ? AND job = ?', { identifier, Config.JobName }))
        if not grade then return { success = false, message = 'Employee not found.' } end
        if grade >= manager.job.grade then return { success = false, message = 'You cannot manage an equal or higher grade.' } end
        if target then
            if UwU.Server.Duty[target.source] then TriggerEvent('z_uwucafe:server:forceDutyOff', target.source, 'Job removed') end
            target.setJob('unemployed', 0)
        else
            MySQL.update.await("UPDATE users SET job = 'unemployed', job_grade = 0 WHERE identifier = ? AND job = ?", { identifier, Config.JobName })
        end
    elseif data.action == 'setGrade' then
        if not identifier then return { success = false, message = 'Employee not found.' } end
        local grade = math.floor(tonumber(data.grade) or -1)
        if grade < 0 or grade >= manager.job.grade then return { success = false, message = 'You may only assign grades below your own.' } end
        if not MySQL.scalar.await('SELECT 1 FROM job_grades WHERE job_name = ? AND grade = ?', { Config.JobName, grade }) then return { success = false, message = 'That job grade does not exist.' } end
        local currentGrade = target and target.job.grade or tonumber(MySQL.scalar.await('SELECT job_grade FROM users WHERE identifier = ? AND job = ?', { identifier, Config.JobName }))
        if currentGrade == nil then return { success = false, message = 'Employee not found.' } end
        if currentGrade >= manager.job.grade then return { success = false, message = 'You cannot manage an equal or higher grade.' } end
        if target then target.setJob(Config.JobName, grade)
        else MySQL.update.await('UPDATE users SET job_grade = ? WHERE identifier = ? AND job = ?', { grade, identifier, Config.JobName }) end
    elseif data.action == 'bonus' then
        if not identifier then return { success = false, message = 'Employee not found.' } end
        local amount = UwU.Clamp(math.floor(tonumber(data.amount) or 0), 1, Config.Security.maxManagementAmount)
        if not target then return { success = false, message = 'Employee must be online to receive a bonus.' } end
        if not UwU.RemoveBusinessMoney(amount, 'Employee bonus', manager.identifier, { employee = identifier }) then return { success = false, message = _L('business_funds') } end
        target.addAccountMoney('bank', amount, 'UwU Cafe employee bonus')
    else
        return { success = false, message = 'Invalid management action.' }
    end

    UwU.AddProgress(manager.identifier, Config.Progression.generalXp.management, 'management_actions', 'management', Config.Progression.skillXp.management)
    UwU.TouchDuty(source)
    UwU.Log('management', 'Employee action', ('%s used %s on %s'):format(manager.getName(), tostring(data.action), tostring(identifier)))
    return { success = true, message = 'Employee updated.' }
end)

lib.callback.register('z_uwucafe:server:depositBusiness', function(source, amount)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'depositBusiness')
    if not allowed then return { success = false, message = deniedMessage } end
    amount = UwU.Clamp(math.floor(tonumber(amount) or 0), 1, Config.Security.maxManagementAmount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local bank = xPlayer.getAccount('bank')
    if not bank or bank.money < amount then return { success = false, message = 'You do not have enough bank money.' } end
    xPlayer.removeAccountMoney('bank', amount, 'UwU Cafe deposit')
    UwU.AddBusinessMoney(amount, 'Manager deposit', xPlayer.identifier)
    UwU.TouchDuty(source)
    return { success = true, message = ('$%s deposited.'):format(amount) }
end)

lib.callback.register('z_uwucafe:server:withdrawBusiness', function(source, amount)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'withdrawBusiness')
    if not allowed then return { success = false, message = deniedMessage } end
    amount = UwU.Clamp(math.floor(tonumber(amount) or 0), 1, Config.Security.maxManagementAmount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not UwU.RemoveBusinessMoney(amount, 'Owner withdrawal', xPlayer.identifier) then return { success = false, message = _L('business_funds') } end
    xPlayer.addAccountMoney('bank', amount, 'UwU Cafe withdrawal')
    UwU.TouchDuty(source)
    return { success = true, message = ('$%s withdrawn.'):format(amount) }
end)

lib.callback.register('z_uwucafe:server:equipmentAction', function(source, data)
    data = data or {}
    local permissionKey = data.action == 'upgrade' and 'upgradeEquipment' or 'repairEquipment'
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', permissionKey)
    if not allowed then return { success = false, message = deniedMessage } end
    local xPlayer = ESX.GetPlayerFromId(source)
    local equipment = UwU.GetEquipment(data and data.stationId)
    if not equipment then return { success = false, message = 'Equipment not found.' } end
    if data.action == 'repair' then
        local missing = Config.Equipment.maxCondition - equipment.condition_value
        if missing <= 0 then return { success = false, message = 'This equipment is already fully repaired.' } end
        local cost = math.max(1, math.floor(missing * Config.Equipment.repairBaseCost / 100))
        if not UwU.RemoveBusinessMoney(cost, ('Repair %s'):format(equipment.label), xPlayer.identifier) then return { success = false, message = _L('business_funds') } end
        MySQL.update.await('UPDATE z_uwucafe_equipment SET condition_value = 100 WHERE station_id = ?', { equipment.station_id })
        return { success = true, message = ('Equipment repaired for $%s.'):format(cost) }
    elseif data.action == 'upgrade' then
        local nextLevel = equipment.level + 1
        local cost = Config.Equipment.upgradeCosts[nextLevel]
        if not cost or nextLevel > Config.Equipment.maxLevel then return { success = false, message = 'This equipment is fully upgraded.' } end
        if not UwU.RemoveBusinessMoney(cost, ('Upgrade %s to level %s'):format(equipment.label, nextLevel), xPlayer.identifier) then return { success = false, message = _L('business_funds') } end
        MySQL.update.await('UPDATE z_uwucafe_equipment SET level = ?, condition_value = 100 WHERE station_id = ?', { nextLevel, equipment.station_id })
        return { success = true, message = ('Equipment upgraded to level %s.'):format(nextLevel) }
    end
    return { success = false, message = 'Invalid equipment action.' }
end)

lib.callback.register('z_uwucafe:server:createPromotion', function(source, data)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'createPromotion')
    if not Config.Features.promotions or not allowed then return { success = false, message = deniedMessage or _L('no_permission') } end
    if not UwU.RequireEmployee(source, Config.Promotions.minimumGrade, true) then return { success = false, message = _L('no_permission') } end
    local activeCount = tonumber(MySQL.scalar.await("SELECT COUNT(*) FROM z_uwucafe_promotions WHERE active = 1 AND ends_at > NOW()")) or 0
    if activeCount >= Config.Promotions.maximumActive then return { success = false, message = 'The maximum number of active promotions has been reached.' } end
    data = data or {}
    local name = UwU.SanitizeText(data.name, 80)
    local scope = data.scope
    if scope ~= 'product' and scope ~= 'category' then scope = 'all' end
    local target = UwU.SanitizeText(data.target, 80)
    if scope == 'product' and not Config.Products[target] then return { success = false, message = 'Invalid product.' } end
    if scope == 'category' then
        local found = false
        for _, product in pairs(Config.Products) do if product.category == target then found = true break end end
        if not found then return { success = false, message = 'Invalid category.' } end
    end
    local discount = UwU.Clamp(math.floor(tonumber(data.discount) or 0), 1, Config.Promotions.maximumDiscountPercent)
    local duration = UwU.Clamp(math.floor(tonumber(data.durationHours) or 1), 1, Config.Promotions.maximumDurationHours)
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.insert.await([[
        INSERT INTO z_uwucafe_promotions (name, scope, target, discount_percent, starts_at, ends_at, active, created_by)
        VALUES (?, ?, ?, ?, NOW(), DATE_ADD(NOW(), INTERVAL ? HOUR), 1, ?)
    ]], { name ~= '' and name or ('%s%% Promotion'):format(discount), scope, target, discount, duration, xPlayer.identifier })
    UwU.InvalidatePromotionCache()
    return { success = true, message = 'Promotion created.' }
end)

lib.callback.register('z_uwucafe:server:disablePromotion', function(source, promotionId)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'disablePromotion')
    if not Config.Features.promotions or not allowed then return { success = false, message = deniedMessage or _L('no_permission') } end
    if not UwU.RequireEmployee(source, Config.Promotions.minimumGrade, true) then return { success = false, message = _L('no_permission') } end
    MySQL.update.await('UPDATE z_uwucafe_promotions SET active = 0 WHERE id = ?', { tonumber(promotionId) })
    UwU.InvalidatePromotionCache()
    return { success = true, message = 'Promotion disabled.' }
end)

lib.callback.register('z_uwucafe:server:buyBusinessUpgrade', function(source, key)
    local allowed, deniedMessage = UwU.CheckTabletAccess(source, 'actions', 'buyBusinessUpgrade')
    if not Config.Features.businessUpgrades or not allowed then return { success = false, message = deniedMessage or _L('no_permission') } end
    local config = Config.BusinessUpgrades[key]
    if not config then return { success = false, message = 'Upgrade not found.' } end
    local current = tonumber(MySQL.scalar.await('SELECT level FROM z_uwucafe_upgrades WHERE upgrade_key = ?', { key })) or 0
    local nextLevel = current + 1
    local cost = config.costs[nextLevel]
    if not cost or nextLevel > config.maxLevel then return { success = false, message = 'This upgrade is at maximum level.' } end
    local xPlayer = ESX.GetPlayerFromId(source)
    if not UwU.RemoveBusinessMoney(cost, ('Business upgrade: %s level %s'):format(config.label, nextLevel), xPlayer.identifier) then return { success = false, message = _L('business_funds') } end
    MySQL.insert.await([[
        INSERT INTO z_uwucafe_upgrades (upgrade_key, level) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level)
    ]], { key, nextLevel })
    return { success = true, message = ('%s upgraded to level %s.'):format(config.label, nextLevel) }
end)
