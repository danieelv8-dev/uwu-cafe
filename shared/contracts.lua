Config.CateringTemplates = {
    office_lunch = {
        label = 'Office Lunch Package',
        description = 'A balanced lunch order for a local office.',
        minimumReputation = 0,
        reward = { min = 900, max = 1250 },
        items = { uwu_burger = 8, uwu_fries = 8, uwu_coffee = 6 }
    },
    emergency_shift = {
        label = 'Emergency Services Night Shift',
        description = 'A large late-shift order for emergency workers.',
        minimumReputation = 50,
        reward = { min = 1500, max = 2100 },
        items = { uwu_deluxe_burger = 10, uwu_fries = 10, uwu_latte = 10, uwu_cat_cookie = 10 }
    },
    city_event = {
        label = 'City Community Event',
        description = 'Desserts and drinks for a public city event.',
        minimumReputation = 150,
        reward = { min = 2200, max = 3200 },
        items = { uwu_cupcake = 15, uwu_strawberry_cake = 10, uwu_boba = 12, uwu_matcha_latte = 12 }
    },
    premium_reception = {
        label = 'Premium Reception',
        description = 'Premium menu service for an exclusive reception.',
        minimumReputation = 350,
        reward = { min = 4000, max = 5500 },
        items = { uwu_salmon_bowl = 12, uwu_chocolate_parfait = 12, uwu_peach_tea = 12 }
    }
}
