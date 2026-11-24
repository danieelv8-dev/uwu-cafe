CreateThread(function()
    Wait(1000)
    exports.ox_inventory:displayMetadata({
        quality = 'Quality',
        preparedBy = 'Prepared by',
        preparedAt = 'Prepared at',
        expiresAt = 'Fresh until'
    })
end)

local function unixTime()
    if GetCloudTimeAsInt then return GetCloudTimeAsInt() end
    return os.time()
end

local function qualityMultiplier(metadata)
    local score = tonumber(metadata and metadata.qualityScore) or UwU.QualityScore(metadata and metadata.quality)
    if score >= 92 then return 1.25 end
    if score >= 75 then return 1.12 end
    if score < 45 then return 0.75 end
    return 1.0
end

exports('consume', function(data, slot)
    local product = Config.Products[data.name]
    if not product then return end
    local metadata = data.metadata or {}
    if tonumber(metadata.expiresAt) and tonumber(metadata.expiresAt) <= unixTime() then
        lib.notify({ title = Config.JobLabel, description = 'This item is no longer fresh.', type = 'error' })
        return
    end
    exports.ox_inventory:useItem(data, function(used)
        if not used then return end
        local multiplier = qualityMultiplier(metadata)
        if product.hunger and GetResourceState('esx_status') == 'started' then
            TriggerEvent('esx_status:add', 'hunger', math.floor(product.hunger * 10000 * multiplier))
        end
        if product.thirst and GetResourceState('esx_status') == 'started' then
            TriggerEvent('esx_status:add', 'thirst', math.floor(product.thirst * 10000 * multiplier))
        end
        lib.notify({
            title = Config.JobLabel,
            description = ('You enjoyed %s (%s quality).'):format(product.label, metadata.quality or 'Normal'),
            type = 'success'
        })
    end)
end)
