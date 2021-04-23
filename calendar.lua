local module = {}

function timestamp(t)
    return os.date("%Y%m%d", t) -- full fandom timestamp YYYYMMDDHHmmss
end

function now() -- Guild day - WEB / Mobile
    local d = os.date('!*t')
    -- using os.time() - 2 * 60 * 60 is undefined behaviour
    d.hour = d.hour - 2 -- UTC -2 ()
    -- according to the lua reference os.time can return any value, no guarantee that it is in seconds
    return os.date('!*t', os.time(d)) -- refetch table if hours got below 0
end

local date = setmetatable({}, {
    __call = function(self, params)
        local createDate
        local meta = {
            __call = function(self, params)
                if params then
                    return createDate{
                        year = params.year or 0,
                        month = params.month or 0,
                        day = params.day or 0,
                    }
                end
            end,
            __add = function(a, b)
                return createDate{
                    year =  a.year  + b.year,
                    month = a.month + b.month,
                    day =   a.day   + b.day,
                }
            end,
            __sub = function(a, b)
                return createDate{
                    year =  a.year  - b.year,
                    month = a.month - b.month,
                    day =   a.day   - b.day,
                }
            end,
            __mul = function(a, b)
                return createDate{
                    year =  a.year  * b,
                    month = a.month * b,
                    day =   a.day   * b,
                }
            end,
            __lt = function(a, b)
                return a.time < b.time
            end,
            __le = function(a, b)
                return a.time <= b.time
            end,
        }
        meta.__index = meta
        createDate = function(t)
            local success, result = pcall(os.time, t)

            if(success) then
                t = os.date('*t', result)
                t.time = result
            end

            return setmetatable(t, meta)
        end

        return setmetatable(self, meta)(params)
    end
})

local event = setmetatable({}, {
    __call = function(self, params)
        local meta = {}

        meta.__call = function(self, params)
            local obj = {}

            for k, v in pairs(params) do
                obj[k] = v
            end

            obj.start = date(obj.start)
            obj.duration = date(obj.duration)
            obj.interval = date(obj.interval)

            if obj.start then
                obj['end'] = obj.start + obj.duration
            end

            return setmetatable(obj, meta)
        end

        meta.setStart = function(self, start)
            self.start = date(start)
            self['end'] = self.start + self.duration

            return self
        end

        meta.__index = meta

        return setmetatable(self, meta)(params)
    end
})

local calendar = setmetatable({}, {
    __call = function(self, params)
        local meta = {}
        local oneDay = date{day = 1}

        meta.__call = function(self, params)
            local cdata = {}
            local self = event({
                name = 'calendar',
                start = params.start,
                duration = params.duration,
            })
            self.data = cdata
            -- fill timespan with empty tables
            local cstart = self.start
            local cend = self['end']

            while cstart < cend do
                local t = {}
                local stamp = cstart.time
                -- reference by index
                table.insert(cdata, {stamp, t})
                -- reference by key
                cdata[stamp] = t
                cstart = cstart + oneDay
            end

            return setmetatable(self, meta)
        end

        local insertEvent = function(dest, event, estart, eend)
            local day = 0 -- counting event days

            while estart < eend do
                local d = dest[estart.time]

                if d then
                    table.insert(d, event)

                    event[estart.time] = day -- saving which day of the event this timestamp represent
                end

                estart = estart + oneDay
                day = day + 1
            end

            event.lastDay = day - 1
        end

        meta.add = function(self, event)
            local cstart = self.start
            local cend = self['end']
            local cdata = self.data

            local estart = event.start
            local einterval = event.interval
            local eend = event['end']

            if einterval then
                local eduration = event.duration
                -- loop until first occurrence, kinda inefficient
                -- but easier than reducing years / months to days
                while eend <= cstart do
                    eend = eend + einterval
                end

                estart = eend - eduration
                -- loop event until out of timespan
                while estart < cend do
                    insertEvent(cdata, event, estart, eend)

                    eend = eend + einterval
                    estart = eend - eduration
                end
            else
                if cstart < eend and estart < cend then
                    insertEvent(cdata, event, estart, eend)
                end
            end

            return self
        end

        meta.__index = meta

        return setmetatable(self, meta)(params)
    end
})

