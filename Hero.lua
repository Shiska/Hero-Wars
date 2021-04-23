local module = {}
local Data = {}
local Stat = setmetatable({}, {
    __call = function(self, ...)
        return setmetatable(self, {
            __call = function(self, data_stat, stat, value)
                return {name = data_stat[stat].name, stat = stat, value = value}
            end,
        })(...)
    end,
})

local MaxStat = setmetatable({}, {
    __call = function(self, ...)
        local calculate = function(self, hero)
            local data_stat = Data.stat[hero.type]
            local data_stat_main = data_stat.main

            local hero_main_stat = (hero.main_stat or {}).stat
            local level = data_stat[0].value

            self[0] = level

            function add(t, key, value)
                self[key] = self[key] + value
                t[key] = t[key] + value
            end

            local meta = {
                __index = function(self, key)
                    return 0
                end,
            }
            setmetatable(self, meta) -- unset values return 0

            local stat_base = setmetatable({}, meta)
            local stat_level = setmetatable({}, meta)
            local stat_skins = setmetatable({}, meta)
            local stat_items = setmetatable({}, {
                __index = function(self, key)
                    local data = setmetatable({}, meta)

                    rawset(self, key, data)

                    return data
                end,
            })
            local stat_glyphs = setmetatable({}, meta)
            local stat_gote = setmetatable({}, meta)
            local stat_artifacts = setmetatable({}, meta)
            -- statGroups
            local statGroup = {
                base = stat_base,
                level = stat_level,
                skins = stat_skins,
                glyphs = stat_glyphs,
                gote = stat_gote,
                artifacts = stat_artifacts,
            }
            hero.statGroup = statGroup
            -- copy base values
            for k, v in pairs(hero.base) do
                add(stat_base, k, v)
            end
            -- add attributes from level
            for k, v in pairs(hero.star) do
                add(stat_level, k, level * v)
            end
            -- add all skins
            for k, v in ipairs(hero.skin or {}) do
                v = v.stat

                add(stat_skins, v.stat, v.value)
            end
            -- add all items
            if hero.item then
                local items = setmetatable({}, meta)

                for r, v in ipairs(hero.item) do
                    local items_rank = stat_items[r]

                    for k = 1, 6 do -- ipairs not working because data is probably not initialized yet
                        for k, v in pairs(v[k].stat) do
                            local k = v.stat

                            add(items_rank, k, v.value)
                        end
                    end
                    -- add one promotion
                    for k, _ in pairs(data_stat_main) do
                        add(items_rank, k, 2)
                    end

                    statGroup['items' .. r] = items_rank
                    -- combine ranks
                    for k, v in pairs(items_rank) do
                        items[k] = items[k] + v
                    end
                end
                -- remove last promotion
                for k, _ in pairs(data_stat_main) do
                    add(stat_items[1], k, -2)
                    items[k] = items[k] - 2
                end

                statGroup.items = items
            end
            -- add all glyphs
            for k, v in ipairs(hero.glyph or {}) do
                k = v.stat

                add(stat_glyphs, k, v.value)
            end
            -- add gift of the elements
            if hero_main_stat and Data.gift then
                local data_gift = Data.gift

                for k, v in ipairs(data_stat_main) do
                    add(stat_gote, k, data_gift)
                end
                -- main stat gets twice the bonus
                add(stat_gote, hero_main_stat, data_gift)
            end
            -- add artifacts
            for k, v in pairs(hero.artifact or {}) do
                add(stat_artifacts, k, v)
            end
            -- resolve effect of main attributes
            for k, v in ipairs(data_stat) do
                for m, v in pairs(v.calculation or {}) do
                    self[k] = self[k] + self[m] * v
                end
            end
            -- add physical damage from main stat
            if hero_main_stat then
                self[5] = self[5] + self[hero_main_stat]
            end
            -- remove metatable
            return setmetatable(self, nil)
        end

        return setmetatable(self, {
            __call = function(self, hero)
                return setmetatable({}, {
                    __index = function(self, key)
                        return calculate(self, hero)[key]
                    end,
                })
            end,
        })(...)
    end,
})

local Power = setmetatable({}, {
    __call = function(self, ...)
        local extra = {
            hero = function(self, data_power, hero)
                local stat = hero.weapon
                local power = Data.artifact.hero.weapon[stat] * data_power[stat] / 2

                self.artifacts = self.artifacts + power

                return power
            end,
        }
        local calculate = function(self, hero)
            setmetatable(self, nil) -- to prevent an infinite loop

            local power_total = 0
            local level = hero.stat[0]
            local hero_type = hero.type
            local data_power = Data.power[hero_type]
            local data_power_skill = data_power.skill

            local function calculatePower(stat)
                local power = 0
    
                for k, v in pairs(stat) do
                    power = power + v * (data_power[k] or 0)
                end
    
                if power > 0 then
                    power_total = power_total + power
    
                    return power
                end
            end

            for k, v in pairs(hero.statGroup or {}) do
                self[k] = calculatePower(v)
            end
            -- remove items from total power because itemX are alos present
            if self.items then
                power_total = power_total - self.items
            end
            -- add power from skills
            if data_power_skill then
                self.skills = level * data_power_skill[1] * data_power_skill[2]
                power_total = power_total + self.skills
            end
            -- add power from non-stats, e.g. heroes artifact weapon
            local extra = extra[hero_type]

            if extra then
                power_total = power_total + extra(self, data_power, hero)
            end

            self.total = power_total
    
            return self
        end

        return setmetatable(self, {
            __call = function(self, hero)
                return setmetatable({}, {
                    __index = function(self, key)
                        return calculate(self, hero)[key]
                    end,
                })
            end,
        })(...)
    end,
})

