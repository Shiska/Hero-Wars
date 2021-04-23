local lfs = require('lfs')
local proto = require('proto')
local lookup = require('lookup')

local parseItem = setmetatable({
        ['gear'] = function(self, idx, params, platform)
            params['loot' .. idx] = lookup.item.gear[self[4]][platform].key
        end,
        ['fragmentGear'] = function(self, idx, params, platform)
            params['loot' .. idx] = lookup.item.fragmentGear[self[4]][platform].key
        end,
        ['scroll'] = function(self, idx, params, platform)
            params['loot' .. idx] = lookup.item.scroll[self[4]][platform].key
        end,
        ['fragmentScroll'] = function(self, idx, params, platform)
            params['loot' .. idx] = lookup.item.fragmentScroll[self[4]][platform].key
        end,
        ['consumable'] = function() end,
        ['fragmentHero'] = function(self, idx, params, platform)
            params.soul_stone = lookup.item.fragmentHero[self[4]][platform]
        end,
        ['pseudo'] = function() end,
    }, {
        __index = function(self, key)
            error('Undefined item type ":' .. key .. '"')
        end,
    }
)

local params_meta = {
    __newindex = function(self, key, value)
        rawset(self, #self + 1, key)
        rawset(self, key, {value, #self})
    end,
}

function getParams(id, platform, data)
    local params = setmetatable({}, params_meta)

    -- params.title = data.name
    params.description = data.description
    params.chapter = tonumber(data.World[1])
    params.mission = tonumber(data.Index[1])

    local nm = data.NormalMode

    if nm.TryCost then
        local try = tonumber(nm.TryCost[1][4])

        params.energy = tonumber(nm.Cost[1][4]) + try
        params.try = try
    end

    local waves = nm.Waves
    local drop_chance = waves[#waves].Enemies
    -- drop_chance is stored in the last enemy
    drop_chance = drop_chance[#drop_chance].Drop

    if drop_chance then
        drop_chance = drop_chance.Chance

        params.gold = tonumber(drop_chance[#drop_chance][5])
    end

    if nm.HeroExp then
        params.exp = tonumber(nm.HeroExp[1])
        params.team_exp = tonumber(nm.TeamExp[1])
    end

    for w = 0, #waves do
        local wave = waves[w]
        local enemies = wave.Enemies

        for e = 0, #enemies do
            local enemy = enemies[e]
            local gid = enemy.Gid[1]
            local pos = (w + 1) .. '_' .. (e + 1)
            local id = gid[4]

            local name
            local creep = lookup.creep[id][platform]

            if creep then
                name = 'Enemies/' .. creep.name
            else
                local hero = lookup.hero[id][platform]

                if hero then
                    name = 'Heroes/' .. hero.name
                else
                    name = 'Titans/' .. lookup.titan[id][platform].name
                end
            end

            if enemy.Color then
                params['rank' .. pos] = lookup.rank[tonumber(enemy.Color[1])]
            else -- titans
                params['rank' .. pos] = lookup.rank[tonumber(id)]
            end

            params['level' .. pos] = tonumber(gid[6])
            params['star' .. pos] = tonumber(gid[8])
            params['enemy' .. pos] = name
        end
    end

    if drop_chance then
        for i, loot in ipairs(drop_chance) do
            parseItem[loot[3]](loot, i, params, platform)
        end
    end

    local previousIdx = tonumber(id) - 1
    local previousMission = lookup.mission[previousIdx][platform]
    local nextIdx = previousIdx + 2
    local nextMission = lookup.mission[nextIdx][platform]

    if previousMission then
        params.previous = string.format('%d/%s', previousMission.World[1], previousMission.name)
    end

    if nextMission then
        params.next = string.format('%d/%s', nextMission.World[1], nextMission.name)
    end

    return setmetatable(params, nil)
end

function generateMission(dest, id, data)
    local output = {}
    local ndata = select(2, next(data))

    table.insert(output, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Infobox Campaign</noinclude>')
    -- table.insert(output, string.format(' |id = %s', id))

    local params = {}

    for platform, data in pairs(data) do
        local output = getParams(id, platform, data)

        if #output > 0 then
            params[platform] = output
        end
    end

    if false and params.browser and params.mobile then
        local params_browser = params.browser
        local params_mobile = params.mobile
        local prefix_all = ' |'
        local prefix_brower = ' |browser_'
        local prefix_mobile = ' |mobile_'

        local params = {}
        local idx_offset = 0

        for idx_browser, key in ipairs(params_browser) do
            local entry_browser = params_browser[key][1]
            local entry_mobile = params_mobile[key]

            if entry_mobile then
                local idx_mobile = entry_mobile[2]
                local idx_offset_new = idx_mobile - idx_browser

                if idx_offset < idx_offset_new then
                    for idx = idx_offset, idx_offset_new - 1 do
                        local key = params_mobile[idx_browser + idx]

                        table.insert(params, string.format('%s%s = %s', prefix_mobile, key, params_mobile[key][1]))

                    end

                    idx_offset = idx_offset_new
                end

                entry_mobile = entry_mobile[1]

                if entry_browser == entry_mobile then
                    table.insert(params, string.format('%s%s = %s', prefix_all, key, entry_browser))
                else
                    table.insert(params, string.format('%s%s = %s', prefix_brower, key, entry_browser))
                    table.insert(params, string.format('%s%s = %s', prefix_mobile, key, entry_mobile))
                end
            else
                table.insert(params, string.format('%s%s = %s', prefix_brower, key, entry_browser))
            end
        end

        table.insert(output, table.concat(params, '\n'))
    else
        for platform, params in pairs(params) do
            local data = {}
            local prefix = ' |' .. platform .. '_'

            for idx, key in ipairs(params) do
                data[idx] = string.format('%s%s = %s', prefix, key, params[key][1])
            end

            table.insert(output, table.concat(data, '\n'))
        end
    end

    table.insert(output, '}}</onlyinclude>')

    local filename = table.concat{dest, '/', ndata.World[1], '-', ndata.Index[1], ' ', ndata.name, '.txt'}
    local data = table.concat(output, '\n')
    local file = io.open(filename, 'w')

    if file then
        file:write(data)
        file:close()

        print(filename)
    end
end

do
    local dest = 'dest/mission'

    lfs.mkdir('dest')
    lfs.mkdir('dest/mission')

    local src = {
        browser = proto['src/Proto/Missions.proto'],
        mobile = proto['src/Mobile/Proto/Missions.proto'],
    }
    local missions = setmetatable({}, {
        __index = function(self, key)
            local data = {}

            self[key] = data

            return data
        end,
    })
    for id in pairs(src.browser.Id) do
        missions[id].browser = true
    end

    for id in pairs(src.mobile.Id) do
        missions[id].mobile = true
        -- cut first part of mobile mission names
        local name = lookup.text('missionName', id)

        name.mobile = name.mobile:match(': (.+)$')
    end

    for id, data in pairs(missions) do
        for platform in pairs(data) do
            data[platform] = lookup.mission[id][platform]
        end

        if data.browser then
            if data.mobile then
                if data.browser.name == data.mobile.name then
                    generateMission(dest, id, data)
                else
                    generateMission(dest, id, {browser = data.browser})
                    generateMission(dest, id, {mobile = data.mobile})
                end
            else
                generateMission(dest, id, {browser = data.browser})
            end
        else
            generateMission(dest, id, {mobile = data.mobile})
        end
    end
end