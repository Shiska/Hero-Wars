return setmetatable({}, {
    __index = function(self, key)
        local lfs = require('lfs')

        self.dir = function(...)
            local args = {...}
            local function yield(self, dir)
                local files = {}
                -- loop remaining files
                for entry in lfs.dir(dir) do
                    table.insert(files, entry)
                end

                local dir = dir .. '/'
                -- skip the first two
                table.remove(files, 1)
                table.remove(files, 1)
                -- loop remaining files
                for _, entry in ipairs(files) do
                    entry = dir .. entry

                    local attr = lfs.attributes(entry)

                    if attr then
                        coroutine.yield(entry, attr)

                        if attr.mode == 'directory' then
                            yield(self, entry)
                        end
                    end
                end
            end

            return coroutine.wrap(function() yield(table.unpack(args)) end)
        end

        self.mode = function(self, ...)
            local args = {self, ...}
            local function yield(self, dir, mode)
                for entry, attr in self:dir(dir) do
                    if attr.mode == mode then
                        coroutine.yield(entry, attr)
                    end
                end
            end

            return coroutine.wrap(function() yield(table.unpack(args)) end)
        end

        self.match = function(self, ...)
            local args = {self, ...}
            local function yield(self, dir, pattern)
                for entry, attr in self:dir(dir) do
                    if entry:match(pattern) then
                        coroutine.yield(entry, attr)
                    end
                end
            end

            return coroutine.wrap(function() yield(table.unpack(args)) end)
        end

        self.mkdir = function(self, dir)
            local folders = {}

            for folder in string.gmatch(dir, '[^/]+') do
                table.insert(folders, folder)

                lfs.mkdir(table.concat(folders, '/'))
            end
        end

        return setmetatable(self, nil)[key]
    end,
})