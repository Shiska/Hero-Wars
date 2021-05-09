local module = {}

function module.set(frame, args, pargs)
    frame = frame or mw.getCurrentFrame()

    local args = args or frame.args
    local parent = frame:getParent()

    if parent then
        local pargs = pargs or parent.args

        if pargs.template then
            local eargs = {}
            local platform = pargs.platform

            if platform then
                platform = platform:lower()

                for k, v in pairs(args) do
                    local p, arg = k:match('([^_]+)_(.+)')

                    if not p then -- copy values that don't match
                        eargs[k] = v
                    else
                        if p:lower() == platform then
                            eargs[arg] = v
                        end
                    end
                end
            else
                for k, v in pairs(args) do
                    eargs[k] = v
                end
            end

            if pargs.sort then
                table.sort(eargs)
            end

            for k, v in pairs(pargs) do
                eargs[k] = v
            end

            return frame:expandTemplate{title = pargs.template, args = eargs}
        end

        local func = pargs.func

        if pargs.module then
            return require('Module:' .. pargs.module)[func](frame)
        end

        if func then
            return module[func](frame)
        end

        local output = {}

        for _, v in ipairs(pargs) do
            table.insert(output, string.format('\t%s=%s', v, args[v] or ''))
        end

        if #output == 0 then
            for k, v in pairs(args) do
                table.insert(output, string.format('\t%s=%s', k, v))
            end
        end

        return table.concat(output)
    end

    return frame:expandTemplate{title = args.template, args = args}
end

function module.swap(frame)
    frame = frame or mw.getCurrentFrame()

    local args = frame.args
    local parent = frame:getParent() or {}
    local pargs = parent.args

    if args[1] then -- calls a set template which calls swap template with the new parameters
        local output = {}
        -- concat all parent parameters, similar to set/get
        for k, v in pairs(pargs) do
            table.insert(output, string.format('%s=%s', k, v))
        end

        return frame:expandTemplate{title = args[1], args = {
            template = args[2],
            swap_template = args[3],
            parent = table.concat(output, '\t'),
        }}
    end

    if pargs.swap_template then
        return frame:expandTemplate{title = pargs.swap_template, args = args}
    end

    local data = pargs.parent
    local pargs = {}

    rawset(pargs, string.match(data, '([^=]+)=([^\t]+)'))

    for k, v in string.gmatch(data, '\t([^=]+)=([^\t]+)') do
        pargs[k] = v
    end

    return module.set(frame, args, pargs)
end

function module.get(frame, args)
    if args then
        local data = frame:expandTemplate{title = ':' .. args.title, args = args}
        local output = {}

        for k, v in string.gmatch(data, '\t([^=]+)=([^\t]+)') do
            output[k] = v
        end

        return output
    end

    frame = frame or mw.getCurrentFrame()

    local args = frame.args

    if args.src then
        local eargs = module.get(frame, {title = args.src})

        for k, v in pairs(args) do
            eargs[k] = v
        end

        return frame:expandTemplate{title = args.dest, args = eargs}
    end

    return frame:expandTemplate{title = ':' .. args.title, args = args}
end

function module.loop(frame)
    frame = frame or mw.getCurrentFrame()

    local output = {}
    local args = frame:getParent().args

    local pargs = {}
    local params = {title = args.loop_template or args.template, args = pargs}

    for k, v in pairs(args) do
        pargs[k] = v
    end

    pargs[2] = nil

    local count = 1

    for k, v in ipairs(args) do
        pargs[1] = v
        pargs.index = k
        pargs.count = count

        local expand = frame:expandTemplate(params)

        if expand ~= '' then
            table.insert(output, expand)
            count = count + 1
        end
    end

    return table.concat{args.before or '', table.concat(output, args.sep), args.after or ''}
end

function module.transfer(frame)
    frame = frame or mw.getCurrentFrame()

    local fargs = frame.args
    local template = fargs.template
    local pargs = frame:getParent().args

    if template then
        local args = {}
        local match = fargs.match

        if match then
            for k, v in pairs(pargs) do
                local m = k:match(match)

                if k:match(match) then
                    args[k] = v
                end
            end
        else
            for k, v in pairs(pargs) do
                args[k] = v
            end
        end

        for k, v in pairs(fargs) do
            args[k] = v
        end

        return frame:expandTemplate{title = template, args = args}
    end

    local func = fargs.func

    if func then
        if fargs.module then
            return require('Module:' .. fargs.module)[func](frame, pargs)
        end

        return module[func](frame, pargs)
    end
end

function module.concat(frame)
    frame = frame or mw.getCurrentFrame()

    local args = frame.args
    local vargs = {}

    for k, v in ipairs(args) do
        if v ~= '' then
            table.insert(vargs, table.concat{args[k .. '_before'] or '', v, args[k .. '_after'] or ''})
        end
    end

    return table.concat(vargs, args.sep)
end

