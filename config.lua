Config = {}

Config.Version = '2.0.9'
Config.Debug = false
Config.Locale = 'en'
Config.JobName = 'uwucafe'
Config.JobLabel = 'UwU Cat Cafe'
Config.DefaultPaymentAccount = 'bank'
Config.InteractionDistance = 2.0
Config.ServerValidationDistance = 5.0
Config.OrderRetentionDays = 30

Config.Features = {
    npcCustomers = true,
    customerDelivery = true,
    tableService = true,
    catering = true,
    promotions = true,
    equipment = true,
    reputation = true,
    businessUpgrades = true,
    uniforms = true,
    employeeBlips = true,
    payroll = true
}

Config.Webhooks = {
    enabled = false,
    duty = '',
    orders = '',
    management = '',
    security = '',
    deliveries = ''
}

Config.Grades = {
    trainee = 0,
    employee = 1,
    senior = 2,
    supervisor = 3,
    manager = 4,
    owner = 5
}

-- Tablet pages and actions are controlled independently by job grade.
-- Change only the numbers below to customise access without editing the UI or server code.
Config.TabletAccess = {
    defaultPage = 'orders',

    pages = {
        orders = Config.Grades.trainee,
        deliveries = Config.Grades.trainee,
        register = Config.Grades.employee,
        catering = Config.Grades.employee,
        supplies = Config.Grades.senior,
        stock = Config.Grades.trainee,
        profile = Config.Grades.trainee,
        business = Config.Grades.supervisor,
        equipment = Config.Grades.supervisor,
        promotions = Config.Grades.manager,
        staff = Config.Grades.manager
    },

    actions = {
        updateOrder = Config.Grades.trainee,
        cancelReadyOrder = Config.Grades.supervisor,
        acceptDelivery = Config.Grades.trainee,
        createRegisterOrder = Config.Grades.employee,
        acceptCatering = Config.Grades.employee,
        startCateringDelivery = Config.Grades.employee,
        startSupplyRun = Config.Grades.senior,
        depositBusiness = Config.Grades.supervisor,
        withdrawBusiness = Config.Grades.owner,
        repairEquipment = Config.Grades.supervisor,
        upgradeEquipment = Config.Grades.manager,
        createPromotion = Config.Grades.manager,
        disablePromotion = Config.Grades.manager,
        employeeAction = Config.Grades.manager,
        buyBusinessUpgrade = Config.Grades.owner
    },

    -- Internal page relationship used by both the NUI and server validation.
    actionPages = {
        updateOrder = 'orders',
        cancelReadyOrder = 'orders',
        acceptDelivery = 'deliveries',
        createRegisterOrder = 'register',
        acceptCatering = 'catering',
        startCateringDelivery = 'catering',
        startSupplyRun = 'supplies',
        depositBusiness = 'business',
        withdrawBusiness = 'business',
        repairEquipment = 'equipment',
        upgradeEquipment = 'equipment',
        createPromotion = 'promotions',
        disablePromotion = 'promotions',
        employeeAction = 'staff',
        buyBusinessUpgrade = 'business'
    }
}

Config.Security = {
    craftRateLimitMs = 1200,
    orderRateLimitMs = 1500,
    actionRateLimitMs = 800,
    craftTokenLifetimeSeconds = 90,
    minimumCraftElapsedPercent = 0.75,
    maxNotesLength = 250,
    maxOrderQuantityPerItem = 10,
    maxOrderLineCount = 20,
    maxOrderValue = 10000,
    maxManagementAmount = 1000000
}

Config.Duty = {
    afkMinutes = 25,
    movementThreshold = 2.0,
    checkIntervalSeconds = 60,
    minimumPaidMinutes = 5,
    maximumPaidHoursPerSession = 10,
    payOnClockOut = true,
    hourlyWages = {
        [0] = 110,
        [1] = 150,
        [2] = 190,
        [3] = 230,
        [4] = 275,
        [5] = 325
    }
}

Config.Progression = {
    generalXp = {
        craft = 3,
        order = 12,
        tableService = 8,
        customerDelivery = 25,
        supplyDelivery = 25,
        catering = 40,
        cleaning = 2,
        management = 5
    },
    skillXp = {
        craft = 5,
        order = 6,
        tableService = 8,
        customerDelivery = 12,
        supplyDelivery = 10,
        catering = 15,
        cleaning = 3,
        management = 5
    },
    levelBase = 100,
    levelMultiplier = 1.35,
    maxLevel = 50,
    skillLevelBase = 75,
    skillLevelMultiplier = 1.28,
    maxSkillLevel = 25
}

