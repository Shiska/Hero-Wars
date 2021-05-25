return setmetatable({}, {
    __index = function(self, key)
        local proto = require('proto')
        local text = setmetatable({}, {
            __call = function(self, ...)
                local src = {
                    browser = proto['src/Language/English/ProtoText.txt'],
                    mobile = proto['src/Language/English/ProtoTextMobile.txt'],
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local src = src[key]

                        if src then
                            src = src[self.key]

                            if src then
                                src = src[1]
                                self[key] = src
                            end
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __call = function(self, ...)
                        return self[table.concat({...}, '_')]
                    end,
                    __index = function(self, key)
                        local output = setmetatable({key = key}, loadPlatform)
  
                        self[key] = output

                        return output
                    end,
                })(...)
            end,
        })
        local item = setmetatable({}, {
            __index = function(self, key)
                local color = {
                    'White',
                    'Green',
                    'Blue',
                    'Violet',
                    'Orange',
                    'Red',
                }
                local gear = setmetatable({}, {
                    __index = function(self, key)
                        local src = {
                            browser = proto['src/Proto/Gear.proto'],
                            mobile = proto['src/Mobile/Proto/Gear.proto'],
                        }
                        local loadPlatform = {
                            __index = function(self, key)
                                local src = src[key]

                                if src then
                                    local id = self.id

                                    src = src.Id[id]

                                    if src then
                                        src.name = text('gearName', self.id)[key]
                                        src.key = color[tonumber(src.Color[1])] .. '/' .. src.name

                                        local craftRecipe = src.CraftRecipe
                                        -- reformat recipe to fix compare of 
                                        if craftRecipe then
                                            local scrollRecipe = craftRecipe.ScrollRecipe
                                            local gearRecipe = craftRecipe.GearRecipe
                                            local cost = craftRecipe.Cost

                                            if scrollRecipe then
                                                scrollRecipe = scrollRecipe[1]

                                                local recipe = {}

                                                for g = 2, #scrollRecipe, 2 do
                                                    table.insert(recipe, {tonumber(scrollRecipe[g]), tonumber(scrollRecipe[g + 1])})
                                                end

                                                table.sort(recipe, function(a, b) return a[1] < b[1] end)
                                                
                                                craftRecipe.ScrollRecipe = recipe
                                            end

                                            if gearRecipe then
                                                gearRecipe = gearRecipe[1]

                                                local recipe = {}

                                                for g = 2, #gearRecipe, 2 do
                                                    table.insert(recipe, {tonumber(gearRecipe[g]), tonumber(gearRecipe[g + 1])})
                                                end

                                                table.sort(recipe, function(a, b) return a[1] < b[1] end)
                                                
                                                craftRecipe.GearRecipe = recipe
                                            end
                                        end

                                        self[key] = src
                                    end
                                end

                                return src
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local id = tonumber(key)
                                local data = setmetatable({id = id}, loadPlatform)

                                self[key] = data
                                self[id] = data

                                return data
                            end,
                        })[key]
                    end,
                })
                local gearFragment = setmetatable({}, {
                    __index = function(self, key)
                        local loadPlatform = {
                            __index = function(self, key)
                                local gear = gear[self.id][key]

                                if gear then
                                    gear = {
                                        name = gear.name .. ' (Fragment)',
                                        key = gear.key .. '/Fragment',
                                    }
                                    self[key] = gear
                                end

                                return gear
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local gear = gear[key]

                                if gear then
                                    gear = setmetatable({id = gear.id}, loadPlatform)

                                    self[key] = gear
                                end

                                return gear
                            end,
                        })[key]
                    end,
                })
                local scroll = setmetatable({}, {
                    __index = function(self, key)
                        local src = {
                            browser = proto['src/Proto/Scroll.proto'],
                            mobile = proto['src/Mobile/Proto/Scroll.proto'],
                        }
                        local loadPlatform = {
                            __index = function(self, key)
                                local src = src[key]

                                if src then
                                    local id = self.id

                                    src = src.Id[id]

                                    if src then 
                                        src.name = text('scrollName', id)[key]
                                        src.key = color[tonumber(src.Color[1])] .. '/' .. src.name:sub(1, -10) .. '/Recipe'

                                        self[key] = src
                                    end
                                end

                                return src
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local id = tonumber(key)
                                local data = setmetatable({id = id, color = color}, loadPlatform)

                                self[key] = data
                                self[id] = data

                                return data
                            end,
                        })[key]
                    end,
                })
                local scrollFragment = setmetatable({}, {
                    __index = function(self, key)
                        local loadPlatform = {
                            __index = function(self, key)
                                local scroll = scroll[self.id][key]

                                if scroll then
                                    scroll = {
                                        name = scroll.name .. ' (Fragment)',
                                        key = scroll.key .. '/Fragment',
                                    }
                                    self[key] = scroll
                                end

                                return scroll
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local scroll = scroll[key]

                                if scroll then
                                    scroll = setmetatable({id = scroll.id}, loadPlatform)

                                    self[key] = scroll
                                end

                                return scroll
                            end,
                        })[key]
                    end,
                })
                local consumable = setmetatable({}, {
                    __index = function(self, key)
                        local src = {
                            browser = proto['src/Proto/Items.proto'].Consumable,
                            mobile = proto['src/Mobile/Proto/Items.proto'].Consumable,
                        }
                        local loadPlatform = {
                            __index = function(self, key)
                                local src = src[key]

                                if src then
                                    local id = self.id

                                    src = src.Id[id]

                                    if src then
                                        src.name = text('consumableName', id)[key]

                                        if src.DescLocaleId then
                                            src.description = text('consumableDesc', src.DescLocaleId[1])[key]
                                        end

                                        self[key] = src
                                    end
                                end

                                return src
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local id = tonumber(key)
                                local data = setmetatable({id = id}, loadPlatform)

                                self[key] = data
                                self[id] = data

                                return data
                            end,
                        })[key]
                    end,
                })
                local heroFragment = setmetatable({}, {
                    __index = function(self, key)
                        local data = text('heroName', key)

                        self[key] = data

                        return data
                    end,
                })
                local pseudo = setmetatable({}, {
                    __index = function(self, key)
                        local src = {
                            browser = proto['src/Proto/Items.proto'].Pseudo,
                            mobile = proto['src/Mobile/Proto/Items.proto'].Pseudo,
                        }
                        local loadPlatform = {
                            __index = function(self, key)
                                local src = src[key]

                                if src then
                                    local id = self.id

                                    src = src.Id[id]

                                    if src then 
                                        src.name = text('pseudoName', id)[key]

                                        self[key] = src
                                    end
                                end

                                return src
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local id = tonumber(key)
                                local data = setmetatable({id = id}, loadPlatform)

                                self[key] = data
                                self[id] = data

                                return data
                            end,
                        })[key]
                    end,
                })
                local petgear = setmetatable({}, {
                    __index = function(self, key)
                        local src = {
                            browser = proto['src/Proto/Items.proto'],
                            mobile = proto['src/Mobile/Proto/Items.proto'],
                        }
                        local loadPlatform = {
                            __index = function(self, key)
                                local src = src[key]

                                if src then
                                    local id = self.id

                                    src = src['Pet Gears'].Id[id]

                                    if src then
                                        src.name = text('petGearName', self.id)[key]
                                        src.color = color[tonumber(src.Color[1])]

                                        self[key] = src
                                    end
                                end

                                return src
                            end,
                        }
                        return setmetatable(self, {
                            __index = function(self, key)
                                local id = tonumber(key)
                                local data = setmetatable({id = id}, loadPlatform)

                                self[key] = data
                                self[id] = data

                                return data
                            end,
                        })[key]
                    end,
                })
                self.gear = gear
                self.fragmentGear = gearFragment
                self.scroll = scroll
                self.fragmentScroll = scrollFragment
                self.consumable = consumable
                self.fragmentHero = heroFragment
                self.pseudo = pseudo
                self.petgear = petgear

                return setmetatable(self, {
                    __index = function(self, key)
                        error('Undefined item type ":' .. key .. '"')
                    end,
                })[key]
            end,
        })
        local skin = setmetatable({}, {
            __index = function(self, key)
                local src = {
                    browser = proto['src/Proto/HeroSkin.proto'],
                    mobile = proto['src/Mobile/Proto/HeroSkin.proto'],
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local src = src[key]

                        if src then
                            src = src.Id[self.id]
                            src.text = text('skinTag', src.LocaleKey[1])[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local hero = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Hero/%d.proto',
                    mobile = 'src/Mobile/Proto/Hero/%d.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local id = self.id
                        local src = proto[path[key]:format(id)]

                        if src then
                            src.id = id
                            src.name = text('heroName', id)[key]
                            src.description = text('heroDesc', id)[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local titan = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Titan/%d.proto',
                    mobile = 'src/Mobile/Proto/Titan/%d.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local id = self.id
                        local src = proto[path[key]:format(id)]

                        if src then
                            src.id = id
                            src.name = text('titanName', id)[key]
                            src.description = text('titanDesc', id)[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local pet = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Pet/%d.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local id = self.id
                        local src = proto[path[key]:format(id)]

                        if src then
                            src.id = id
                            src.name = text('petName', id)[key]
                            src.description = text('petDesc', id)[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local creep = setmetatable({}, {
            __index = function(self, key)
                local creepNameFix = setmetatable({
                        ['Infernal knight'] = 'Infernal Knight',
                        ['Demon-archer'] = 'Demon Archer',
                        ['Wild demon'] = 'Wild Demon',
                        ['Archdemon (boss)'] = 'Archdemon',
                        ['Demon-fencer'] = 'Demon Fencer',
                        ['Satyr-javelin thrower'] = 'Satyr Javelin Thrower',
                        ['Mountain troll'] = 'Mountain Troll',
                        ['Champion troll'] = 'Champion Troll',
                        ['Killer orc'] = 'Killer Orc',
                        ['Goblin-slinger'] = 'Goblin Slinger',
                        ['Ogre (boss)'] = 'Gro Bulgor',
                        ['Skeleton-arbalester'] = 'Skeleton Arbalester',
                        ['Bone ballista'] = 'Bone Ballista',
                        ['Black knight'] = 'Black Knight',
                        ['Messenger of death'] = 'Messenger of Death',
                        ['Huge revived tree (boss)'] = 'Scrump',
                        ['Cemetery dragon (boss)'] = 'Morth Chrone',
                    }, {
                        __index = function(self, key)
                            return key
                        end,
                    }
                )
                local path = {
                    browser = 'src/Proto/Creep/%d.proto',
                    mobile = 'src/Mobile/Proto/Creep/%d.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local id = self.id
                        local src = proto[path[key]:format(id)]

                        if src then
                            src.name = creepNameFix[text('creepName', id)[key]]
                            src.description = text('creepDesc', id)[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local boss = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Boss/%d.proto',
                    mobile = 'src/Mobile/Proto/Boss/%d.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local id = self.id
                        local src = proto[path[key]:format(id)]

                        if src then
                            src.name = text('bossName', id)[key]
                            src.description = text('bossDesc', id)[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        local attribute = setmetatable({}, {
                __index = function(self, key)
                    local attribute = {
                        [0] = 'Level',
                        [1] = 'Strength',
                        [2] = 'Intelligence',
                        [3] = 'Agility',
                        [4] = 'Health',
                        [5] = 'Physical attack',
                        [6] = 'Magic attack',
                        [7] = 'Armor',
                        [8] = 'Magic defense',
                        [9] = 'Crit hit chance',
                        [10] = 'Dodge',
                        [11] = 'Magic penetration',
                        [12] = 'Armor penetration',
                        [13] = 'Vampirism',
                        ['intelligence'] = 'Intelligence',
                        ['agility'] = 'Agility',
                        ['strength'] = 'Strength',
                        ['hp'] = 'Health',
                        ['physicalattack'] = 'Physical attack',
                        ['magicpower'] = 'Magic attack',
                        ['armor'] = 'Armor',
                        ['magicresist'] = 'Magic defense',
                        ['dodge'] = 'Dodge',
                        ['armorpenetration'] = 'Armor penetration',
                        ['magicpenetration'] = 'Magic penetration',
                        ['lifesteal'] = 'Vampirism',
                        ['physicalcritchance'] = 'Crit hit chance',
                        ['patronagepower'] = 'Patronage Power',
                        ['skillpower'] = 'Skill Power',
                        ['level'] = 'Level',
                        ['anticrit'] = 'Anti crit',
                        ['antidodge'] = 'Anti dodge',
                        ['elementarmor'] = 'Elemental Armor',
                        ['elementattack'] = 'Elemental Damage',
                        ['elementspiritpower'] = 'Elemental Spirit Power',
                        ['damagetoearth'] = 'Damage to Earth',
                        ['defensefromearth'] = 'Defense from Earth',
                        ['damagetowater'] = 'Damage to Water',
                        ['defensefromwater'] = 'Defense from Water',
                        ['damagetofire'] = 'Damage to Fire',
                        ['defensefromfire'] = 'Defense from Fire',
                        ['hpRegen'] = 'HP regen',
                        ['attack'] = 'Attack',
                    }
                    return setmetatable(self, {
                        __index = function(self, key)
                            local resolve = attribute[key] or attribute[key:lower()] or attribute[tonumber(key)]

                            if resolve then
                                self[key] = resolve
                            else
                                error('Attribute "' .. key .. '" not found!')
                            end

                            return resolve
                        end,
                    })[key]
                end,
            }
        )
        local param = setmetatable({}, {
            __index = function(self, key)
                local attribute = attribute[key]

                if attribute then
                    attribute = attribute:gsub(' ', '_'):lower()

                    self[key] = attribute
                end

                return attribute
            end,
        })
        local rank = {
            -- heroes - rankid
            'white',
            'green',
            'green +1',
            'blue',
            'blue +1',
            'blue +2',
            'violet',
            'violet +1',
            'violet +2',
            'violet +3',
            'orange',
            'orange +1',
            'orange +2',
            'orange +3',
            'orange +4',
            'red',
            'red +1',
            'red +2',
            param = {
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
            -- titans - titanid
            [4000] = 'white',
            [4001] = 'white',
            [4002] = 'white',
            [4003] = 'super',
            [4010] = 'white',
            [4011] = 'white',
            [4012] = 'white',
            [4013] = 'super',
            [4020] = 'white',
            [4021] = 'white',
            [4022] = 'white',
            [4023] = 'super',
        }
        local role = setmetatable({
            ['control'] = 'Control',
            ['healer'] = 'Healer',
            ['mage'] = 'Mage',
            ['ranged_dps'] = 'Marksman',
            ['support'] = 'Support',
            ['melee_tank'] = 'Tank',
            ['melee_dps'] = 'Warrior',
            ['boss'] = 'Boss',
        }, {
            __index = function(self, key)
                error('Unknown role "' .. key .. '"')
            end,
        })
        local artifact = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    hero = {
                        browser = 'src/Proto/HeroArtifact.proto',
                        mobile = 'src/Mobile/Proto/HeroArtifact.proto',
                    },
                    titan = {
                        browser = 'src/Proto/TitanArtifact.proto',
                        mobile = 'src/Mobile/Proto/TitanArtifact.proto',
                    },
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local type = self.key
                        local proto = proto[path[type][key]]

                        if proto then
                            local id = self.id
                            local src = proto.Id[id]

                            if src then
                                src.name = text(type .. 'ArtifactName', id)[key]

                                local srcBattleEffect = src.BattleEffect
                                local protoBattleEffect = proto['Battle Effect']

                                for k, v in ipairs(srcBattleEffect) do
                                    srcBattleEffect[k] = protoBattleEffect[tonumber(v)]
                                end

                                self[key] = src
                            end

                            return src
                        end
                    end,
                }
                local loadId = {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({key = self.key, id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        if path[key] then
                            local output = setmetatable({key = key}, loadId)
     
                            self[key] = output

                            return output
                        end
                    end,
                })[key]
            end,
        })
        local skill = setmetatable({
            color = {'white', 'green', 'blue', 'violet'},
            attribute = setmetatable({
                [''] = 0,
                ['PA'] = 5,
                ['MP'] = 6,
                ['STR'] = 1,
                ['FP'] = 2,
                ['HP'] = 4,
            }, {
                __index = function(self, key)
                    error('Undefined skill attribute "' .. key .. '"')
                end,
            }),
        }, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Skill.proto',
                    mobile = 'src/Mobile/Proto/Skill.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local src = proto[path[key]]

                        if src then
                            local id = self.id

                            src = src.Id[id]

                            if src then
                                src.name = text('skillName', id)[key]
                                src.description = text('skillDesc', id)[key]
                                src.param = text('skillParam', id)[key]

                                self[key] = src
                            end
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]                
            end,
        })
        local mission = setmetatable({}, {
            __index = function(self, key)
                local path = {
                    browser = 'src/Proto/Missions.proto',
                    mobile = 'src/Mobile/Proto/Missions.proto',
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local src = proto[path[key]]

                        if src then
                            local id = self.id

                            src = src.Id[id]

                            if src then
                                src.name = text('missionName', id)[key]
                                src.description = text('missionDesc', id)[key]

                                self[key] = src
                            end
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]                
            end,
        })
        local titanskin = setmetatable({}, {
            __index = function(self, key)
                local src = {
                    browser = proto['src/Proto/TitanSkin.proto'],
                    mobile = proto['src/Mobile/Proto/TitanSkin.proto'],
                }
                local loadPlatform = {
                    __index = function(self, key)
                        local src = src[key]

                        if src then
                            src = src.Id[self.id]
                            src.text = text('skinTag', src.LocaleKey[1])[key]

                            self[key] = src
                        end

                        return src
                    end,
                }
                return setmetatable(self, {
                    __index = function(self, key)
                        local id = tonumber(key)
                        local output = setmetatable({id = id}, loadPlatform)
 
                        self[tostring(id)] = output
                        self[id] = output

                        return output
                    end,
                })[key]
            end,
        })
        self.text = text
        self.item = item
        self.skin = skin
        self.titanskin = titanskin
        self.hero = hero
        self.titan = titan
        self.pet = pet
        self.creep = creep
        self.boss = boss
        self.attribute = attribute
        self.param = param
        self.rank = rank
        self.role = role
        self.artifact = artifact
        self.skill = skill
        self.mission = mission        

        return setmetatable(self, nil)[key]
    end,
})