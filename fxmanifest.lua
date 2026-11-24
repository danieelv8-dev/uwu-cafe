shared_script '@ElectronAC/src/include/shared.lua'
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'z_uwucafe'
author 'zScripts'
description 'Complete advanced UwU Cat Cafe job for ESX and the ox ecosystem'
version '2.0.9'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/pl.lua',
    'shared/products.lua',
    'shared/recipes.lua',
    'shared/contracts.lua'
}

client_scripts {
    'client/main.lua',
    'client/duty.lua',
    'client/crafting.lua',
    'client/orders.lua',
    'client/logistics.lua',
    'client/npc.lua',
    'client/consumables.lua',
    'client/wardrobe.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/progression.lua',
    'server/business.lua',
    'server/equipment.lua',
    'server/orders.lua',
    'server/logistics.lua',
    'server/npc.lua',
    'server/management.lua',
    'server/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/uwu-cafe-logo.png'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql'
}