Config.Ordering = {
    terminalServiceFee = 0,
    tableServiceFee = 8,
    deliveryFee = 35,
    deliveryEmployeeBonus = 20,
    deliveryTimeoutMinutes = 20,
    readyExpiryMinutes = 45,
    customerCollectionDistance = 5.0,
    tableServiceDistance = 5.0,
    deliveryCompletionDistance = 18.0,
    allowCustomerCancellationBeforeAccepted = true,
    refundOnCancellation = true,
    tipMaximumPercent = 50,
    pickupCounter = vec3(-584.10, -1059.55, 22.34)
}

Config.Business = {
    maxCleanliness = 100,
    minCleanliness = 0,
    cleanlinessLossPerOrder = 1,
    cleanlinessLossPerNpcOrder = 2,
    cleaningReward = 6,
    lowCleanlinessThreshold = 35,
    inspectionThreshold = 20,
    inspectionPenalty = 300,
    inspectionChancePercent = 20,
    inspectionCooldownMinutes = 120,
    reputationPerCompletedOrder = 1,
    reputationPerPerfectOrder = 2,
    reputationLossCancelledNpc = 1
}

Config.ReputationLevels = {
    { level = 1, name = 'Local Spot', required = 0, priceMultiplier = 1.00, npcMultiplier = 1.00 },
    { level = 2, name = 'Popular Cafe', required = 50, priceMultiplier = 1.02, npcMultiplier = 1.15 },
    { level = 3, name = 'City Favourite', required = 150, priceMultiplier = 1.05, npcMultiplier = 1.30 },
    { level = 4, name = 'Neko Landmark', required = 350, priceMultiplier = 1.08, npcMultiplier = 1.50 },
    { level = 5, name = 'Legendary Cafe', required = 700, priceMultiplier = 1.12, npcMultiplier = 1.75 }
}

Config.Locations = {
    duty = vec3(-587.7647, -1051.4036, 22.3442),
    wardrobe = vec3(-586.5867, -1049.9358, 22.3442),
    employeeTablet = vec3(-587.13, -1052.54, 22.34),
    register = vec3(-584.04, -1058.70, 22.34),
    customerTerminal = vec3(-584.10, -1061.42, 22.34),
    stock = vec3(-590.85, -1068.10, 22.34),
    management = vec3(-578.61, -1067.24, 26.61),
    deliveryReturn = vec3(-599.62, -1059.22, 21.74),
    cateringDispatch = vec3(0, 0, 0)
}

Config.Zones = {
    duty = { size = vec3(0.8, 0.8, 1.8), rotation = 0.0 },
    wardrobe = { size = vec3(0.8, 0.8, 1.8), rotation = 0.0 },
    employeeTablet = { size = vec3(0.9, 0.9, 1.8), rotation = 0.0 },
    register = { size = vec3(0.8, 0.8, 1.5), rotation = 0.0 },
    customerTerminal = { size = vec3(1.0, 1.0, 1.8), rotation = 0.0 },
    stock = { size = vec3(1.2, 1.2, 1.8), rotation = 0.0 },
    management = { size = vec3(1.0, 1.0, 1.8), rotation = 0.0 },
    pickupCounter = { size = vec3(1.0, 1.0, 1.6), rotation = 0.0 }
}

Config.Stock = {
    stashId = 'z_uwucafe_stock',
    label = 'UwU Cafe Ingredient Storage',
    slots = 140,
    weight = 400000,
    minimumGrade = 0,
    lowStock = {
        uwu_bun = 10,
        uwu_raw_patty = 10,
        uwu_cheese = 10,
        uwu_lettuce = 10,
        uwu_potato = 10,
        uwu_cup = 15,
        uwu_coffee_beans = 10,
        uwu_milk = 10,
        uwu_flour = 10,
        uwu_sugar = 10,
        uwu_egg = 10,
        uwu_food_box = 10
    }
}

