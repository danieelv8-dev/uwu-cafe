UwU = UwU or {}
UwU.Client = UwU.Client or {}
UwU.Server = UwU.Server or {}

function UwU.Round(value, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor((tonumber(value) or 0) * multiplier + 0.5) / multiplier
end

function UwU.Clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    return math.max(minimum, math.min(maximum, value))
end

function UwU.TableCount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

function UwU.DeepCopy(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, entry in pairs(value) do copy[UwU.DeepCopy(key)] = UwU.DeepCopy(entry) end
    return copy
end

function UwU.QualityScore(label)
    local scores = { Poor = 35, Normal = 60, Good = 82, Perfect = 100 }
    return scores[label] or tonumber(label) or 60
end

function UwU.QualityLabel(score)
    score = tonumber(score) or 60
    if score >= 92 then return 'Perfect' end
    if score >= 75 then return 'Good' end
    if score >= 45 then return 'Normal' end
    return 'Poor'
end

function UwU.GetTabletMinimumGrade(group, key)
    local access = Config.TabletAccess or {}
    local entries = access[group] or {}
    local grade = tonumber(entries[key])
    if grade == nil then return math.huge end
    return grade
end

function UwU.HasTabletAccess(grade, group, key)
    grade = tonumber(grade) or -1
    return grade >= UwU.GetTabletMinimumGrade(group, key)
end

function UwU.GetTabletPermissions(grade)
    grade = tonumber(grade) or -1
    local permissions = { pages = {}, actions = {} }

    for page in pairs((Config.TabletAccess and Config.TabletAccess.pages) or {}) do
        permissions.pages[page] = UwU.HasTabletAccess(grade, 'pages', page)
    end

    for action in pairs((Config.TabletAccess and Config.TabletAccess.actions) or {}) do
        permissions.actions[action] = UwU.HasTabletAccess(grade, 'actions', action)
    end

    for action, page in pairs((Config.TabletAccess and Config.TabletAccess.actionPages) or {}) do
        if permissions.pages[page] ~= true then permissions.actions[action] = false end
    end

    local features = Config.Features or {}
    if features.customerDelivery == false then
        permissions.pages.deliveries = false
        permissions.actions.acceptDelivery = false
    end
    if features.catering == false or (Config.Catering and Config.Catering.enabled == false) then
        permissions.pages.catering = false
        permissions.actions.acceptCatering = false
        permissions.actions.startCateringDelivery = false
    end
    if features.promotions == false then
        permissions.pages.promotions = false
        permissions.actions.createPromotion = false
        permissions.actions.disablePromotion = false
    end
    if features.equipment == false then
        permissions.pages.equipment = false
        permissions.actions.repairEquipment = false
        permissions.actions.upgradeEquipment = false
    end
    if features.businessUpgrades == false then
        permissions.actions.buyBusinessUpgrade = false
    end

    -- Compatibility flags retained for older/custom NUI code.
    permissions.manage = permissions.pages.staff == true
    permissions.owner = permissions.actions.withdrawBusiness == true
    permissions.supervise = permissions.pages.business == true
    permissions.supplies = permissions.pages.supplies == true
    permissions.catering = permissions.pages.catering == true

    return permissions
end
