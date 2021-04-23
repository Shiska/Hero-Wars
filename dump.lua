local ldir = require('dir')
local proto = require('proto')

function dump(t, output, indent)
    indent = indent or 0
    output = output or {}

    local indentStr1 = string.rep('  ', indent)

    table.insert(output, '{\n')

    indent = indent + 1

    local indentStr2 = string.rep('  ', indent)
    for k, v in pairs(t) do
        table.insert(output, string.format('%s["%s"]: ', indentStr2, k))

        if type(v) == 'table' then
            dump(v, output, indent)
        else
            if type(v) == 'string' then
                table.insert(output, table.concat{'"', v, '",\n'})
            else
                table.insert(output, v .. ',\n')
            end
        end
    end

    table.insert(output, indentStr1 .. '},\n')

    return output
end

function dumpProtoDir(dest, dir, extension)
    dest = dest .. '/'

    for file, attr in ldir:mode(dir, 'directory') do
        lfs.mkdir(dest .. file)
    end

    for file, attr in ldir:match(dir, '.' .. extension .. '$') do
        local dest = dest .. file

        print(file, dest)

        local proto = proto[file]:expand()
        local data = table.concat(dump(proto))

        ldir:mkdir(dest:match('^.*/'))

        local file = io.open(dest, 'w')

        if file then
            file:write(data)
            file:close()
        end
    end
end

dumpProtoDir('dest', 'src', 'proto')
dumpProtoDir('dest', 'src', 'txt')