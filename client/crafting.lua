local stationLookup = {}
for _, station in ipairs(Config.Stations) do stationLookup[station.id] = station end

local stationAnimations = {
    prep = { dict = 'anim@amb@business@coc@coc_unpack_cut_left@', clip = 'coke_cut_v1_coccutter' },
    grill = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
    fryer = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
    assembly = { dict = 'anim@amb@business@coc@coc_unpack_cut_left@', clip = 'coke_cut_v1_coccutter' },
    drinks = { dict = 'mp_ped_interaction', clip = 'handshake_guy_a' },
    dessert = { dict = 'amb@prop_human_bbq@male@base', clip = 'base' },
    packaging = { dict = 'anim@heists@box_carry@', clip = 'idle' }
}

local function ingredientDescription(ingredients)
    local lines = {}
    for item, amount in pairs(ingredients) do
        local itemData = exports.ox_inventory:Items(item)
        lines[#lines + 1] = ('%sx %s'):format(amount, itemData and itemData.label or item)
    end
    table.sort(lines)
    return table.concat(lines, '\n')
end

local function beginCraft(recipeId, stationId)
    local recipe = Config.Recipes[recipeId]
    local station = stationLookup[stationId]
    if not recipe or not station then return end
    local preparation = lib.callback.await('z_uwucafe:server:beginCraft', false, recipeId, stationId)
    if not preparation or not preparation.success then
        lib.notify({ title = Config.JobLabel, description = preparation and preparation.message or 'Crafting could not start.', type = 'error' })
        return
    end
    local passed = lib.skillCheck(preparation.difficulty, {'w', 'a', 's', 'd'})
    if not passed then
        lib.notify({ title = Config.JobLabel, description = 'You failed the preparation.', type = 'error' })
        return
    end
    local completed = lib.progressCircle({
        duration = preparation.duration,
        label = preparation.label,
        position = 'bottom',
        canCancel = true,
        useWhileDead = false,
        disable = { move = true, car = true, combat = true },
        anim = stationAnimations[station.station]
    })
    if not completed then return end
    local response = lib.callback.await('z_uwucafe:server:completeCraft', false, preparation.token)
    if not response then return end
    lib.notify({
        title = Config.JobLabel,
        description = response.success and ('%s Quality: %s.'):format(response.message, response.quality or 'Normal') or response.message,
        type = response.success and 'success' or 'error'
    })
end

RegisterNetEvent('z_uwucafe:client:openStation', function(stationId)
    local station = stationLookup[stationId]
    if not station then return end
    local stats = lib.callback.await('z_uwucafe:server:getMyStats', false) or { skills = {} }
    local options = {}
    for recipeId, recipeEntry in pairs(Config.Recipes) do
        local recipe = recipeEntry
        if recipe.station == station.station then
            local skill = stats.skills and stats.skills[recipe.skill or 'cooking'] or { level = 1 }
            local locked = recipe.minimumLevel and skill.level < recipe.minimumLevel
            options[#options + 1] = {
                title = recipe.label,
                description = ingredientDescription(recipe.ingredients),
                icon = locked and 'lock' or 'utensils',
                disabled = locked,
                metadata = {
                    { label = 'Result', value = ('%sx %s'):format(recipe.result.amount, recipe.result.item) },
                    { label = 'Skill', value = recipe.skill or 'cooking' },
                    { label = 'Required level', value = recipe.minimumLevel or 1 },
                    { label = 'Required reputation', value = recipe.minimumReputation or 0 }
                },
                onSelect = function() beginCraft(recipeId, stationId) end
            }
        end
    end
    table.sort(options, function(a, b) return a.title < b.title end)
    local contextId = ('z_uwucafe_station_menu_%s'):format(stationId)
    lib.registerContext({ id = contextId, title = station.label, options = options })
    lib.showContext(contextId)
end)