local Skill = setmetatable({}, {
    __call = function(self, ...)
        local lang = mw.getContentLanguage()
        local function formatNum(value)
            local round = math.floor(value)
            -- convert to integer if float ends with .0
            if round == value then
                value = round
            end

            return lang:formatNum(value)
        end

        local function formatProduct(data_stat, mul)
            data_stat = data_stat or {}

            local output = {}

            if data_stat.percentage then
                output = {formatNum(mul * 100) .. '%', concat = ' ', data_stat.name}
            else
                output = {formatNum(mul), concat = ' * ', data_stat.name}
            end

            return table.concat(output, output.concat)
        end

        local function formatForumla(self, description, skill, max_stat, data_stat, maxLevel)
            local formulas = {}
            -- replace max hero level with max skill level
            local fixed = {
                [0] = maxLevel, -- if maxLevel doesn't exists it will fallback to max_stat
                [-1] = 1,
            }
            for _, v in ipairs(skill) do
                local sum = {}
                local value = 0

                for _, v in ipairs(v) do
                    local stat = v.stat or -1
                    local val = v.value

                    if fixed[stat] then
                        value = value + (fixed[stat] * val)
                    else
                        value = value + (max_stat[stat] * val)
                    end

                    table.insert(sum, formatProduct(data_stat[stat], val))
                end

                local round = v.round or 0

                if round >= 0 then
                    round = 10^round
                    value = math.floor(value * round + 0.5) / round
                end

                table.insert(formulas, description and formatNum(value) or value)
                table.insert(formulas, table.concat(sum, ' + '))
            end

            if description then
                return string.format(description, (table.unpack or unpack)(formulas))
            end

            return formulas
        end

        return setmetatable(self, {
            __call = function(self, hero, skill) -- hero, value
                local output = {}
                local data_stat = Data.stat[hero.type]
                local data_maxLevel = Data.maxLevel[hero.type] or {}

                for k, v in pairs(skill) do
                    output[k] = setmetatable({
                        format = function(self, description, fake_stat)
                            return formatForumla(self, description, v, fake_stat or hero.stat, data_stat, data_maxLevel[k])
                        end
                    }, {__index = v})
                end

                return output
            end,
        })(...)
    end,
})

local Skin = setmetatable({}, {
    __call = function(self, ...)
        return setmetatable(self, {
            __call = function(self, hero, skin)
                local output = {}
                local hero_type = hero.type
                local data_skin = Data.skin[hero_type]
                local data_stat = Data.stat[hero_type]

                for k, v in ipairs(skin) do
                    output[k] = setmetatable(v, {
                        __index = function(self, key)
                            setmetatable(self, nil)

                            local name = self.name
                            local stat = data_stat.lookup[self.attribute]

                            self.stat = Stat(data_stat, stat, self.value and tonumber(self.value) or ((data_skin[name] or data_skin)[stat]))

                            return self[key]
                        end,
                    })
                end

                return output
            end,
        })(...)
    end,
})

local Item_Hero = setmetatable({}, {
    __call = function(self, ...)
        local data_item = Data.item.hero
        local function resolve(self, item)
            for k, v in ipairs(item) do
                self[k] = data_item[v]
            end

            return setmetatable(self, nil)
        end

        return setmetatable(self, {
            __call = function(self, item)
                local output = {
                    raw = item,
                }
                for k, v in ipairs(item) do
                    output[k] = setmetatable({}, {
                        __index = function(self, key)
                            return resolve(self, v)[key]
                        end,
                    })
                end

                return output
            end,
        })(...)
    end,
})

local Item_Pet = setmetatable({}, {
    __call = function(self, ...)
        local data_item = Data.item.pet
        local data_stone = Data.stone
        local data_stone_item = data_stone.item
        local data_stone_class = data_stone.class

        local function resolve(self, stone, item)
            for k, v in ipairs(item) do
                local stone = stone[v[1]]
                local class = data_stone_class[v[2]]

                self[k] = data_item[class and table.concat({class, stone}, ' ') or stone]
            end

            return setmetatable(self, nil)
        end

        return setmetatable(self, {
            __call = function(self, stone)
                local output = {
                    raw = stone,
                }
                for k, v in ipairs(data_stone_item) do
                    output[k] = setmetatable({}, {
                        __index = function(self, key)
                            return resolve(self, stone, v)[key]
                        end,
                    })
                end

                return output
            end,
        })(...)
    end,
})

local Glyph = function(glyph)
    local output = {}
    local data_glyph = Data.glyph
    local data_stat_lookup = Data.stat.hero.lookup

    for k, v in ipairs(glyph) do
        local glyph = data_glyph[data_stat_lookup[v]]

        if not glyph then
            error(string.format('Glyph: Invalid attribute "%s" (check spelling, only first character uppercase)', v))
        end

        output[k] = glyph
    end

    return output
end