Config.Stations = {
    { id = 'prep_1', label = 'Preparation Counter', station = 'prep', equipment = 'prep_counter', coords = vec3(-590.95, -1063.11, 22.36), size = vec3(1.4, 0.8, 1.4), rotation = 0.0, icon = 'fa-solid fa-kitchen-set' },
    { id = 'grill_1', label = 'Grill', station = 'grill', equipment = 'grill', coords = vec3(-590.35, -1056.52, 22.36), size = vec3(1.2, 0.8, 1.4), rotation = 0.0, icon = 'fa-solid fa-fire-burner' },
    { id = 'fryer_1', label = 'Fryer', station = 'fryer', equipment = 'fryer', coords = vec3(-591.02, -1056.50, 22.36), size = vec3(0.8, 0.8, 1.4), rotation = 0.0, icon = 'fa-solid fa-fire-flame-simple' },
    { id = 'assembly_1', label = 'Assembly Counter', station = 'assembly', equipment = 'assembly_counter', coords = vec3(-591.18, -1061.53, 22.36), size = vec3(1.5, 0.8, 1.4), rotation = 0.0, icon = 'fa-solid fa-burger' },
    { id = 'drinks_1', label = 'Drink Station', station = 'drinks', equipment = 'coffee_machine', coords = vec3(-586.80, -1061.92, 22.34), size = vec3(1.8, 0.8, 1.5), rotation = 0.0, icon = 'fa-solid fa-mug-hot' },
    { id = 'dessert_1', label = 'Dessert Oven', station = 'dessert', equipment = 'oven', coords = vec3(-590.2808, -1059.5938, 22.3442), size = vec3(1.2, 0.8, 1.5), rotation = 0.0, icon = 'fa-solid fa-cake-candles' },
    { id = 'packaging_1', label = 'Packaging Counter', station = 'packaging', equipment = 'packaging_counter', coords = vec3(-588.1252, -1057.7749, 22.1735), size = vec3(1.2, 0.8, 1.5), rotation = 0.0, icon = 'fa-solid fa-box' }
}

Config.Equipment = {
    maxLevel = 4,
    maxCondition = 100,
    minimumConditionToUse = 5,
    degradationPerCraft = { min = 1, max = 3 },
    repairBaseCost = 180,
    upgradeCosts = { [2] = 1200, [3] = 2500, [4] = 5000 },
    speedMultiplier = { [1] = 1.00, [2] = 0.90, [3] = 0.80, [4] = 0.70 },
    qualityBonus = { [1] = 0, [2] = 4, [3] = 8, [4] = 12 }
}

Config.CleaningSpots = {
    { id = 'floor_1', label = 'Mop Kitchen Floor', coords = vec3(-584.8342, -1056.5077, 22.3442), scenario = 'WORLD_HUMAN_JANITOR' },
    { id = 'tables_1', label = 'Clean Dining Tables', coords = vec3(-573.73, -1059.78, 22.34), scenario = 'WORLD_HUMAN_MAID_CLEAN' },
    { id = 'bins_1', label = 'Empty Bins', coords = vec3(-589.62, -1069.20, 22.34), scenario = 'PROP_HUMAN_BUM_BIN' },
    { id = 'dishes_1', label = 'Wash Dishes', coords = vec3(-588.5750, -1062.0743, 22.3516), scenario = 'PROP_HUMAN_BUM_BIN' }
}

Config.Tables = {
    { number = 1, coords = vec3(-573.55, -1059.78, 22.34), size = vec3(1.8, 1.8, 1.5) },
    { number = 2, coords = vec3(-573.64, -1063.14, 22.34), size = vec3(1.8, 1.8, 1.5) },
    { number = 3, coords = vec3(-576.25, -1063.09, 22.34), size = vec3(1.8, 1.8, 1.5) },
    { number = 4, coords = vec3(-576.36, -1059.77, 22.34), size = vec3(1.8, 1.8, 1.5) },
    { number = 5, coords = vec3(-578.90, -1059.76, 22.34), size = vec3(1.8, 1.8, 1.5) },
    { number = 6, coords = vec3(-578.92, -1063.06, 22.34), size = vec3(1.8, 1.8, 1.5) }
}

Config.SupplyDelivery = {
    vehicleModel = 'speedo',
    vehicleSpawn = vec4(-600.39, -1059.88, 21.49, 90.0),
    supplier = vec3(1200.52, -1276.77, 35.23),
    pickupDistance = 5.0,
    returnDistance = 7.0,
    timeoutMinutes = 25,
    damagePenaltyMaximum = 300
}

Config.CustomerDelivery = {
    vehicleModel = 'faggio',
    vehicleSpawn = vec4(-600.39, -1059.88, 21.49, 90.0),
    minimumGrade = 0,
    requireCafeVehicle = false
}

Config.SupplyPacks = {
    basic = { label = 'Basic Ingredient Pack', description = 'Burger ingredients, potatoes and packaging.', cost = 700, minimumGrade = 2, minimumReputation = 0, items = { uwu_bun = 30, uwu_raw_patty = 30, uwu_cheese = 30, uwu_lettuce = 30, uwu_potato = 40, uwu_food_box = 30, uwu_signature_sauce = 20 } },
    drinks = { label = 'Drink Supply Pack', description = 'Coffee, milk, matcha, fruit and cups.', cost = 550, minimumGrade = 2, minimumReputation = 0, items = { uwu_cup = 50, uwu_coffee_beans = 35, uwu_milk = 40, uwu_matcha = 25, uwu_strawberries = 30, uwu_boba_pearls = 30 } },
    bakery = { label = 'Bakery Supply Pack', description = 'Dough, flour, sugar, eggs and chocolate.', cost = 600, minimumGrade = 2, minimumReputation = 25, items = { uwu_dough = 35, uwu_flour = 35, uwu_sugar = 35, uwu_egg = 30, uwu_chocolate = 25, uwu_vanilla = 20 } },
    premium = { label = 'Premium Ingredient Pack', description = 'Premium seafood, fruit and specialty supplies.', cost = 1100, minimumGrade = 3, minimumReputation = 150, items = { uwu_salmon = 20, uwu_rice = 30, uwu_nori = 25, uwu_avocado = 20, uwu_peach = 25, uwu_cream = 25 } }
}

