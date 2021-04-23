local module = {}

function module.pie(frame)
    local content = {}
    local args = { start = 0 }
    local pargs = frame:getParent().args
    local params = {title = 'PieChart/Entry', args = args}

    for k, v in ipairs(pargs) do
        local value = tonumber(v)

        if value > 0 then
            args.color = pargs['color' .. k]
            args.text = pargs['text' .. k]
            args.diff = value
    
            table.insert(content, frame:expandTemplate(params))

            args.start = args.start + args.diff
        end
    end

    if pargs.rest1 then
        local diff = 100 - args.start

        if diff > 0 then
            local r = 1
            local sum = 0
            local rest = {}
            local value = tonumber(pargs.rest1)
            -- find sum of all rest values
            while value do
                table.insert(rest, value)

                r = r + 1
                sum = sum + value
                value = tonumber(pargs['rest' .. r])
            end
            -- get the rest and divide through the sum
            if sum > 0 then
                sum = diff / sum
                -- distribute the rest by each value
                for r, value in ipairs(rest) do
                    if value > 0 then
                        local key = string.format('rest%d_', r)
            
                        args.color = pargs[key .. 'color']
                        args.text = pargs[key .. 'text']
                        args.diff = sum * value

                        table.insert(content, frame:expandTemplate(params))

                        args.start = args.start + args.diff
                    end
                end
            end
        end
    end

    local eargs = {
        content = table.concat(content)
    }
    for k, v in pairs(pargs) do
        eargs[k] = v
    end

    return frame:expandTemplate{title = 'PieChart', args = eargs}
end

return module