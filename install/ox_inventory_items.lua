-- Paste these entries inside ox_inventory/data/items.lua.
-- Product items use the custom z_uwucafe.consume export so quality and freshness metadata affect consumption.

['uwu_bun'] = { label = 'Burger Bun', weight = 100, stack = true, close = true },
['uwu_raw_patty'] = { label = 'Raw Burger Patty', weight = 180, stack = true, close = true },
['uwu_cooked_patty'] = { label = 'Cooked Burger Patty', weight = 160, stack = true, close = true },
['uwu_cheese'] = { label = 'Cheese Slice', weight = 40, stack = true, close = true },
['uwu_lettuce'] = { label = 'Fresh Lettuce', weight = 80, stack = true, close = true },
['uwu_sliced_vegetables'] = { label = 'Prepared Vegetables', weight = 70, stack = true, close = true },
['uwu_signature_sauce'] = { label = 'UwU Signature Sauce', weight = 80, stack = true, close = true },
['uwu_potato'] = { label = 'Potato', weight = 120, stack = true, close = true },
['uwu_cup'] = { label = 'UwU Cup', weight = 20, stack = true, close = true },
['uwu_coffee_beans'] = { label = 'Coffee Beans', weight = 50, stack = true, close = true },
['uwu_milk'] = { label = 'Fresh Milk', weight = 250, stack = true, close = true },
['uwu_matcha'] = { label = 'Matcha Powder', weight = 50, stack = true, close = true },
['uwu_strawberries'] = { label = 'Strawberries', weight = 90, stack = true, close = true },
['uwu_boba_pearls'] = { label = 'Boba Pearls', weight = 80, stack = true, close = true },
['uwu_dough'] = { label = 'Pastry Dough', weight = 150, stack = true, close = true },
['uwu_flour'] = { label = 'Flour', weight = 150, stack = true, close = true },
['uwu_sugar'] = { label = 'Sugar', weight = 80, stack = true, close = true },
['uwu_egg'] = { label = 'Egg', weight = 60, stack = true, close = true },
['uwu_chocolate'] = { label = 'Chocolate', weight = 80, stack = true, close = true },
['uwu_food_box'] = { label = 'Food Box', weight = 30, stack = true, close = true },
['uwu_vanilla'] = { label = 'Vanilla', weight = 40, stack = true, close = true },
['uwu_salmon'] = { label = 'Fresh Salmon', weight = 220, stack = true, close = true },
['uwu_rice'] = { label = 'Sushi Rice', weight = 120, stack = true, close = true },
['uwu_nori'] = { label = 'Nori Sheet', weight = 20, stack = true, close = true },
['uwu_avocado'] = { label = 'Avocado', weight = 130, stack = true, close = true },
['uwu_peach'] = { label = 'Peach', weight = 100, stack = true, close = true },
['uwu_cream'] = { label = 'Fresh Cream', weight = 180, stack = true, close = true },

['uwu_burger'] = {
    label = 'UwU Burger', weight = 350, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 2500 }
},
['uwu_deluxe_burger'] = {
    label = 'Deluxe Neko Burger', weight = 500, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 3000 }
},
['uwu_fries'] = {
    label = 'Neko Fries', weight = 220, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 2200 }
},
['uwu_salmon_bowl'] = {
    label = 'Sakura Salmon Bowl', weight = 450, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 3000 }
},
['uwu_cat_cookie'] = {
    label = 'Cat Cookie', weight = 90, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 1800 }
},
['uwu_cupcake'] = {
    label = 'Pink Paw Cupcake', weight = 140, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 2000 }
},
['uwu_strawberry_cake'] = {
    label = 'Strawberry Cake', weight = 180, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 2200 }
},
['uwu_chocolate_parfait'] = {
    label = 'Neko Chocolate Parfait', weight = 220, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = 'eating', prop = 'burger', usetime = 2400 }
},
['uwu_coffee'] = {
    label = 'Neko Coffee', weight = 220, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 }
},
['uwu_latte'] = {
    label = 'Paw Latte', weight = 250, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 }
},
['uwu_matcha_latte'] = {
    label = 'Matcha Latte', weight = 250, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2500 }
},
['uwu_boba'] = {
    label = 'Brown Sugar Boba', weight = 280, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_cs_paper_cup`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2700 }
},
['uwu_strawberry_milkshake'] = {
    label = 'Strawberry Milkshake', weight = 300, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_cs_paper_cup`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2700 }
},
['uwu_peach_tea'] = {
    label = 'Sakura Peach Tea', weight = 260, stack = true, close = true,
    client = { export = 'z_uwucafe.consume', anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' }, prop = { model = `prop_cs_paper_cup`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) }, usetime = 2600 }
},
['uwu_packaged_meal'] = { label = 'Packaged UwU Meal', weight = 650, stack = true, close = true }
