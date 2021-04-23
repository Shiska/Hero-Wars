return {
    stat = {
        hero = {
            [ 0] = {name = "Level", value = 130},
            main = {
                [1] = {name = "Intelligence"},
                [2] = {name = "Agility"},
                [3] = {name = "Strength"},
            },
            [ 4] = {name = "Health", calculation = { [3] = 40 }, percentage = true},
            [ 5] = {name = "Physical attack", calculation = { [2] = 2 }, percentage = true},
            [ 6] = {name = "Magic attack", calculation = { [1] = 3 }, percentage = true},
            [ 7] = {name = "Armor", calculation = { [2] = 1 }},
            [ 8] = {name = "Magic defense", calculation = { [1] = 1 }},
            [ 9] = {name = "Dodge"},
            [10] = {name = "Armor penetration"},
            [11] = {name = "Magic penetration"},
            [12] = {name = "Vampirism"}, -- in percent
            [13] = {name = "Crit hit chance"},
        },
        pet = {
            [ 0] = {name = "Level", value = 130},
            main = {
                [14] = {name = "Skill Power", percentage = true},
                [15] = {name = "Patronage Power", percentage = true},
            },
            [ 4] = {name = "Health"},
            [ 5] = {name = "Physical attack"},
            [ 6] = {name = "Magic attack"},
            [ 7] = {name = "Armor"},
            [ 8] = {name = "Magic defense"},
            [ 9] = {name = "Dodge"},
            [10] = {name = "Armor penetration"},
            [11] = {name = "Magic penetration"},
        },
        titan = {
            [ 0] = {name = "Level", value = 120},
            main = {},
            [ 4] = {name = "Health", percentage = true},
            [ 5] = {name = "Attack", percentage = true},
            [16] = {name = "Elemental Damage"},
            [17] = {name = "Elemental Armor"},
        },
    },
    maxLevel = {
        hero = {
            blue = 110,
            violet = 90,
        },
    },
    power = {
        hero = {2.75, 2.75, 2.75, 0.05, 0.75, 0.5, 0.5, 0.5, 1.8, 0.5, 0.5, 14.5, 1.8, skill = {4, 20}},
        pet = {[10] = 1, [11] = 1, [14] = 5.5, [15] = 5.5, skill = {3, 20}},
        titan = {[4] = 0.0051, [5] = 0.068, [16] = 0.068, [17] = 0.319},
    },
    skin = {
        hero = {
            ["Default Skin"] = {
                [1] =  1365,
                [2] =  1365,
                [3] =  1365,
            },
            ["Champion's Skin"] = {
                [4] =  106870,
                [5] =  7117,
                [6] =  10687,
                [8] =  10687,
            },
            ["Winter Skin"] = {
                [4] =  106670,
                [5] =  7120,
                [6] =  10665,
                [7] =  10665,
                [9] =  2965,
                [10] = 10665,
            },
            [4] =  106645,
            [5] =  7095,
            [6] =  10650,
            [7] =  10650,
            [8] =  10650,
            [9] =  2960,
            [10] = 10650,
            [11] = 10650,
            [13] = 2960,
        },
        titan = {
            [4] = 1022985,
            [5] = 76740,
            [17] = 49065,
        },
    },
    glyph = {
        [1] = 1135,
        [2] = 1135,
        [3] = 1135,
        [4] = 62200,
        [5] = 4340,
        [6] = 6500,
        [7] = 6500,
        [8] = 6500,
        [9] = 1995,
        [10] = 6500,
        [11] = 6500,
        [13] = 1995,
    },
    gift = 360,
    artifact = {
        hero = {{ -- weapon
                [5] =  21357,
                [6] =  32040,
                [7] =  32040,
                [8] =  32040,
                [9] =  8898,
                [10] = 32040,
                [11] = 32040,
                [13] = 8898,
            }, { -- book
                [2001] = {name = "Warrior's Code", stat = {13, 5}},
                [2002] = {name = "Book of Illusions", stat = {9, 4}},
                [2003] = {name = "Manuscript of the Void", stat = {11, 6}},
                [2004] = {name = "Alchemist's Folio", stat = {10, 5}},
                [2005] = {name = "Tome of Arcane Knowledge", stat = {6, 4}},
                [2006] = {name = "Defender's Covenant", stat = {7, 8}},
                stat = {{
                        [6] =  10680,
                        [7] =  8010,
                        [9] =  2967,
                        [10] = 10680,
                        [11] = 10680,
                        [13] = 2967,
                    }, {
                        [4] =  53394,
                        [5] =  3561,
                        [6] =  5340,
                        [8] =  8010,
                    },
                },
            }, { -- ring
                [1] = 3990,
                [2] = 3990,
                [3] = 3990,
            },
        },
        titan = {{ -- weapon
                [16] = 422565,
            }, { -- crown
                [17] = 89982,
            }, { -- seal and spirit
                [3001] = {name = "Attack Seal", stat = {
                    [4] = 2112821.25,
                    [5] = 369742.50,
                }},
                [3002] = {name = "Balance Seal", stat = {
                    [4] = 3521370.0,
                    [5] = 264101.25,
                }},
                [3003] = {name = "Defense Seal", stat = {
                    [4] = 4929915.0,
                    [5] = 158460.0,
                }},
                [4001] = {name = "Water", stat = {
                    [5] = 264101.25,
                }},
                [4002] = {name = "Fire", stat = {
                    [5] = 264101.25,
                }},
                [4003] = {name = "Earth", stat = {
                    [4] = 3521370.0,
                }},
            },
        },
    },
    stone = {
        item = { -- {stone index, classification}
            {{1, 1}, {1, 1}, {1, 1}, {1, 1}, {1, 1}, {1, 1}}, -- white0
            {{1, 1}, {1, 1}, {1, 1}, {1, 1}, {1, 2}, {1, 2}}, -- green0
            {{1, 1}, {1, 1}, {1, 2}, {1, 2}, {1, 2}, {1, 2}}, -- green1
            {{1, 2}, {1, 2}, {1, 3}, {2, 2}, {2, 2}, {2, 3}}, -- blue0
            {{1, 2}, {1, 3}, {1, 3}, {2, 2}, {2, 3}, {2, 3}}, -- blue1
            {{1, 3}, {1, 3}, {1, 4}, {2, 3}, {2, 3}, {2, 4}}, -- blue2
            {{1, 4}, {1, 4}, {1, 5}, {2, 4}, {2, 4}, {2, 5}}, -- violet0
            {{1, 4}, {1, 5}, {1, 5}, {2, 4}, {2, 5}, {2, 5}}, -- violet1
            {{1, 5}, {1, 5}, {1, 6}, {2, 5}, {2, 5}, {2, 6}}, -- violet2
            {{1, 5}, {1, 6}, {1, 6}, {2, 5}, {2, 6}, {2, 6}}, -- violet3
        },
        class = {"Small", nil, "Uncommon", "Rare", "Excellent", "Flawless"},
    },
}