local Hero = setmetatable({}, {
    __index = function(self, key)
        self.loadSkin = function(args)
            local skin = {}

            while true do
                local field = 'skin' .. (#skin + 1)

                local name = args[field .. '_name']
                local attribute = args[field .. '_attribute']

                if not name or not attribute then
                    break
                end

                table.insert(skin, {name = name, attribute = attribute, value = args[field .. '_value']})
            end

            return skin
        end

        self.loadItem = function(args, params)
            local item = {}

            for k, v in ipairs(params) do
                local key = v .. '_'
                local row = {}

                for i = 1, 6 do
                    local value = args[key .. i]

                    if not value or value == '' then
                        error(string.format('Item: Item parameter "%s%d" not set!', key, i))
                    end

                    row[i] = value
                end

                item[k] = row
            end

            return item
        end

        self.loadSkill = function(data_stat_param, args, colors)
            local output = {}

            for _, color in ipairs(colors) do
                local key = 'skill_' .. color .. '_'
                local skill = {}

                while true do
                    local key = key .. (#skill + 1) .. '_'
                    local attr = {}

                    for k, v in pairs(data_stat_param) do
                        local arg = args[key .. v]

                        if arg then
                            table.insert(attr, {stat = k, value = tonumber(arg)})
                        end
                    end

                    local arg = args[key .. 'base']

                    if arg then
                        table.insert(attr, {value = tonumber(arg)})
                    end

                    local arg = args[key .. 'round']

                    if arg then
                        attr.round = tonumber(arg)
                    end

                    if #attr == 0 then
                        break
                    end

                    table.insert(skill, attr)
                end

                if #skill > 0 then
                    output[color] = skill
                end
            end

            return output
        end

        self.loadAttributes = function(data_stat_param, args, key)
            local output = {}
            local key = key or ''

            for k, v in pairs(data_stat_param) do
                local arg = args[key .. v]

                if arg then
                    output[k] = tonumber(arg)
                end
            end

            return output
        end

        return setmetatable(self, nil)[key]
    end,
})

setmetatable(Data, {
    __index = function(self, key)
        -- load data on first access
        local data = mw.loadData('Module:Hero/Data')
        local get = require('Module:Data').get
        local frame = mw.getCurrentFrame()

        local function createInitMetatable(data, index, newindex)
            return {
                __index = function(self, key)
                    local init = index[key]

                    if init then
                        init = init()
                    else
                        init = data[key]
                    end

                    rawset(self, key, init)

                    return init
                end,
                __newindex = function(self, key, value)
                    local init = newindex[key]

                    if init then
                        init = init(value)
                    else
                        init = value
                    end

                    return rawset(self, key, init)
                end,
            }
        end

        local newTableMeta = {
            __index = function(self, key)
                local data = {}

                self[key] = data

                return data
            end,
        }
        function splitArgs(args)
            local function load(self)
                setmetatable(self, newTableMeta)

                for k, v in pairs(args) do
                    local platform, param = k:match('([^_]+)_(.+)')
                    
                    if platform then -- TODO: remove later
                        self[platform][param] = v
                    end
                end
                
                setmetatable(self, nil)
                -- TODO: temp fix
                local browser = self.browser
                local mobile = self.mobile

                for k in pairs(self) do
                    self[k] = nil
                end

                self.browser = browser or args
                self.mobile = mobile

                return self
            end

            return setmetatable({}, {
                __ipairs = function(self) return ipairs(load(self)) end,
                __pairs = function(self) return pairs(load(self)) end,
                __index = function(self, key) return load(self)[key] end,
            })
        end
        -- resolve data on access
        return setmetatable(self, createInitMetatable(data, {
            stat = function()
                return setmetatable({}, {
                    __index = function(self, key)
                        local stat = {}
                        local param = {}
                        local lookup = {}

                        self[key] = stat

                        for k, v in pairs(data.stat[key]) do
                            stat[k] = v
                        end

                        for k, v in pairs(stat.main) do
                            stat[k] = v
                        end

                        for k, v in pairs(stat) do
                            if v.name then
                                param[k] = v.name:lower():gsub(' ', '_')
                                lookup[v.name] = k
                            end
                        end

                        stat.param = param
                        stat.lookup = setmetatable(lookup, {
                            __index = function(self, key)
                                error(string.format('Lookup: Invalid attribute "%s" (check spelling, only first character uppercase)', key or ''))
                            end,
                        })
                        return stat
                    end,
                })
            end,
            hero = function()
                return setmetatable({}, {
                    __call = function(self, key, args, sargs)
                        local output = {}
                        local data_stat = Data.stat.hero
                        local data_stat_param = data_stat.param
                        local items = {
                            browser = {
                                'white0',
                                'green0',
                                'green1',
                                'blue0',
                                'blue1',
                                'blue2',
                                'violet0',
                                'violet1',
                                'violet2',
                                'violet3',
                                'orange0',
                                'orange1',
                                'orange2',
                                'orange3',
                                'orange4',
                                'red0',
                                'red1',
                                'red2',
                            },
                            mobile = {
                                'white0',
                                'green0',
                                'green1',
                                'blue0',
                                'blue1',
                                'blue2',
                                'violet0',
                                'violet1',
                                'violet2',
                                'violet3',
                                'orange0',
                                'orange1',
                                'orange2',
                                'orange3',
                                'orange4',
                            },
                        }
                        for platform, args in pairs(sargs or splitArgs(args)) do
                            local hero = {
                                type = 'hero',
                                title = key,
                                args = args
                            }
                            local main_stat = args.main_stat

                            output[platform] = hero

                            setmetatable(hero, createInitMetatable({}, {
                                stat = function() return MaxStat(hero) end,
                                power = function() return Power(hero) end,
                                weapon = function()
                                    return Data.stat.hero.lookup[get(frame, {'attr1',
                                        title = string.format('File:%s weapon.png', args.hero or key),
                                    })['attr1']]
                                end,
                            }, {
                                main_stat = function(value) return Stat(data_stat, data_stat.lookup[value]) end,
                                skin = function(value)
                                    table.insert(value, 1, {name = 'Default Skin', attribute = main_stat})
    
                                    return Skin(hero, value)
                                end,
                                skill = function(value) return Skill(hero, value) end,
                                glyph = function(value) return Glyph(value) end,
                                artifact = function(value)
                                    local stat = {}
                                    local main_stat = hero.main_stat.stat
                                    local data_artifact = Data.artifact.hero
                                    -- add book
                                    for k, v in ipairs(data_artifact[data_artifact.lookup[value]].stat) do
                                        stat[v.stat] = v.value
                                    end
                                    -- add ring
                                    stat[main_stat] = data_artifact.ring[main_stat]
    
                                    return stat
                                end,
                                item = function(value) return Item_Hero(value) end,
                            }))
                            hero.main_stat = main_stat
                            hero.glyph = {args['glyph1'], args['glyph2'], args['glyph3'], args['glyph4'], main_stat}
                            hero.artifact = args.artifact
                            hero.skin = Hero.loadSkin(args)
                            hero.item = Hero.loadItem(args, items[platform])
                            hero.star = Hero.loadAttributes(data_stat_param, args, 'level_')
                            hero.base = Hero.loadAttributes(data_stat_param, args, 'base_')
                            hero.skill = Hero.loadSkill(data_stat_param, args, {'white', 'green', 'blue', 'violet'})
                        end

                        self[key] = output

                        return output
                    end,
                    __index = function(self, key)
                        return self(key, nil, Data.load['Heroes/' .. key])
                    end,
                })
            end,
            pet = function()
                return setmetatable({}, {
                    __call = function(self, key, args)
                        local data_stat = Data.stat.pet
                        local data_stat_param = data_stat.param
                        local pet = {
                            type = 'pet',
                            title = key,
                            args = args
                        }
                        setmetatable(pet, createInitMetatable({}, {
                            stat = function() return MaxStat(pet) end,
                            power = function() return Power(pet) end,
                        }, {
                            skill = function(value) return Skill(pet, value) end,
                            item = function(value) return Item_Pet(value) end,
                        }))
                        pet.item = {args.stone1, args.stone2}
                        pet.star = Hero.loadAttributes(data_stat_param, args, 'level_')
                        pet.base = Hero.loadAttributes(data_stat_param, args, 'base_')
                        pet.skill = Hero.loadSkill(data_stat_param, args, {'white', 'green', 'violet'})

                        self[key] = pet

                        return pet
                    end,
                    __index = function(self, key)
                        return self(key, get(frame, {title = 'Pets/' .. key}))
                    end,
                })
            end,
            titan = function()
                return setmetatable({}, {
                    __call = function(self, key, args)
                        local data_stat = Data.stat.titan
                        local data_stat_param = data_stat.param
                        local titan = {
                            type = 'titan',
                            title = key,
                            args = args
                        }
                        setmetatable(titan, createInitMetatable({}, {
                            power = function() return Power(titan) end,
                        }, {
                            skin = function(value) return Skin(titan, value) end,
                            skill = function(value) return Skill(titan, value) end,
                            artifact = function(value)
                                local stat = {}
                                local data_artifact = Data.artifact.titan
                                local data_artifact_lookup = data_artifact.lookup
                                -- add weapon
                                for k, v in pairs(data_artifact.weapon) do
                                    stat[k] = v
                                end
                                -- add crown
                                for k, v in pairs(data_artifact.crown) do
                                    stat[k] = v
                                end
                                -- add seal
                                for k, v in ipairs(data_artifact[data_artifact_lookup[value]].stat) do
                                    stat[v.stat] = v.value
                                end

                                return stat
                            end,
                            spirit = function(value)
                                local stat = {}
                                local data_artifact = Data.artifact.titan
                                local data_artifact_lookup = data_artifact.lookup
                                -- add spirit
                                for k, v in ipairs(data_artifact[data_artifact_lookup[value]].stat) do
                                    stat[v.stat] = v.value
                                end

                                return stat
                            end,
                        }))

                        titan.artifact = args.artifact
                        titan.spirit = args.element
                        titan.skin = Hero.loadSkin(args)
                        titan.star = Hero.loadAttributes(data_stat_param, args, 'level_')
                        titan.base = Hero.loadAttributes(data_stat_param, args, 'base_')
                        titan.stat = Hero.loadAttributes(data_stat_param, args, 'max_')
                        titan.skill = Hero.loadSkill(data_stat_param, args, {'white', 'green'})

                        titan.stat[0] = data_stat[0].value
                        titan.statGroup = {
                            base = titan.base,
                            skins = (function()
                                local stat = {}

                                for _, v in ipairs(titan.skin) do
                                    v = v.stat

                                    stat[v.stat] = v.value
                                end

                                return stat
                            end)(),
                            artifacts = titan.artifact,
                            spirit = titan.spirit,
                        }
                        local stat = {}

                        for k, v in pairs(titan.stat) do
                            stat[k] = v
                        end
                        for k, v in pairs(titan.base) do
                            stat[k] = stat[k] - v
                        end
                        for k, v in pairs(titan.statGroup.skins) do
                            stat[k] = stat[k] - v
                        end
                        for k, v in pairs(titan.artifact) do
                            stat[k] = stat[k] - v
                        end
                        for k, v in pairs(titan.spirit) do
                            stat[k] = stat[k] - v
                        end

                        titan.statGroup.level = stat

                        self[key] = titan

                        return titan
                    end,
                    __index = function(self, key)
                        return self(key, get(frame, {title = 'Titans/' .. key}))
                    end,
                })
            end,
            item = function()
                local param = {
                    hero = function(s) return s.param end,
                    pet = function(s) return {
                            [10] = 'armor_penetration_max',
                            [11] = 'magic_penetration_max',
                            [14] = 'skill_power_max',
                            [15] = 'patronage_power_max',
                        }
                    end,
                }
                local title = {
                    hero = 'Heroes/Equipment/',
                    pet = 'Pets/Equipment/',
                }
                return setmetatable({}, {
                    __index = function(self, ttype)
                        local data_stat = Data.stat[ttype]
                        local param = param[ttype](data_stat)
                        local title = title[ttype]

                        return setmetatable({}, {
                            __index = function(self, key)
                                local args = Data.load[title .. key]
                                local args_browser = args.browser
                                local stat = {}

                                for idx, param in pairs(param) do
                                    local s = args_browser[param]

                                    if s then
                                        stat[idx] = Stat(data_stat, idx, s)
                                    end
                                end                                    

                                local item = {
                                    title = key,
                                    stat = stat,
                                    args = args,
                                }
                                self[key] = item

                                return item
                            end,
                        })
                    end,
                })
            end,
            glyph = function()
                local glyphs = {}
                local data_stat = Data.stat.hero

                for k, v in pairs(data.glyph) do
                    glyphs[k] = Stat(data_stat, k, v)
                end

                return glyphs
            end,
            artifact = function()
                local function createLookup(artifacts, data)
                    artifacts.lookup = setmetatable({}, {
                        __index = function(self, key)
                            local lookup = {}

                            for k, v in pairs(data) do
                                if v.name then
                                    lookup[v.name] = k
                                end
                            end

                            artifacts.lookup = setmetatable(lookup, {
                                __index = function(self, key)
                                    error(string.format('Lookup: Invalid artifact "%s" (check spelling)', key or ''))
                                end,
                            })
                            setmetatable(self, { __index = lookup })

                            return lookup[key]
                        end,
                    })
                end

                return setmetatable({}, createInitMetatable({}, {
                    hero = function()
                        local data_artifact = data.artifact.hero
                        local data_stat = Data.stat.hero

                        return setmetatable({}, {
                            __index = function(self, key)
                                local artifacts = {
                                    weapon = data_artifact[1],
                                    ring = data_artifact[3],
                                }
                                local ref = data_artifact[2].stat
                                -- loop through books
                                for k, v in pairs(data_artifact[2]) do
                                    artifacts[k] = setmetatable({}, {
                                        __index = function(self, key)
                                            local artifact = {}

                                            for k, v in pairs(v) do
                                                artifact[k] = v
                                            end

                                            local stat = {}

                                            for k, v in ipairs(artifact.stat) do
                                                stat[k] = Stat(data_stat, v, ref[k][v])
                                            end

                                            artifact.stat = stat
                                            artifacts[k] = artifact

                                            setmetatable(self, { __index = artifact })

                                            return artifact[key]
                                        end,
                                    })
                                end

                                createLookup(artifacts, data_artifact[2])

                                return setmetatable(self, { __index = artifacts })[key]
                            end,
                        })
                    end,
                    titan = function()
                        local data_artifact = data.artifact.titan
                        local data_stat = Data.stat.titan

                        return setmetatable({}, {
                            __index = function(self, key)
                                local artifacts = {
                                    weapon = data_artifact[1],
                                    crown = data_artifact[2],
                                }
                                -- loop through seals and sprit
                                for k, v in pairs(data_artifact[3]) do
                                    artifacts[k] = setmetatable({}, {
                                        __index = function(self, key)
                                            local artifact = {}

                                            for k, v in pairs(v) do
                                                artifact[k] = v
                                            end

                                            local stat = {}

                                            for k, v in pairs(artifact.stat) do
                                                table.insert(stat, Stat(data_stat, k, v))
                                            end

                                            artifact.stat = stat
                                            artifacts[k] = artifact

                                            setmetatable(self, { __index = artifact })

                                            return artifact[key]
                                        end,
                                    })
                                end

                                createLookup(artifacts, data_artifact[3])

                                return setmetatable(self, { __index = artifacts })[key]
                            end,
                        })
                    end,
                }))
            end,
            load = function()
                return setmetatable({}, {
                    __call = function(self, key, value)
                        value = splitArgs(value)

                        rawset(self, key, value)

                        return value
                    end,
                    __index = function(self, key)
                        return self(key, get(frame, {title = key}))
                    end,
                })
            end,
        }))[key]
    end,
})

function module.page(frame, args, pargs)
    local template = (args or frame.args).template
    local pargs = pargs or (frame.getParent and frame:getParent().args) or {}
    local title = pargs.title or mw.title.getCurrentTitle().subpageText
    local hero = Data[template](title, pargs)
    local args = {}

    if hero then
        --for platform, hero in pairs(hero) do
        do
            local hero = hero.browser or hero

            if hero then
                local pargs = hero.args

                for k, v in pairs(hero.skill) do
                    local key = 'skill_' .. k
        
                    args[key .. '_description'] = v:format(pargs[key .. '_format'])
                end
        
                for k, v in pairs(pargs) do
                    args[k] = v
                end
        
                for k, v in pairs(args) do
                    mw.log('args', k, v)
                end
                -- pass stats
                local data_stat = Data.stat[hero.type]
                local param = data_stat.param
        
                for k, v in pairs(hero.stat) do
                    local param = param[k]
        
                    args[param] = v
                    mw.log(param, v)
                end
                -- pass power
                local hero_power = hero.power or {}
        
                _ = hero_power.total
        
                for k, v in pairs(hero_power) do
                    local param = 'power_' .. k
        
                    args[param] = v
                    mw.log(param, v)
                end
                -- pass stats per group
                local groups = hero.statGroup or {}
        
                for stat, _ in pairs(param) do
                    local param = param[stat] .. '_'
        
                    for k, v in pairs(groups) do
                        local param = param .. k
                        local value = v[stat] or 0
        
                        if value > 0 then
                            args[param] = value
                            mw.log(param, value)
                        end
                    end
                end
            end
        end
    else
        mw.log('Hero "' .. title .. '" not in database!')

        args = pargs
    end

    return frame.expandTemplate and frame:expandTemplate{title = template, args = args}
end

function module.page_test(template, title, hero)
    local hero = hero or 'Alvanor'
    local frame = mw:getCurrentFrame()
    local pargs = require('Module:Data').get(frame, {title = title or 'Heroes/' .. hero})

    pargs.title = hero

    return module.page(frame, {template = template or 'hero'}, pargs)
end

function module.stats(frame, args)
    local fargs = args or frame.args or {}
    local template = fargs.row_template

    if template then
        local platform = fargs.platform or 'browser'
        local dpl = require('Module:Data').dpl
        local heroes = dpl(frame, {
            category = platform,
            uses = 'Template:Infobox Hero',
        })
        local data_hero = Data.hero

        table.sort(heroes)

        local output = {}
        local params = {title = template}

        for _, v in ipairs(heroes) do
            v = v:sub(8)

            local hero = data_hero[v]

            if hero then
                local hero = hero[platform]

                if hero then
                    _ = hero.stat[0] -- call calculate
    
                    local args = hero.stat
    
                    args.title = v
                    args.hero = hero.args.hero
    
                    params.args = args
    
                    table.insert(output, frame:expandTemplate(params))
                end
            end
        end

        return table.concat(output)
    end
end

function module.stats_test()
    return module.stats(mw:getCurrentFrame(), {row_template = 'Hero/Gist/Stats'})
end

function module.faceless(frame, args)
    local fargs = args or frame.args or {}
    local template = fargs.row_template

    if template then
        local platform = fargs.platform or 'browser'
        local dpl = require('Module:Data').dpl
        local heroes = dpl(frame, {
            category = platform,
            uses = 'Template:Infobox Hero',
        })
        local lang = mw.getContentLanguage()
        local data_hero = Data.hero
        local sep = fargs.sep

        table.sort(heroes)

        local hero = data_hero.Faceless[platform]
        local clevel = hero.skill.white:format()[1]
        local stat = {}
        -- copy faceless stat
        for k, v in pairs(hero.stat) do
            stat[k] = v
        end
        -- overwrite level
        stat[0] = clevel

        local output = {}
        local params = {title = template}

        for _, v in ipairs(heroes) do
            local hero = data_hero[v:sub(8)]

            if hero then
                hero = hero[platform]

                if hero then
                    local skill_white = hero.skill.white
                    local formulas = skill_white:format()
                    local valuesOriginal = {}
    
                    for i = 1, #formulas, 2 do
                        table.insert(valuesOriginal, formulas[i])
                    end
    
                    local formulas = skill_white:format(nil, stat)
                    local valuesCopy = {}
    
                    for i = 1, #formulas, 2 do
                        table.insert(valuesCopy, formulas[i])
                    end
    
                    local diff = {}
    
                    for k, v in ipairs(valuesOriginal) do
                        local c = valuesCopy[k]
                        local d = c - v
    
                        if d >= 0 then
                            diff[k] = '+' .. d
                        else
                            diff[k] = d
                        end
                    end
    
                    params.args = {
                        title = hero.title,
                        hero = hero.args.hero,
                        original = table.concat(valuesOriginal, sep),
                        copy = table.concat(valuesCopy, sep),
                        diff = table.concat(diff, sep),
                    }
                    table.insert(output, frame:expandTemplate(params))
                end
            end
        end

        return table.concat(output)
    end
end

function module.faceless_test()
    return module.faceless(mw:getCurrentFrame(), {row_template = 'Hero/Gist/Faceless', sep = '<br/>'})
end

function module.equipment(frame, args)
    local fargs = args or frame.args or {}
    local column_template = fargs.column_template
    local row_template = fargs.row_template

    if column_template and row_template then
        local platform = fargs.platform or 'browser'
        local dpl = require('Module:Data').dpl
        local heroes = dpl(frame, {
            category = platform,
            uses = 'Template:Infobox Hero',
        })
        local data_hero = Data.hero

        table.sort(heroes)

        local params = {title = column_template}
        local items = setmetatable({}, {
            __index = function(self, key)
                table.insert(self, key)
                self[key] = true
            end,
        })
        local header = {}

        for k, v in ipairs(heroes) do
            v = v:sub(8)

            local hero = data_hero[v][platform]
            local count = {
                title = v,
                hero = hero.args.hero,
            }
            for _, v in ipairs(hero.item.raw) do
                for _, v in ipairs(v) do
                    count[v] = (count[v] or 0) + 1
                    _ = items[v]
                end
            end

            params.args = count
            heroes[k] = count

            table.insert(header, frame:expandTemplate(params))
        end

        local args = {}

        params.title = row_template
        params.args = args

        for k, item in ipairs(items) do
            args.item = item

            local row = frame:expandTemplate(params)
            local key = row:match('data%-sort%-value="([^"]+)"') or item

            row = {row}
            
            for _, v in ipairs(heroes) do
                table.insert(row, string.format('\r\n|title="%s"|%s', v.title, v[item] or '&nbsp;'))
            end

            items[k] = {key, table.concat(row)}
        end

        table.sort(items, function(a, b) return a[1] < b[1] end)

        for k, v in ipairs(items) do
            items[k] = v[2]
        end

        return table.concat(header) .. table.concat(items)
    end
end

function module.equipment_test()
    return module.equipment(mw:getCurrentFrame(), {column_template = 'Hero/Gist/Equipment/Column', row_template = 'Hero/Gist/Equipment/Row'})
end

function module.infobox_item_platform(frame, args)
    local fargs = args or frame.args

    local item = fargs.item
    local template = fargs.template
    local template_raw = fargs.template_raw
    local template_used_by_item = fargs.template_used_by_item
    local template_used_by_hero = fargs.template_used_by_hero
    local template_found_in = fargs.template_found_in
    local template_created_with = fargs.template_created_with

    if item and template and template_used_by_item and template_used_by_hero and template_found_in and template_created_with and template_raw then
        local dpl = require('Module:Data').dpl
        local data_item = Data.item.hero
        local data_hero = Data.hero
        local data_load = Data.load
        local args = {
            item = item
        }
        for k, v in pairs(fargs) do
            args[k] = v
        end

        local parent = frame:getParent()

        if parent then
            local pargs = parent.args

            data_load(mw.title.getCurrentTitle().text, pargs)

            for k, v in pairs(pargs) do
                args[k] = v
            end
        end

        local platforms = data_item[item].args
        local meta_createSubTable = {
            __index = function(self, key)
                local value = {}

                self[key] = value

                return value
            end,
        }
        local meta_createSubSubTable = {
            __index = function(self, key)
                local value = setmetatable({}, meta_createSubTable)

                self[key] = value

                return value
            end,
        }
        local meta_created_with_internal = {
            __newindex = function(self, key, value)
                table.insert(self, key)

                return rawset(self, key, value)
            end,
        }
        local meta_created_with = {
            __index = function(self, key)
                local value = setmetatable({}, meta_created_with_internal)

                self[key] = value

                return value
            end,
        }
        local created_with = setmetatable({}, {
            __index = function(self, item)
                local created_with = setmetatable({}, meta_created_with)

                self[item] = created_with

                for platform, args in pairs(data_item[item].args) do
                    local gold = args.created_with_gold

                    if gold then
                        local created_with = created_with[platform]

                        local idx = 1
                        local key = 'created_with_1'
                        local param = args.created_with_1

                        while param do
                            created_with[param] = tonumber(args[key .. '_count'] or 1)

                            idx = idx + 1
                            key = 'created_with_' .. idx
                            param = args[key]
                        end

                        local recipe = args.created_with_recipe

                        if recipe then
                            created_with[item .. '/Recipe'] = tonumber(recipe)
                        end

                        local fragment = args.created_with_fragment

                        if fragment then
                            created_with[item .. '/Fragment'] = tonumber(fragment)
                        end

                        -- created_with.gold = gold
                    end
                end

                return setmetatable(created_with, nil)
            end,
        })
        local used_by_item = setmetatable({}, {
            __index = function(self, item)
                local used_by_item = setmetatable({}, meta_createSubTable)
                local created_with = created_with

                self[item] = used_by_item

                local data = dpl(frame, {
                    linksto = 'Heroes/Equipment/' .. item,
                    uses = 'Template:Infobox item|Template:Infobox Item',
                })
                for _, v in ipairs(data) do -- remove 'Heroes/Equipment/'
                    v = v:sub(18)

                    for platform, created_with in pairs(created_with[v]) do
                        local count = created_with[item]

                        if count then -- only direct items
                            used_by_item[platform][v] = count
                        end
                    end
                end

                return used_by_item
            end,
        })
        local used_by_hero = setmetatable({}, {
            __index = function(self, item)
                local used_by = setmetatable({}, {
                    __index = function(self, item)
                        local data = dpl(frame, {
                            linksto = 'Heroes/Equipment/' .. item,
                            category = 'Browser', -- TODO: temp fix - only heroes that have browser part set
                            uses = 'Template:Infobox Hero',
                        })
                        for k, v in ipairs(data) do
                            data[k] = v:sub(8)
                        end

                        self[item] = data

                        return data
                    end,
                })
                local function search(data, item) -- goes through all used_by items and adds all heroes to data
                    if not data[item] then
                        data[item] = true
                        -- add heroes
                        for _, v in ipairs(used_by[item]) do
                            if not data[v] then
                                table.insert(data, v)
     
                                data[v] = true
                            end
                        end
                        -- search for further items
                        for _, used_by_item  in pairs(used_by_item[item]) do
                            for item in pairs(used_by_item) do
                                search(data, item)
                            end
                        end
                    end

                    return data
                end

                return setmetatable(self, {
                    __index = function(self, item)
                        local used_by_hero = search({}, item)

                        table.sort(used_by_hero)

                        self[item] = used_by_hero

                        return used_by_hero
                    end,
                })[item]
            end,
        })
        do -- image
            for platform in pairs(platforms) do
                args[platform .. '_image'] = item
            end
        end

        do -- created_with
            local pargs = {}
            local params = {title = template_created_with, args = pargs}

            for platform, created_with in pairs(created_with[item]) do
                local output = {}

                for idx, item in ipairs(created_with) do
                    pargs.item = item
                    pargs.count = created_with[item]
                    pargs.index = idx

                    table.insert(output, frame:expandTemplate(params))
                end

                args[platform .. '_created_with'] = table.concat(output)
            end
        end

        do -- created_with_raw
            local meta = {
                __index = function(self, key)
                    rawset(self, #self + 1, key)
                    rawset(self, key, 0)

                    return 0
                end,
            }
            local pargs = {}
            local params = {title = template_raw, args = pargs}

            for platform in pairs(platforms) do
                local items = setmetatable({}, meta)
                local show = false

                local function go(name, pcount)
                    local data = created_with[name][platform]
    
                    if data then
                        for _, key in ipairs(data) do
                            local count = pcount * data[key]
                            local data = created_with[key][platform]
        
                            if data and next(data) then
                                go(key, count)
        
                                show = true -- if more than the base items are found
                            else
                                items[key] = items[key] + count
                            end
                        end
                    end
                end
    
                go(item, 1)

                if show then
                    local output = {}

                    table.sort(items, function(a, b)
                        return items[a] < items[b] -- sort by count
                    end)
    
                    for k, v in ipairs(items) do
                        pargs.item = v
                        pargs.count = items[v]
                        pargs.index = k
    
                        table.insert(output, frame:expandTemplate(params))
                    end
            
                    args[platform .. '_created_with_raw'] = table.concat(output)
                end
            end
        end

        do -- used_by_item
            local pargs = {}
            local params = {title = template_used_by_item, args = pargs}

            for platform, used_by_item in pairs(used_by_item[item]) do
                local items = {}

                for k, _ in pairs(used_by_item) do
                    table.insert(items, k)
                end

                if #items > 0 then
                    table.sort(items)
        
                    for k, v in ipairs(items) do
                        pargs.item = v
                        pargs.count = used_by_item[v]
                        pargs.index = k
        
                        items[k] = frame:expandTemplate(params)
                    end

                    args[platform .. '_used_by_item'] = table.concat(items)
                end
            end
        end

        do -- used_by_hero
            local pargs = {}
            local used_by_hero = used_by_hero[item]
            local params = {title = template_used_by_hero, args = pargs}
            local total_count_meta = {
                __index = function(self, key)
                    rawset(self, #self + 1, key)

                    return 0
                end,
            }
            for platform in pairs(platforms) do
                local item_count = setmetatable({}, meta_createSubTable)
                local total_count = setmetatable({}, total_count_meta)
                -- count hero items
                for _, hero in ipairs(used_by_hero) do
                    local data = data_hero[hero][platform]

                    if data then
                        for _, items in ipairs(data.item.raw) do
                            for _, item in ipairs(items) do
                                local item_count = item_count[item]
        
                                item_count[hero] = (item_count[hero] or 0) + 1
                            end
                        end
                    end
                end
                -- sum up counts of used_by_items
                local function go(item, parent_count)
                    for hero, count in pairs(item_count[item]) do
                        total_count[hero] = total_count[hero] + count * parent_count
                    end

                    for item, count in pairs(used_by_item[item][platform]) do
                        go(item, count * parent_count)
                    end
                end

                go(item, 1)

                table.sort(total_count)

                local sum = 0
                local output = {}
                local item_count = item_count[item]

                for idx, hero in ipairs(total_count) do
                    pargs.hero = hero
                    pargs.index = idx

                    local count, total = item_count[hero], total_count[hero]
                    -- split count that directly need that item (count1) and needed for creating other items (count2)
                    if count then
                        pargs.count1 = count
                        pargs.count2 = total - count
                    else
                        pargs.count1 = 0
                        pargs.count2 = total
                    end

                    sum = sum + total

                    table.insert(output, frame:expandTemplate(params))
                end

                if sum > 0 then
                    args[platform .. '_used_by_hero'] = table.concat(output)
                    args[platform .. '_used_by_hero_total'] = sum
                end
            end
        end

        do -- found_in
            local params = {title = template_found_in}
            local data = dpl(frame, {
                category = '**Missions',
                linksto = 'Heroes/Equipment/' .. item,
                uses = 'Template:Infobox Campaign',
                ordermethod = 'sortkey',
            })
            for platform in pairs(platforms) do
                local missions = {}

                for _, mission in ipairs(data) do
                    local args = data_load[mission][platform]

                    if args then
                        local idx = 1
                        local param = args.loot1

                        while param do
                            if param == item then
                                table.insert(missions, mission)

                                missions[mission] = args
                                break
                            end

                            idx = idx + 1
                            param = args['loot' .. idx]
                        end
                    end
                end

                local output = {}

                for idx, mission in ipairs(missions) do
                    local args = missions[mission]

                    args.title = mission
                    args.index = idx

                    params.args = args
                    
                    table.insert(output, frame:expandTemplate(params))
                end

                args[platform .. '_found_in'] = table.concat(output)
            end
        end

        for k, v in pairs(args) do mw.log(k, v) end

        return frame:expandTemplate{title = template, args = args}
    end
end

function module.skins(frame, args)
    frame = frame or mw.getCurrentFrame()

    local fargs = args or frame.args or {}
    local template = fargs.template

    if template then
        local type = fargs.type or 'Hero'
        local dpl = require('Module:Data').dpl
        local heroes = dpl(frame, {
            category = 'Browser',
            uses = 'Template:Infobox ' .. type,
        })
        local data_hero = Data[type:lower()]

        table.sort(heroes)

        local output = {}
        local skins = setmetatable({}, {
            __index = function(self, key)
                local data = {
                    skin = key
                }
                table.insert(self, key)

                self[key] = data

                return data
            end,
        })
        for _, v in ipairs(heroes) do
            v = v:sub(8)

            local hero = data_hero[v]
            local title = hero.title

            if hero then
                for _, v in ipairs(hero.skin or {}) do
                    table.insert(skins[v.name], title)
                end
            end
        end

        table.sort(skins)

        local params = {title = template}

        for k, v in ipairs(skins) do
            local heroes = skins[v]

            table.sort(heroes)

            params.skin = v
            params.args = heroes

            skins[k] = frame:expandTemplate(params)
        end

        return table.concat(skins)
    end
end

function module.infobox_item_test()
    return module.infobox_item_platform(mw.getCurrentFrame(), {
        item = "Orange/La Mort's Map",
        template = 'Infobox Item',
        template_raw = 'Infobox Item/Hero/Raw',
        template_created_with = 'Infobox Item/Hero/Created With',
        template_found_in = 'Campaign/Match/Output',
        template_used_by_hero = 'Infobox Item/Hero/Hero',
        template_used_by_item = 'Infobox item/hero/item',
    })
end

function module.selftest()
    assert(module.page_test('hero', 'Heroes/Alvanor', 'Alvanor'), 'page_test hero')
    assert(module.page_test('titan', 'Titans/Eden', 'Eden'), 'page_test titan')
    assert(module.page_test('pet', 'Pets/Albus', 'Albus'), 'page_test pet')
    assert(module.stats_test(), 'stats_test')
    assert(module.faceless_test(), 'faceless_test')
    assert(module.equipment_test(), 'equipment_test')
    assert(module.infobox_item_test(), 'infobox_item_test')
end

return module