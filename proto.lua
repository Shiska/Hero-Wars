return setmetatable({
    eq = function(t1, t2)
        return t1:expand() == t2:expand()
    end
}, {
    __index = function(self, key)
        local parse = {}
        local meta = {}
        -- compare tables - only gets called for different tables!
        local function cmp(t1, t2)
            local copy = {}
            -- create shallow copy of t2
            for k, v in pairs(t2) do
                copy[k] = v
            end
            -- compare keys
            for k, v1 in pairs(t1) do
                local v2 = copy[k]
                local t1 = type(v1)

                if t1 ~= type(v2) then
                    return false
                end

                if v1 ~= v2 then
                    if t1 == 'table' then
                        if not cmp(v1, v2) then
                            return false
                        end
                    else
                        return false
                    end
                end

                copy[k] = nil
            end
            -- check if copy has any keys left
            return not next(copy)
        end
        -- compare and expand, use proto.eq to auto-expand tables, normal compare only works if both tables are already expanded
        local function dummy(self) return self end
        local metaCompDummy = {
            __eq = cmp,
            __index = {
                expand = dummy
            },
        }
        local function expand(self)
            for k, v in pairs(self) do
                if type(v) == 'table' and v.expand then
                    v:expand()
                end
            end

            return setmetatable(self, metaCompDummy)
        end

        local metaComp = {
            __eq = cmp,
            __index = {
                expand = expand
            },
        }
        -- check if for the specific key is a parser available
        local metaParse = {
            __index = function(self, key)
                local parse = parse[key[1]]

                if parse then
                    self[key] = parse(key)
                end

                return setmetatable(self, metaComp)[key]
            end,
        }
        -- generate new meta tables if key not exists
        local function indexNew(self, key)
            local data = setmetatable({}, meta)

            self[key] = data

            return data
        end
        -- generate new  tables if key not exists
        local function indexSplit(self, key)
            local data = setmetatable({}, metaCompDummy)

            self[key] = data

            return data
        end
        -- parse lines and remove itself afterwards
        local function indexParse(self, key)
            meta.__index = nil
            -- only parse string entries
            if type(self[1]) == 'string' then
                meta.__index = indexSplit

                local output = setmetatable({}, meta)

                for i = 1, #self do
                    local line = self[i]:gsub("´", "'")
                    local dest = line:match('^[^\t]+')
                    local data = {dest}

                    for v in string.gmatch(line, '\t([^\t]*)') do
                        table.insert(data, v)
                    end

                    self[i] = nil

                    dest = output[tonumber(dest) or dest]

                    if #data < 3 then
                        v = data[2] or ''

                        table.insert(dest, tonumber(v) or v)
                    else
                        table.insert(dest, setmetatable(data, metaParse))
                    end
                end

                for k, v in pairs(output) do
                    self[k] = v
                end
            end
        
            meta.__index = indexParse

            return setmetatable(self, metaComp)[key]
        end

        return setmetatable(self, {
            __index = function(self, key)
                local success, lines = pcall(io.lines, key)

                if success then
                    meta.__index = indexNew

                    local dest = setmetatable({}, meta)
                    local end_string = nil
                    local stack = {}

                    for line in lines do
                        if line == end_string then
                            dest, end_string = table.unpack(table.remove(stack))
                        else
                            if line:match('^[^%w%s}]') then
                                table.insert(stack, {dest, end_string})

                                end_string = string.gsub(line, '[%w%s]+', function(key)
                                    for v in string.gmatch(key, '[^\t]+') do
                                        dest = dest[tonumber(v) or v]
                                    end

                                    return 'End'
                                end)
                            else
                                table.insert(dest, line)
                            end
                        end
                    end

                    meta.__index = indexParse

                    return (#stack > 0) and stack[1][1] or dest
                end
            end,
        })[key]
    end,
})