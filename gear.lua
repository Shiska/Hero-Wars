local ldir = require('dir')
local proto = require('proto')
local lookup = require('lookup')

local paramsMeta = {
    __newindex = function(self, key, value)
        rawset(self, #self + 1, key)
        rawset(self, key, value)
    end,
}
function getParamsHeroGear(id, platform, data)
    local params = setmetatable({}, paramsMeta)
    local paramsFragment = setmetatable({}, paramsMeta)

    data:expand()

    if data.HeroLevel then
        params.hero_level_required = tonumber(data.HeroLevel[1])
    end
    
    if data.TeamLevel then
        params.team_level_required = tonumber(data.TeamLevel[1])
    end

    for k, v in pairs(data.BattleStatData or {}) do
        params[lookup.param[k]] = tonumber(v[1])
    end

    local craftRecipe = data.CraftRecipe

    if craftRecipe then
        local scrollRecipe = craftRecipe.ScrollRecipe
        local gearRecipe = craftRecipe.GearRecipe
        local cost = craftRecipe.Cost

        if cost then
            cost = cost[1]

            local currency = lookup.item[cost[2]][cost[3]][platform].name

            params['created_with_' .. currency:lower()] = tonumber(cost[4])
        end

        for idx, data in ipairs(gearRecipe) do
            local item = lookup.item.gear[data[1]][platform]
            local key = 'created_with_' .. idx
            local count = data[2]

            params[key] = item.key

            if count > 1 then
                params[key .. '_count'] = tonumber(count)
            end
        end

        if scrollRecipe and #scrollRecipe > 0 then
            params.created_with_recipe = tonumber(scrollRecipe[1][2])
        end
    end

    local fragmentMerge = data.FragmentMerge
    
    if fragmentMerge then
        local cost = fragmentMerge.Cost[1]
        local currency = lookup.item[cost[2]][cost[3]][platform].name

        params['created_with_' .. currency:lower()] = tonumber(cost[4])
        params.created_with_fragment = tonumber(fragmentMerge.Count[1])

        for _, fragmentBuyCost in ipairs(data.FragmentBuyCost or {}) do
            local currency = lookup.item[fragmentBuyCost[2]][fragmentBuyCost[3]][platform].name

            paramsFragment['value_buy_' .. currency:lower()] = tonumber(fragmentBuyCost[4])
        end

        local fragmentSpecialCost = data.FragmentSpecialCost

        if fragmentSpecialCost then
            paramsFragment.value_buy_coins = tonumber(fragmentSpecialCost[1])
        end

        for _, fragmentSellCost in ipairs(data.FragmentSellCost or {}) do
            local currency = lookup.item[fragmentSellCost[2]][fragmentSellCost[3]][platform].name

            paramsFragment['value_sell_' .. currency:lower()] = tonumber(fragmentSellCost[4])
        end

        local fragmentEnchantValue = data.FragmentEnchantValue

        if fragmentEnchantValue then
            paramsFragment.value_sell_exchange = tonumber(fragmentEnchantValue[1])
        end
    end

    for _, buyCost in ipairs(data.BuyCost or {}) do
        local currency = lookup.item[buyCost[2]][buyCost[3]][platform].name

        params['value_buy_' .. currency:lower()] = tonumber(buyCost[4])
    end

    local buySpecialCost = data.BuySpecialCost

    if buySpecialCost then
        params.value_buy_coins = tonumber(buySpecialCost[1])
    end

    for _, sellCost in ipairs(data.SellCost or {}) do
        local currency = lookup.item[sellCost[2]][sellCost[3]][platform].name

        params['value_sell_' .. currency:lower()] = tonumber(sellCost[4])
    end

    local enchantValue = data.EnchantValue

    if enchantValue then
        params.value_sell_exchange = tonumber(enchantValue[1])
    end

    return params, paramsFragment
end

function generateHeroGear(dest, id, data)
    local output = {}
    local outputFragment = {}
    local ndata = select(2, next(data))

    print(id, ndata.name, ndata.key)

    local browser = data.browser
    local mobile = data.mobile

    if browser and mobile and browser.name ~= mobile.name then
        error(string.format("Name doesn't match!\nBrowser:\t%s\nMobile:\t%s", browser.name, mobile.name))
    else
        for _, platform in ipairs{'browser', 'mobile'} do -- ensure order
            local data = data[platform]

            if data then
                local params, paramsFragment = getParamsHeroGear(id, platform, data)
                local data = {}
                local dataFragment = {}
                local prefix = ' |' .. platform .. '_'

                for idx, key in ipairs(params) do
                    data[idx] = string.format('%s%s = %s', prefix, key, params[key])
                end

                table.insert(output, table.concat(data, '\n'))

                if #paramsFragment > 0 then
                    for idx, key in ipairs(paramsFragment) do
                        dataFragment[idx] = string.format('%s%s = %s', prefix, key, paramsFragment[key])
                    end

                    table.insert(outputFragment, table.concat(dataFragment, '\n'))
                end
            end
        end
    end

    if #output > 0 then
        table.insert(output, 1, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Infobox Item/Hero</noinclude>')
        -- table.insert(output, 2, ' |id = ' .. id)
        table.insert(output, '}}</onlyinclude>')

        output = table.concat(output, '\n')

        -- print(output)

        local file = io.open(table.concat{dest, '/', ndata.key:gsub('/', '-'), '-', id, '.txt'}, 'w')

        if file then
            file:write(output)
            file:close()
        end
    end

    if #outputFragment > 0 then
        table.insert(outputFragment, 1, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Infobox Item/Hero</noinclude>')
        -- table.insert(outputFragment, 2, ' |id = ' .. id)
        table.insert(outputFragment, '}}</onlyinclude>')

        outputFragment = table.concat(outputFragment, '\n')

        -- print(outputFragment)

        local file = io.open(table.concat{dest, '/', ndata.key:gsub('/', '-'), '-', id, '-Fragment.txt'}, 'w')

        if file then
            file:write(outputFragment)
            file:close()
        end
    end
end

local attribute_fix = setmetatable({
    intelligence = 'patronagepower',
    strength = 'skillpower',
}, {
    __index = function(self, key)
        local resolve = rawget(self, key) or rawget(self, key:lower())

        if resolve then
            self[key] = resolve

            return resolve
        end

        self[key] = key

        return key
    end,
})

function getParamsPetGear(id, platform, data)
    local params = setmetatable({}, paramsMeta)

    data:expand()

    if data.PetLevel then
        params.pet_level_required = tonumber(data.PetLevel[1])
    end

    local levels = data.Levels

    if levels then
        local lookup_param = lookup.param
        local gold = levels.GoldCost[1]
        local particle = levels.ConsumableCost[1]
        local emeralds = levels.StarmoneyCost[1]

        for attribute, v in pairs(levels.Stats) do
            local param = lookup_param[attribute_fix[attribute]]
            local value = v[1]

            params[param .. '_min'] = tonumber(value[2])
            params[param .. '_max'] = tonumber(value[#value])
        end

        params.upgrade_max_level = #gold
        params.upgrade_chaos_particle = tonumber(particle[2])
        params.upgrade_gold = tonumber(gold[2])
        params.upgrade_emeralds = tonumber(emeralds[2])
    end

    if data.UnlockCost then
        params.buy_chaos_particle = tonumber(data.UnlockCost[1][4])
    end

    if data.SellCost then
        params.sell_chaos_particle = tonumber(data.SellCost[1][4])
    end

    return params
end

function generatePetGear(dest, id, data)
    local output = {}
    local ndata = select(2, next(data))

    print(id, ndata.name)

    local browser = data.browser
    local mobile = data.mobile

    if browser and mobile and browser.name ~= mobile.name then
        error(string.format("Name doesn't match!\nBrowser:\t%s\nMobile:\t%s", browser.name, mobile.name))
    else
        for _, platform in ipairs{'browser', 'mobile'} do -- ensure order
            local data = data[platform]

            if data then
                local params = getParamsPetGear(id, platform, data)
                local data = {}
                local prefix = ' |' .. platform .. '_'

                for idx, key in ipairs(params) do
                    data[idx] = string.format('%s%s = %s', prefix, key, params[key])
                end

                table.insert(output, table.concat(data, '\n'))
            end
        end
    end

    if #output > 0 then
        table.insert(output, 1, '<onlyinclude>{{<includeonly>#invoke:Data|set</includeonly><noinclude>Infobox Item/Pet</noinclude>')
        -- table.insert(output, 2, ' |id = ' .. id)
        table.insert(output, 2, ' |color = ' .. ndata.color)
        table.insert(output, '}}</onlyinclude>')

        output = table.concat(output, '\n')

        -- print(output)

        local file = io.open(table.concat{dest, '/', ndata.name, '-', id, '.txt'}, 'w')

        if file then
            file:write(output)
            file:close()
        end
    end
end

function generate(dest, func, lookup, src)
    local gears = setmetatable({}, {
        __index = function(self, key)
            local data = {}

            self[key] = data

            return data
        end,
    })
    for platform, v in pairs(src) do
        for k in pairs(v) do
            gears[tonumber(k)][platform] = true
        end
    end

    for id, data in pairs(gears) do
        for platform in pairs(data) do
            data[platform] = lookup[id][platform]
        end

        if data.browser then
            if data.mobile then
                if data.browser.name == data.mobile.name then
                    func(dest, id, data)
                else
                    func(dest, id, {browser = data.browser})
                    func(dest, id, {mobile = data.mobile})
                end
            else
                func(dest, id, {browser = data.browser})
            end
        else
            func(dest, id, {mobile = data.mobile})
        end
    end
end

do
    local dest = 'dest/gear'

    ldir:mkdir(dest)

    generate(dest, generateHeroGear, lookup.item.gear, {browser = proto['src/Proto/Gear.proto'].Id, mobile = proto['src/Mobile/Proto/Gear.proto'].Id})
    generate(dest, generateHeroGear, lookup.item.scroll, {browser = proto['src/Proto/Scroll.proto'].Id, mobile = proto['src/Mobile/Proto/Scroll.proto'].Id})

    generate(dest, generatePetGear, lookup.item.petgear, {browser = proto['src/Proto/Items.proto']['Pet Gears'].Id})
end