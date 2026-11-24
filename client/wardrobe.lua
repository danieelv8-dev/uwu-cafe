local originalSkin
local wearingUniform = false

local function skinchangerAvailable()
    return GetResourceState('skinchanger') == 'started'
end

local function putOnUniform()
    if not Config.Features.uniforms or not Config.Wardrobe.enabled then return end
    if not skinchangerAvailable() then
        return lib.notify({ title = Config.JobLabel, description = 'Install skinchanger/esx_skin or adapt client/wardrobe.lua to your appearance resource.', type = 'error' })
    end
    TriggerEvent('skinchanger:getSkin', function(skin)
        originalSkin = originalSkin or skin
        local clothes = skin.sex == 0 and Config.Wardrobe.male or Config.Wardrobe.female
        TriggerEvent('skinchanger:loadClothes', skin, clothes)
        wearingUniform = true
        lib.notify({ title = Config.JobLabel, description = 'Work uniform equipped.', type = 'success' })
    end)
end

local function restoreClothes()
    if not originalSkin or not skinchangerAvailable() then
        return lib.notify({ title = Config.JobLabel, description = 'No saved civilian outfit is available.', type = 'error' })
    end
    TriggerEvent('skinchanger:loadSkin', originalSkin)
    originalSkin = nil
    wearingUniform = false
    lib.notify({ title = Config.JobLabel, description = 'Civilian outfit restored.', type = 'success' })
end

RegisterNetEvent('z_uwucafe:client:openWardrobe', function()
    local options = {
        { title = 'Work Uniform', description = 'Equip the configured UwU Cafe uniform.', icon = 'shirt', onSelect = putOnUniform },
        { title = 'Civilian Clothes', description = 'Restore the outfit you wore before changing.', icon = 'user', disabled = not wearingUniform, onSelect = restoreClothes }
    }
    lib.registerContext({ id = 'z_uwucafe_wardrobe', title = 'Employee Wardrobe', options = options })
    lib.showContext('z_uwucafe_wardrobe')
end)
