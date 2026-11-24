local function ensureEquipment(station)
    MySQL.insert.await([[
        INSERT IGNORE INTO z_uwucafe_equipment (station_id, equipment_key, label, level, condition_value)
        VALUES (?, ?, ?, 1, 100)
    ]], { station.id, station.equipment or station.station, station.label })
end

function UwU.EnsureAllEquipment()
    for _, station in ipairs(Config.Stations) do ensureEquipment(station) end
end

function UwU.GetEquipment(stationId)
    local station = UwU.FindStation(stationId)
    if not station then return nil end
    ensureEquipment(station)
    local row = MySQL.single.await('SELECT * FROM z_uwucafe_equipment WHERE station_id = ?', { stationId })
    if row then
        row.level = tonumber(row.level) or 1
        row.condition_value = tonumber(row.condition_value) or 100
    end
    return row
end

function UwU.GetAllEquipment()
    UwU.EnsureAllEquipment()
    local rows = MySQL.query.await('SELECT * FROM z_uwucafe_equipment ORDER BY label ASC') or {}
    for _, row in ipairs(rows) do
        row.level = tonumber(row.level) or 1
        row.condition_value = tonumber(row.condition_value) or 100
        row.repairCost = math.max(0, math.floor((Config.Equipment.maxCondition - row.condition_value) * Config.Equipment.repairBaseCost / 100))
        row.upgradeCost = Config.Equipment.upgradeCosts[row.level + 1]
    end
    return rows
end

function UwU.GetCraftModifiers(stationId)
    local equipment = UwU.GetEquipment(stationId)
    if not equipment then return nil end
    local condition = tonumber(equipment.condition_value) or 100
    local level = UwU.Clamp(tonumber(equipment.level) or 1, 1, Config.Equipment.maxLevel)
    local damagedSlowdown = condition < 50 and (1 + ((50 - condition) / 100)) or 1.0
    return {
        level = level,
        condition = condition,
        usable = condition >= Config.Equipment.minimumConditionToUse,
        durationMultiplier = (Config.Equipment.speedMultiplier[level] or 1.0) * damagedSlowdown,
        qualityBonus = (Config.Equipment.qualityBonus[level] or 0) - math.max(0, math.floor((40 - condition) / 5))
    }
end

function UwU.DegradeEquipment(stationId)
    local amount = math.random(Config.Equipment.degradationPerCraft.min, Config.Equipment.degradationPerCraft.max)
    MySQL.update.await('UPDATE z_uwucafe_equipment SET condition_value = GREATEST(0, condition_value - ?) WHERE station_id = ?', { amount, stationId })
end