Config.NPC = {
    enabled = true,
    minimumOnDuty = 1,
    maximumActive = 3,
    spawnInterval = { min = 150, max = 300 },
    maximumWaitMinutes = 12,
    orderItemCount = { min = 1, max = 3 },
    models = { 'a_f_y_hipster_01', 'a_f_y_business_04', 'a_m_y_hipster_02', 'a_m_y_business_03', 'a_f_y_tourist_01' },
    spawn = vec4(-565.28, -1077.12, 22.33, 90.0),
    queue = vec4(-583.05, -1060.40, 22.34, 90.0),
    exit = vec4(-565.28, -1077.12, 22.33, 270.0),

    -- Controls what happens after an NPC receives an order or abandons the queue.
    departure = {
        enabled = true,              -- Set false to despawn immediately instead of walking away.
        walkToExit = true,           -- Makes the NPC walk to Config.NPC.exit before despawning.
        useNavMesh = true,           -- Recommended for navigating doors and the cafe interior.
        walkSpeed = 1.0,             -- Normal walking speed.
        arrivalDistance = 1.75,      -- Distance from the exit that counts as arrival.
        maxWalkTimeMs = 30000,       -- Force cleanup if the NPC becomes stuck.
        repathIntervalMs = 5000,     -- How often a stopped NPC retries the route.
        despawnDelayMs = 1000,       -- Delay after reaching the exit before deletion.
        fadeOut = true,              -- Smoothly fade the NPC before deletion.
        fadeDurationMs = 800
    },

    baseTipChance = 35,
    maxTip = 35
}

Config.Catering = {
    enabled = true,
    minimumGrade = 1,
    refreshMinutes = 30,
    maximumAvailable = 5,
    acceptanceTimeoutMinutes = 60,
    destinations = {
        { id = 'mrpd', label = 'Mission Row Police Department', coords = vec3(441.19, -981.93, 30.69) },
        { id = 'pillbox', label = 'Pillbox Medical Center', coords = vec3(306.72, -595.22, 43.28) },
        { id = 'cityhall', label = 'City Hall', coords = vec3(-544.17, -204.73, 38.22) },
        { id = 'mechanic', label = 'Los Santos Customs', coords = vec3(-337.12, -136.75, 39.01) },
        { id = 'beach', label = 'Vespucci Beach Event', coords = vec3(-1225.69, -1507.24, 4.35) }
    }
}

Config.BusinessUpgrades = {
    marketing = { label = 'Marketing Campaign', description = 'Increases NPC customer frequency and tips.', maxLevel = 3, costs = { [1] = 1500, [2] = 3500, [3] = 7000 } },
    service = { label = 'Service Training', description = 'Improves order reputation and customer ratings.', maxLevel = 3, costs = { [1] = 1200, [2] = 3000, [3] = 6000 } },
    logistics = { label = 'Logistics Program', description = 'Improves delivery bonuses and supply efficiency.', maxLevel = 3, costs = { [1] = 1400, [2] = 3200, [3] = 6500 } }
}

Config.Promotions = {
    maximumDiscountPercent = 40,
    maximumActive = 3,
    maximumDurationHours = 72,
    minimumGrade = 4
}

Config.Wardrobe = {
    enabled = true,
    male = {
        tshirt_1 = 15, tshirt_2 = 0, torso_1 = 241, torso_2 = 5,
        arms = 0, pants_1 = 28, pants_2 = 0, shoes_1 = 10, shoes_2 = 0,
        chain_1 = 0, chain_2 = 0, helmet_1 = -1, helmet_2 = 0
    },
    female = {
        tshirt_1 = 14, tshirt_2 = 0, torso_1 = 249, torso_2 = 5,
        arms = 0, pants_1 = 6, pants_2 = 0, shoes_1 = 6, shoes_2 = 0,
        chain_1 = 0, chain_2 = 0, helmet_1 = -1, helmet_2 = 0
    }
}

Config.Blips = {
    cafe = { enabled = true, coords = vec3(-581.02, -1066.32, 22.34), sprite = 106, colour = 8, scale = 0.75, label = 'UwU Cat Cafe' },
    employees = { enabled = true, sprite = 280, colour = 8, scale = 0.65 }
}