function module.list(frame)
    frame = frame or mw.getCurrentFrame()

    local fargs = frame.args
    local pargs = frame:getParent().args
    local key = fargs.key or ''
    local form = key:format(1)
    local list, value = {}

    if form == key then
        key = key .. '%d'
        value = pargs[key:format(1)]
    else
        value = pargs[form]
    end

    while value do
        table.insert(list, value)

        value = pargs[key:format(#list + 1)]
    end

    if fargs.sort then
        table.sort(list)
    end

    local template = fargs.template

    if template then
        local args = {}
        local params = {title = template, args = args}

        for k, v in pairs(pargs) do
            args[k] = v
        end

        for k, v in pairs(fargs) do
            args[k] = v
        end

        for k, v in ipairs(list) do
            args[1] = v
            args.index = k

            list[k] = frame:expandTemplate(params)
        end
    end

    return table.concat(list, fargs.sep)
end

function module.match(frame)
    frame = frame or mw.getCurrentFrame()

    local args = frame.args
    local pargs = frame:getParent().args

    function call()
        local eargs = {}

        for k, v in pairs(pargs) do
            eargs[k] = v
        end
        --  prioritise local args
        for k, v in pairs(args) do
            eargs[k] = v
        end

        return frame:expandTemplate{title = pargs.match_template, args = eargs}
    end

    local match = pargs.match

    local k = 1
    local key = pargs['key' .. k]

    if key == '' then
        if pargs[1]:match(match) then
            return call()
        end
    else
        while key do
            local form = key:format(1)

            if form == key then
                local value = args[key]

                if value and value:match(match) then
                    return call()
                end
            else
                local v, value = 1, args[form]

                while value do
                    if value:match(match) then
                        return call()
                    end

                    v = v + 1
                    value = args[key:format(v)]
                end
            end

            k = k + 1
            key = pargs['key' .. k]
        end
    end
end

function module.combine(frame)
    local args = {}
    local get = module.get
    local fargs = frame.args

    for k, v in ipairs(fargs) do
        local key = (fargs['key' .. k] or k) .. '_'

        for k, v in pairs(get(frame, {title = v})) do
            args[key .. k] = v
        end
    end

    return module.set(frame, args)
end

function module.split(frame)
    local pargs = frame:getParent().args
    local template = pargs.split_template
    local sep = pargs.sep

    if template and sep then
        local fargs = frame.args
        local output = {}
        local eargs = {}

        for k, v in pairs(pargs) do
            eargs[k] = v
        end

        local params = {title = template, args = eargs}
        local pattern = '([^' .. sep .. ']+)'

        for k, v in ipairs(pargs) do
            local value = fargs[v] or ''
            local args = {v}

            for s in string.gmatch(value, pattern) do
                table.insert(args, s)
            end

            for k, v in ipairs(args) do
                eargs[k] = v
            end

            eargs.index = k

            table.insert(output, frame:expandTemplate(params))
        end

        return table.concat(output)
    end
end

function module.log(frame)
    for k, v in pairs(frame.args) do
        mw.log(k, v)
    end

    for k, v in pairs((frame:getParent() or {}).args) do
        mw.log(k, v)
    end
end

function module.dpl(frame, args)
    args[1] = '' -- necessary for callParserFunction
    args.format = args.format or ',%PAGE%,\t,'

    local data = (frame or mw.getCurrentFrame()):callParserFunction{name = '#dpl', args = args}
    local output = {}

    for v in string.gmatch(data, '[^\t]+') do
        table.insert(output, v)
    end

    return output
end

function module.dump(frame, args)
    local output = {}
    local args = frame:getParent().args

    for k, v in pairs(args) do
        table.insert(output, string.format('\t%s=%s', k, v))
    end

    return table.concat(output)
end


function module.dpl_get(frame, args)
    args[1] = '' -- necessary for callParserFunction
    args.format = args.format or ',\1%PAGE%\1,,'

    local data = (frame or mw.getCurrentFrame()):callParserFunction{name = '#dpl', args = args}
    local trim = mw.text.trim
    local output = {}

    for page, params in string.gmatch(data, '\1([^\1]*)\1([^\1]*)') do
        local args = {}

        for key, value in string.gmatch(params, '\t([^=]+)=([^\t]+)') do
            args[key] = value
        end

        output[page] = args
    end

    return output
end

function module.dpl_expand(frame, args)
    frame = frame or mw.getCurrentFrame()

    if not args then
        args = {}

        for k, v in pairs(frame.args) do
            args[k] = v
        end
    end

    local output = module.dpl(frame, args)
    local params = {args = args}

    for k, v in ipairs(output) do
        params.title = ':' .. v
        args.title = v

        output[k] = frame:expandTemplate(params)
    end

    return table.concat(output)
end

function module.test(args)
    local frame = mw.getCurrentFrame()

    function test(name, func, iterations)
        local t = os.clock()
        for i = 1, iterations do func() end
        t = os.clock() - t
        mw.log(string.format('%s (time: %.2f, it/t: %.2f)', name, t, iterations / t))
    end

    function get()
        local output= {}
        local heroes = module.dpl(frame, {
            uses = "Template:Infobox Hero",
            --format = '{{loop|loop_template = Hero/Gist|template = Data,|%PAGE%,\t,}}'
            --format = ',{{:%PAGE%|template = Infobox_Hero/Glyphs}},,'
        })
        for _, v in ipairs(heroes) do
            output[v] = frame:expandTemplate{title = ':' .. v, args = {template = 'Infobox_Hero/Glyphs'}}
        end

        return output
    end

    function dpl_get()
        return module.dpl_get(frame, {
            uses = "Template:Infobox Hero",
            include = "{<includeonly>#invoke:Data|Infobox_Hero/Glyphs}"
        })
    end

    local iterations = tonumber((args or {})[1] or 1)

    test('get', get, iterations)
    test('dpl_get', dpl_get, iterations)
end

return module