function fillCalendar(params)
    local calendar = calendar(params)

    for _, e in ipairs(params.data) do
        local start = e.start

        if start then
            e.start = nil
            e = event(e)
    
            for _, s in pairs(start) do
                calendar:add(e:setStart(s))
            end
        end
    end

    return calendar
end

function module.calendar(frame, args)
    frame = frame or mw.getCurrentFrame()

    local fargs = args or frame.args or {}
    local now = now()
    local calendar = fillCalendar{
        start = {
            year =  fargs.start_year  or now.year,
            month = fargs.start_month or now.month,
            day =   fargs.start_day   or now.day,
        },
        duration = {
            year =  fargs.duration_year  or nil,
            month = fargs.duration_month or nil,
            day =   fargs.duration_day   or nil,
        },
        data = require('Module:' .. (fargs.data or 'Calendar/Data')),
    }
    local rows = {}
    local data = calendar.data

    local istart, iend, istep

    if fargs.reverse == "true" then
        istart = #data
        iend = 1
        istep = -1
    else
        istart = 1
        iend = #data
        istep = 1
    end

    for i = istart, iend, istep do
        local data = data[i]
        local stamp = data[1]
        local entries = data[2]

        for k, v in ipairs(entries) do
            entries[k] = frame:expandTemplate{title = 'Calendar/Entry', args = {
                event = v.name,
                short = v.short,
                button = v.button and string.gsub(v.button, '%$(.-)%$', os.date('*t', stamp)),
                days = v.lastDay - v[stamp] + 1,
            }}
        end

        table.insert(rows, frame:expandTemplate{title = 'Calendar/Row', args = {
            timestamp = timestamp(stamp),
            entries = table.concat(entries),
        }})
    end

    return frame:expandTemplate{title = 'DataTable', args = {
        style = "text-align: left;",
        content = table.concat(rows),
    }}
end

function formatDuration(t)
    if t then
        local output = {}

        for k, v in pairs(t) do
            if v == 1 then
                table.insert(output, '1 ' .. k)
            else
                table.insert(output, string.format('%s %ss', v, k))
            end
        end

        table.sort(output)

        return table.concat(output, ', ')
    end

    return nil
end

function addHistory(history, frame, start, interval, duration)
    local start = start or  {}

    if interval then
        local today = date(now())
        local step = date(interval)

        for _, v in ipairs(start) do
            local d = date(v)

            while d <= today do
                history[timestamp(os.time(d))] = duration

                d = d + step
            end
        end
    else
        for _, v in ipairs(start) do
            history[timestamp(os.time(v))] = duration
        end
    end
end

function formatHistory(history, frame)
    table.sort(history)

    local params = {title = 'Calendar/History'}

    for k, v in ipairs(history) do
        params.args = {v, duration = history[v]}
        history[k] = frame:expandTemplate(params)
    end

    return table.concat(history)
end

function module.infobox(frame)
    local fargs = frame.args or {}
    local data = require('Module:' .. (fargs.data or 'Calendar/Data'))
    local name = fargs.title
    local title = name

    local duration = {}
    local recurrence = {}
    local history = setmetatable({}, {
        __newindex = function(self, key, value)
            table.insert(self, key)

            return rawset(self, key, value)
        end,
    })
    for _, v in ipairs(data) do
        if v.name == name then
            local interval = v.interval
            local fduration = formatDuration(v.duration)

            table.insert(duration, fduration)
            table.insert(recurrence, formatDuration(interval))
            
            addHistory(history, frame, v.start, interval, fduration)
            title = v.short or short
        end
    end

    local args = {
        title = title,
        recurrence = table.concat(recurrence, fargs.sep),
    }
    if #history > 0 then
        args.history = formatHistory(history, frame)
    else
        args.duration = table.concat(duration, fargs.sep)
    end

    for k, v in pairs(frame:getParent().args) do
        args[k] = v
    end
    
    return frame:expandTemplate{title = 'infobox_event', args = args}
