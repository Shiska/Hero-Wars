local ldir = require('dir')
local proto = require('proto')
local lookup = require('lookup')

function getTextEntries(dest, items, type, name, description)
    local output = {}
    local lookup = lookup.text

    for platform, items in pairs(items) do
        local items = items[type].Id
        local data = {}

        for k, v in pairs(items) do
            table.insert(data, tonumber(k))

            data[tostring(k)] = string.format('%d = %s = %s', k, lookup(name, k)[platform], lookup(description, k)[platform])
        end

        table.sort(data)
        table.insert(output, platform)

        for _, v in ipairs(data) do
            table.insert(output, data[tostring(v)])
        end
    end

    local file = io.open(table.concat{dest, '/', type:lower(), '.txt'}, 'w')

    if file then
        file:write(table.concat(output, '\n'))
        file:close()
    end
end

function getConsumables(dest, items, type)
    local output = {}
    local lookup = lookup.item.consumable

    for platform, items in pairs(items) do
        local items = items[type].Id
        local data = {}

        for k, v in pairs(items) do
            local consumable = lookup[k][platform]
            local effectDescription = consumable.EffectDescription

            table.insert(data, tonumber(k))

            if effectDescription then
                data[tostring(k)] = string.format('%d = %s = %s (%s = %s)', k, consumable.name, consumable.description, effectDescription.Name[1], effectDescription.Count[1])
            else
                data[tostring(k)] = string.format('%d = %s = %s', k, consumable.name, consumable.description)
            end
        end

        table.sort(data)
        table.insert(output, platform)

        for _, v in ipairs(data) do
            table.insert(output, data[tostring(v)])
        end
    end

    local file = io.open(table.concat{dest, '/', type:lower(), '.txt'}, 'w')

    if file then
        file:write(table.concat(output, '\n'))
        file:close()
    end
end

do
    local dest = 'dest/item'

    ldir:mkdir(dest)

    local items = {
        browser = proto['src/Proto/Items.proto'],
        mobile = proto['src/Mobile/Proto/Items.proto'],
    }
    getTextEntries(dest, items, 'Coins', 'coinName', 'coinDesc')
    getConsumables(dest, items, 'Consumable')
    getTextEntries(dest, items, 'Pseudo', 'pseudoName', 'pseudoDesc')
end