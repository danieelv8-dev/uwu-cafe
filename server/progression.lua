local statColumns = {
    crafts = true,
    orders_completed = true,
    table_orders = true,
    customer_deliveries = true,
    supply_deliveries = true,
    catering_completed = true,
    cleaning_actions = true,
    management_actions = true
}

local skillColumns = {
    cooking = 'cooking_xp',
    drinks = 'drinks_xp',
    service = 'service_xp',
    delivery = 'delivery_xp',
    management = 'management_xp'
}

local function xpForLevel(level, base, multiplier)
    if level <= 1 then return 0 end
    local total = 0
    for current = 1, level - 1 do
        total = total + math.floor(base * (multiplier ^ (current - 1)))
    end
    return total
end

local function getLevel(xp, base, multiplier, maximum)
    xp = tonumber(xp) or 0
    local level = 1
    while level < maximum and xp >= xpForLevel(level + 1, base, multiplier) do level = level + 1 end
    local current = xpForLevel(level, base, multiplier)
    local nextXp = level >= maximum and current or xpForLevel(level + 1, base, multiplier)
    return level, current, nextXp
end

function UwU.EnsureEmployee(identifier)
    if not identifier then return end
    MySQL.insert.await([[
        INSERT IGNORE INTO z_uwucafe_employees
            (identifier, xp, total_minutes, crafts, orders_completed, table_orders, customer_deliveries,
             supply_deliveries, catering_completed, cleaning_actions, management_actions,
             cooking_xp, drinks_xp, service_xp, delivery_xp, management_xp)
        VALUES (?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    ]], { identifier })
end

function UwU.GetEmployeeStats(identifier)
    UwU.EnsureEmployee(identifier)
    local row = MySQL.single.await('SELECT * FROM z_uwucafe_employees WHERE identifier = ?', { identifier }) or {}
    row.xp = tonumber(row.xp) or 0
    row.level, row.currentLevelXp, row.nextLevelXp = getLevel(row.xp, Config.Progression.levelBase, Config.Progression.levelMultiplier, Config.Progression.maxLevel)
    row.skills = {}
    for skill, column in pairs(skillColumns) do
        local skillXp = tonumber(row[column]) or 0
        local level, currentXp, nextXp = getLevel(skillXp, Config.Progression.skillLevelBase, Config.Progression.skillLevelMultiplier, Config.Progression.maxSkillLevel)
        row.skills[skill] = { xp = skillXp, level = level, currentLevelXp = currentXp, nextLevelXp = nextXp }
    end
    return row
end

function UwU.AddProgress(identifier, generalXp, statColumn, skill, skillXp)
    if not identifier then return end
    generalXp = math.max(0, math.floor(tonumber(generalXp) or 0))
    skillXp = math.max(0, math.floor(tonumber(skillXp) or 0))
    UwU.EnsureEmployee(identifier)

    local sets, params = { 'xp = xp + ?' }, { generalXp }
    if statColumn and statColumns[statColumn] then sets[#sets + 1] = ('%s = %s + 1'):format(statColumn, statColumn) end
    local skillColumn = skill and skillColumns[skill]
    if skillColumn and skillXp > 0 then
        sets[#sets + 1] = ('%s = %s + ?'):format(skillColumn, skillColumn)
        params[#params + 1] = skillXp
    end
    params[#params + 1] = identifier
    MySQL.update.await(('UPDATE z_uwucafe_employees SET %s WHERE identifier = ?'):format(table.concat(sets, ', ')), params)
end

function UwU.AddDutyMinutes(identifier, minutes)
    minutes = math.max(0, math.floor(tonumber(minutes) or 0))
    if not identifier or minutes <= 0 then return end
    UwU.EnsureEmployee(identifier)
    MySQL.update.await('UPDATE z_uwucafe_employees SET total_minutes = total_minutes + ? WHERE identifier = ?', { minutes, identifier })
end