end

function module.list(frame)
    local args = frame.args or {}
    local data = require('Module:' .. (args.data or 'Calendar/Data'))

    local params = {title = 'l'}
    local events = setmetatable({}, {
        __newindex = function(self, key, value)
            params.args = {'Special Events/' .. key}

            table.insert(self, frame:expandTemplate(params))

            return rawset(self, key, true)
        end,
    })

    for _, v in ipairs(data) do
        events[v.name] = true
    end

    table.sort(events)

    return table.concat{args.before or '', table.concat(events, args.concat), args.after or ''}
end

function module.table(frame, args)
    frame = frame or mw.getCurrentFrame()

    local args = args or frame:getParent().args
    local params = {}

    for k, v in ipairs(args) do
        params[k] = v
    end

    local length = #params
    local columns = tonumber(args.cols)
    local div = length / columns
    local dfloor = math.floor(div)
    local dceil = math.ceil(div)

    if dfloor ~= dceil then
        error(string.format('Uneven partition, found %d entries, expected %d or %d', length, dfloor * columns, dceil * columns))
    end

    local count = {}
    local output = {}
    local trim = mw.text.trim
    local expand = {title = 'DataTable/Row'}

    for i = columns + 1, length, columns do
        local args = {type1 = 'header', unpack(params, i, i + columns - 1)}

        for k, v in ipairs(args) do
            v = trim(v)

            if v ~= '-' then
                count[k] = (count[k] or 0) + (tonumber(v) or 1)
            end
        end

        expand.args = args
        table.insert(output, frame:expandTemplate(expand))
    end

    expand.args = {['type'] = 'header', 'Total', unpack(count, 2)}
    table.insert(output, frame:expandTemplate(expand))

    return frame:expandTemplate{
        title = 'DataTable',
        args = {style = 'table-layout:fixed', content = table.concat(output), unpack(params, 1, columns)},
    }
end

function module.total(frame, args)
    frame = frame or mw.getCurrentFrame()

    local args = args or frame:getParent().args

    if args.ignore then
        return
    end

    local params = {}

    for k, v in ipairs(args) do
        params[k] = v
    end

    local length = #params
    local trim = mw.text.trim
    local columns = tonumber(args.cols)
    -- security checks are done in function table, hoping that noone saves bad tables ^^
    local count = {}

    for i = columns + 1, length, columns do
        local args = {unpack(params, i, i + columns - 1)}

        for k, v in ipairs(args) do
            v = trim(v)

            if v ~= '-' then
                count[k] = (count[k] or 0) + (tonumber(v) or 1)
            end
        end
    end

    local header = {unpack(params, 1, columns)}

    for k, v in pairs(header) do
        header[k] = trim(v)
    end

    for k, v in ipairs(count) do
        count[k] = string.format('\t%s=%s', header[k], v)
    end

    table.remove(count, 1) -- first column doesn't matter

    return table.concat(count)
end

function module.rewards(frame, args)
    frame = frame or mw.getCurrentFrame()

    local args = args or frame.args
    local data = frame:callParserFunction{name = '#dpl', args = {
        '', -- necessary for callParserFunction
        title = args.title or mw.title.getCurrentTitle().text,
        skipthispage = 'false',
        include = '{Event/Quests/Entry¦Event/Quests/Total}',
    }}
    local count = setmetatable({}, {
        __index = function(self, key)
            table.insert(self, key)

            return 0
        end,
    })
    for key, value in string.gmatch(data, '\t([^=]+)=([^\t]+)') do
        count[key] = count[key] + tonumber(value)
    end

    table.sort(count)

    local form = args.format or '%count% %item%'

    for k, v in ipairs(count) do
        count[k] = form:gsub('%%(%w+)%%', {count = count[v], item = v})
    end

    return table.concat(count, args.sep)
end

return module
