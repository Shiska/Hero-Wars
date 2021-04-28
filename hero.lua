local ldir = require('dir')
local lookup = require('lookup')

local allKeys = {}
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

function getParams(platform, data)
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

    params.stone_source1 = ''
    params.stone_source2 = ''

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
            local idx = 1

            for i = 3, #skins do
                local key = 'skin' .. idx
                local skin = lookup_skin[skins[i]][platform]

                if skin and skin.IsEnabled[1] == 'True' then
                    local stats = skin.StatData

                    stats:expand()
                    stats = stats[#stats][1]

                    params[key .. '_name'] = skin.text
                    params[key .. '_attribute'] = lookup_attribute[stats[8]]
                    params[key .. '_value'] = tonumber(stats[9])

                    idx = idx + 1
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
                    params[key .. '_value'] = tonumber(value[1]) * 3
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

    local skills = data.Skill

    if skills then
        local skills = skills[1]
        local lookup_skill = lookup.skill
        local lookup_param = lookup.param
        local skill_color = lookup_skill.color
        local lookup_attribute = lookup.attribute
        local skill_attribute = lookup_skill.attribute
        -- basic attack
        do
            local skill = lookup_skill[skills[2]][platform]
            local prime = skill.Behavior.Prime

            if prime then
                local _, attribute, damageType = table.unpack(prime[1])

                params.basic_attack_attribute = lookup_attribute[skill_attribute[attribute]]
                params.basic_attack_damage_type = damageType
            end
        end
        -- skills
        for i = 3, #skills do
            local skill = lookup_skill[skills[i]][platform]

            if skill then
                local description = table.concat({'', skill.description, skill.param}, '\n')
                local key = 'skill_' .. skill_color[i - 2] .. '_'
                local behavior = skill.Behavior
                local keys = {
                    level = 10,
                    name = 10,
                }
                params[key .. 'name'] = skill.name

                local prime = behavior.Prime

                if prime then
                    local k, attribute, damageType, scale, level, base = table.unpack(prime[1])
                    local key = key .. k:lower() .. '_'

                    scale = tonumber(scale)
                    level = tonumber(level)
                    base = tonumber(base)

                    params[key .. 'attribute'] = lookup_attribute[skill_attribute[attribute]]
                    params[key .. 'damage_type'] = damageType

                    if scale ~= 0 then params[key .. 'scale'] = scale end
                    if level ~= 0 then params[key .. 'level'] = level end
                    if base  ~= 0 then params[key .. 'base'] = base end

                    keys.prime = 0
                end

                local secondary = behavior.Secondary

                if secondary then
                    local k, attribute, damageType, scale, level, base = table.unpack(secondary[1])
                    local key = key .. k:lower() .. '_'

                    scale = tonumber(scale)
                    level = tonumber(level)
                    base = tonumber(base)

                    params[key .. 'attribute'] = lookup_attribute[skill_attribute[attribute]]
                    params[key .. 'damage_type'] = damageType

                    if scale ~= 0 then params[key .. 'scale'] = scale end
                    if level ~= 0 then params[key .. 'level'] = level end
                    if base  ~= 0 then params[key .. 'base'] = base end

                    keys.secondary = 0
                end

                local duration = behavior.Duration

                if duration then
                    params[key .. 'duration'] = tonumber(duration[1])

                    keys.duration = 0
                end

                local initialCooldown = behavior.InitialCooldown

                if initialCooldown then
                    params[key .. 'initial_cooldown'] = tonumber(initialCooldown[1])

                    keys['initial cooldown'] = 0
                end

                local cooldown = behavior.Cooldown

                if cooldown then
                    params[key .. 'cooldown'] = tonumber(cooldown[1])

                    keys.cooldown = 0
                end

                local hits = behavior.Hits

                if hits then
                    params[key .. 'hits'] = tonumber(hits[1])

                    keys.hits = 0
                end

                description:gsub('%%(%w+)%%', function(key)
                    local count = keys[key]

                    if not count then
                        error(string.format('Missing parameter "%s" in description (%d):%s', key, skills[i], description))
                    end

                    keys[key] = count + 1
                    allKeys[key] = (allKeys[key] or 0) + 1
                end)

                local description = {description}

                for k, v in pairs(keys) do
                    if v == 0 then
                        table.insert(description, string.format('%s: %%%s%%', k:gsub('^%l', string.upper), k:lower():gsub(' ', '_')))
                    end
                end

                params[key .. 'format'] = table.concat(description, '\n')
            end
        end
    end

    local items = data.Colors

    if items then
        local lookup_gear = lookup.item.gear
        local rank_param = lookup.rank.param

        for idx, items in ipairs(items) do
            local items = items.Items[1]
            local key = 'gear_' .. rank_param[idx] .. '_'

            for i = 2, #items do
                params[key .. (i - 1)] = lookup_gear[items[i]][platform].key
            end
        end
    end

    return params
end

local chooseDescription = {
    ['Orion'] = 'mobile',
    ['Ginger'] = 'browser',
    ['Cornelius'] = 'browser',
    ['Jorgen'] = 'browser',
    ['Jhu'] = 'browser',
    ['Satori'] = 'browser',
    ['Sebastian'] = {'browser', 'mobile'},
}

function generateHero(dest, data)
    local output = {}
    local browser = data.browser
    local mobile = data.mobile
    local ndata = browser or mobile
    local name, description = ndata.name

    print(name, (browser or {}).id, (mobile or {}).id)

    table.insert(output, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Hero/Lua</noinclude>')

    if browser and mobile and browser.description ~= mobile.description then
        local platform = chooseDescription[name]

        if not platform then
            error(string.format("Description doesn't match:\nHero:\t%s (%d)\nBrowser:\t%s\nMobile:\t%s", name, id, browser.description, mobile.description))
        end

        if type(platform) == 'table' then
            local output = {}

            for k, v in ipairs(platform) do
                table.insert(output, data[v].description)
            end

            description = '\n' .. table.concat(output, '\n\n')
        else
            description = data[platform].description
        end
    else
        description = ndata.description
    end

    table.insert(output, ' |flavor = ' .. description:gsub('%%(%w+)%%', {param1 = name}))

    for _, platform in ipairs{'browser', 'mobile'} do -- ensure order
        local data = data[platform]

        if data then
            local params = getParams(platform, data)
            local data = {}
            local prefix = ' |' .. platform .. '_'

            for idx, key in ipairs(params) do
                data[idx] = string.format('%s%s = %s', prefix, key, params[key])
            end

            table.insert(output, table.concat(data, '\n'))
        end
    end
 
    if #output > 0 then
        table.insert(output, '}}</onlyinclude>')

        local data = table.concat(output, '\n')
        local file = io.open(table.concat{dest, '/', name, '.txt'}, 'w')

        if file then
            file:write(data)
            file:close()
        end
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
                local data = lookup[id][platform]

                heroes[data.name][platform] = data
            end
        end
    end

    for _, data in pairs(heroes) do
        generateHero(dest, data)
    end

    for k, v in pairs(allKeys) do
        print(k, v)
    end
end