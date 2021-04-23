local ldir = require('dir')
local lookup = require('lookup')

local paramsMeta = {
    __newindex = function(self, key, value)
        rawset(self, #self + 1, key)
        rawset(self, key, value)
    end,
}

function addStats(params, key, stats)
    local attributes = {}
    local lookup_param = lookup.param

    for attribute in pairs(stats) do
        table.insert(attributes, attribute)
    end

    table.sort(attributes)

    for _, attribute in ipairs(attributes) do
        params[key .. lookup_param[attribute]] = tonumber(stats[attribute][1])
    end
end

function getParams(id, platform, data)
    local params = setmetatable({}, paramsMeta)

    data:expand()

    local position = data.Role

    if position then
        params.position = position[1]:gsub('^%l', string.upper)
    end

    local roles = data.RoleExtended

    if roles then
        local roles = roles[1]
        local lookup_role = lookup.role

        if type(roles) == 'table' then
            for i = 2, #roles do
                params['role' .. i - 1] = lookup_role[roles[i]]
            end
        else
            params.role1 = lookup_role[roles]
        end
    end

    params.stone_source1 = '[[FILL ME IN OR DELETE ME]]'
    params.stone_source2 = '[[FILL ME IN OR DELETE ME]]'

    local main_stat = data.MainStat

    if main_stat then
        params.main_stat = main_stat[1]
    end

    local skins = data.Skin

    if skins then
        local skins = skins[1]
        local lookup_skin = lookup.skin
        local lookup_attribute = lookup.attribute

        if type(skins) == 'table' then
            for i = 3, #skins do
                local key = 'skin' .. i - 2
                local skin = lookup_skin[skins[i]][platform]

                if skin and skin.IsEnabled[1] then
                    local stats = skin.StatData

                    stats:expand()
                    stats = stats[#stats][1]

                    params[key] = skin.text
                    params[key .. '_attribute'] = lookup_attribute[stats[8]]
                    params[key .. '_value'] = tonumber(stats[9])
                end
            end
        else
            -- only the default skin, do nothing
        end
    end

    local glyphs = data.Runes

    if glyphs then
        local glyphs = glyphs[1]
        local lookup_attribute = lookup.attribute

        for i = 2, #glyphs - 1 do
            params['glyph' .. i - 1] = lookup_attribute[glyphs[i]]
        end
    end

    local artifacts = data.Artifacts

    if artifacts then
        local artifacts = artifacts[1]
        local lookup_attribute = lookup.attribute
        local lookup_artifact_hero = lookup.artifact.hero

        local weapon = lookup_artifact_hero[artifacts[2]][platform]
        local book = lookup_artifact_hero[artifacts[3]][platform]

        if weapon then
            local key = 'artifact_' .. weapon.Type[1]

            params[key] = weapon.name

            for idx, effect in ipairs(weapon.BattleEffect) do
                for attribute, value in pairs(effect) do
                    value:expand()
                    value = value[100] -- browser list goes to 130???

                    params[key .. '_attribute'] = lookup_attribute[attribute]
                    params[key .. '_value'] = tonumber(value[1])
                end
            end
        end

        if book then
            local key = 'artifact_' .. book.Type[1]

            params[key] = book.name
        end
    end

    local base_stats = data.BaseStats

    if base_stats then
        addStats(params, 'base_', base_stats)
    end

    local stars = data.Stars

    if stars then
        local star = tonumber(data.Other.MinStar[1])
        local stats = stars[star]

        params.star = star

        while stats do
            addStats(params, string.format('star%d_', star), stats)

            star = star + 1
            stats = stars[star]
        end
    end

    return params
end

 -- |browser_skill_white_name = Crystal of Selias
 -- |browser_skill_white_prime_level = 40
 -- |browser_skill_white_format = 
-- A light flash strikes at the center of the enemy team and deals damage to all enemies around the point of impact.
 -- |browser_skill_green_name = Crystalline Onslaught
 -- |browser_skill_green_cooldown = 16
 -- |browser_skill_green_duration = 3
 -- |browser_skill_green_prime_level = 25
 -- |browser_skill_green_format = 
-- Stuns and damages a nearby target. (Stun chance lowered if the target's level is above %level%.)
 -- |browser_skill_blue_name = Piercing Light
 -- |browser_skill_blue_cooldown = 19.5
 -- |browser_skill_blue_prime_level = 35
 -- |browser_skill_blue_prime_base = -600
 -- |browser_skill_blue_format = 
-- Casts a spark of light which deals damage to all rivals in its way.
 -- |browser_skill_violet_name = Rainbow Halo
 -- |browser_skill_violet_secondary_base = 20
 -- |browser_skill_violet_format = 
-- Passive skill. The shield partially absorbs magic damage. After absorbing a certain amount of damage, the shield explodes, damaging nearby enemies.
-- The shield absorbs %secondary%% of magic damage
 -- |browser_white0_1 = White/Orcish Knuckles
 -- |browser_white0_2 = White/Apprentice's Mantle
 -- |browser_white0_3 = White/Giant's Belt
 -- |browser_white0_4 = White/Wooden Shield
 -- |browser_white0_5 = White/Imperial Shield
 -- |browser_white0_6 = White/Oil Lamp
 -- |browser_green0_1 = White/Giant's Belt
 -- |browser_green0_2 = White/Apprentice's Mantle
 -- |browser_green0_3 = White/Sledgehammer
 -- |browser_green0_4 = White/Orcish Hammer
 -- |browser_green0_5 = Green/Fire Sword
 -- |browser_green0_6 = Green/Cuirass
 -- |browser_green1_1 = White/Imperial Shield
 -- |browser_green1_2 = White/Wizard's Staff
 -- |browser_green1_3 = Green/Cuirass
 -- |browser_green1_4 = Green/Cain's Seal
 -- |browser_green1_5 = Green/Screaming Blade
 -- |browser_green1_6 = Green/Soul Catcher
 -- |browser_blue0_1 = Green/Midnight Crystal
 -- |browser_blue0_2 = Green/Wall-Breaker
 -- |browser_blue0_3 = Green/Soul Catcher
 -- |browser_blue0_4 = Green/Silent Guardian
 -- |browser_blue0_5 = Blue/Sacred Rosary
 -- |browser_blue0_6 = Blue/Enchanted Lute
 -- |browser_blue1_1 = Green/Midnight Crystal
 -- |browser_blue1_2 = Green/Wall-Breaker
 -- |browser_blue1_3 = Green/Soul Catcher
 -- |browser_blue1_4 = Blue/Dragon's Heart
 -- |browser_blue1_5 = Blue/Portal Gem
 -- |browser_blue1_6 = Blue/Voodoo Staff
 -- |browser_blue2_1 = Green/Poleaxe
 -- |browser_blue2_2 = Green/Voodoo Doll
 -- |browser_blue2_3 = Blue/Dragon's Heart
 -- |browser_blue2_4 = Blue/Portal Gem
 -- |browser_blue2_5 = Blue/Voodoo Staff
 -- |browser_blue2_6 = Blue/Hand of Midas
 -- |browser_violet0_1 = Blue/Dragon's Heart
 -- |browser_violet0_2 = Blue/Portal Gem
 -- |browser_violet0_3 = Blue/Voodoo Staff
 -- |browser_violet0_4 = Blue/Globus Cruciger
 -- |browser_violet0_5 = Violet/Pastor's Seal
 -- |browser_violet0_6 = Violet/Minotaur's Head
 -- |browser_violet1_1 = Blue/Enchanted Lute
 -- |browser_violet1_2 = Blue/Branch of the World Tree
 -- |browser_violet1_3 = Blue/Prince of Thieves' Armor
 -- |browser_violet1_4 = Violet/Flaming Heart
 -- |browser_violet1_5 = Violet/Funeral Totem
 -- |browser_violet1_6 = Violet/Book of Tales
 -- |browser_violet2_1 = Blue/Voodoo Staff
 -- |browser_violet2_2 = Blue/Voodoo Staff
 -- |browser_violet2_3 = Blue/Hand of Midas
 -- |browser_violet2_4 = Violet/Primordial Word
 -- |browser_violet2_5 = Violet/Trine
 -- |browser_violet2_6 = Violet/Book of Prophecies
 -- |browser_violet3_1 = Blue/Voodoo Staff
 -- |browser_violet3_2 = Blue/Globus Cruciger
 -- |browser_violet3_3 = Violet/Primordial Word
 -- |browser_violet3_4 = Violet/Elephant Guard
 -- |browser_violet3_5 = Violet/Book of Prophecies
 -- |browser_violet3_6 = Violet/Cosmic Tremor
 -- |browser_orange0_1 = Violet/Trine
 -- |browser_orange0_2 = Violet/All-seer
 -- |browser_orange0_3 = Violet/Executioner's Sword
 -- |browser_orange0_4 = Violet/Book of Prophecies
 -- |browser_orange0_5 = Orange/Harunian Helm
 -- |browser_orange0_6 = Orange/Enchanted Chain
 -- |browser_orange1_1 = Violet/Elephant Guard
 -- |browser_orange1_2 = Violet/Trine
 -- |browser_orange1_3 = Violet/Book of Prophecies
 -- |browser_orange1_4 = Orange/Harunian Helm
 -- |browser_orange1_5 = Orange/Thieves Guild Sign
 -- |browser_orange1_6 = Orange/Staff of Neutralization
 -- |browser_orange2_1 = Violet/Talisman
 -- |browser_orange2_2 = Violet/Executioner's Sword
 -- |browser_orange2_3 = Orange/Enchanted Chain
 -- |browser_orange2_4 = Orange/La Mort's Card
 -- |browser_orange2_5 = Orange/Trickster's Cane
 -- |browser_orange2_6 = Orange/Shining Armor
 -- |browser_orange3_1 = Violet/Talisman
 -- |browser_orange3_2 = Violet/Executioner's Sword
 -- |browser_orange3_3 = Orange/Enchanted Chain
 -- |browser_orange3_4 = Orange/Trickster's Cane
 -- |browser_orange3_5 = Orange/Oracle's Censer
 -- |browser_orange3_6 = Orange/Oppressor's Crown
 -- |browser_orange4_1 = Violet/Executioner's Sword
 -- |browser_orange4_2 = Violet/Apostle's Mace
 -- |browser_orange4_3 = Orange/Trickster's Cane
 -- |browser_orange4_4 = Orange/Staff of Neutralization
 -- |browser_orange4_5 = Orange/Oppressor's Crown
 -- |browser_orange4_6 = Orange/Evil Genius Cuirass
 -- |browser_red0_1 = Orange/Evil Genius Cuirass
 -- |browser_red0_2 = Orange/Oracle's Censer
 -- |browser_red0_3 = Orange/Asklepius' Staff
 -- |browser_red0_4 = Orange/Shining Armor
 -- |browser_red0_5 = Red/Jarugardi's Sneer
 -- |browser_red0_6 = Red/Aigrette of Nocturnal Cicadas
 -- |browser_red1_1 = Orange/Evil Genius Cuirass
 -- |browser_red1_2 = Orange/Asklepius' Staff
 -- |browser_red1_3 = Orange/Trickster's Cane
 -- |browser_red1_4 = Red/Echidna's Dark Hex
 -- |browser_red1_5 = Red/Andvari's Fortitude Support
 -- |browser_red1_6 = Red/Piercing Gaze
 -- |browser_red2_1 = Orange/Trickster's Cane
 -- |browser_red2_2 = Orange/Alucard's Amulet
 -- |browser_red2_3 = Red/Echidna's Dark Hex
 -- |browser_red2_4 = Red/Dragon's Heart
 -- |browser_red2_5 = Red/Piercing Gaze
 -- |browser_red2_6 = Red/Demigod's Wreath

local chooseDescription = {
    ['Orion'] = 'mobile',
    ['Ginger'] = 'browser',
    ['Cornelius'] = 'browser',
    ['Jorgen'] = 'browser',
    ['Jhu'] = 'browser',
    ['Satori'] = 'browser',
}

function generateHero(dest, id, data)
    local output = {}
    local browser = data.browser
    local mobile = data.mobile
    local ndata = browser or mobile
    local name, description = ndata.name

    if browser and mobile and browser.description ~= mobile.description then
        local platform = chooseDescription[name]

        if not platform then
            error(string.format('\nHero:\t%s (%d)\nBrowser:\t%s\nMobile:\t%s', name, id, browser.description, mobile.description))
        end

        description = data[platform].description
    else
        description = ndata.description
    end

    description = description:gsub('%%(%w+)%%', {param1 = name})

    for _, platform in ipairs{'browser', 'mobile'} do -- ensure order
        local data = data[platform]

        if data then
            local params = getParams(id, platform, data)
            local data = {}
            local prefix = ' |' .. platform .. '_'

            for idx, key in ipairs(params) do
                data[idx] = string.format('%s%s = %s', prefix, key, params[key])
            end

            table.insert(output, table.concat(data, '\n'))
        end
    end

 -- |flavor = As a child Aurora chose to follow the Light. She left her house and went a long way to finally receive the title of Paladin of Riversar, thus becoming a protector and a lantern for her people.
 
    if #output > 0 then
        table.insert(output, 1, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Hero/Lua</noinclude>')
        table.insert(output, 2, ' |id = ' .. id)
        table.insert(output, 3, ' |flavor = ' .. description)
        table.insert(output, '}}</onlyinclude>')

        output = table.concat(output, '\n')

        print(output)

        -- local file = io.open(table.concat{dest, '/', name, '.txt'}, 'w')

        -- if file then
            -- file:write(output)
            -- file:close()
        -- end
    end
end

do
    local dest = 'dest/hero'
    local src = {
        browser = 'src/Proto/Hero',
        mobile = 'src/Mobile/Proto/Hero',
    }
    local lookup = lookup.hero
    local heroes = setmetatable({}, {
        __index = function(self, key)
            local data = {}

            self[key] = data

            return data
        end,
    })
    ldir:mkdir(dest)

    for platform, src in pairs(src) do
        for file in ldir:mode(src, 'file') do
            local id = tonumber(file:match('/([0-9]+).proto$'))

            if id then
                heroes[id][platform] = lookup[id][platform]
            end
        end
    end

    for id, data in pairs(heroes) do
        local browser = data.browser
        local mobile = data.mobile

        if browser then
            if mobile then
                if browser.name == mobile.name then
                    generateHero(dest, id, data)
                else
                    generateHero(dest, id, {browser = browser})
                    generateHero(dest, id, {mobile = mobile})
                end
            else
                generateHero(dest, id, {browser = browser})
            end
        else
            generateHero(dest, id, {mobile = mobile})
        end

        break
    end
end