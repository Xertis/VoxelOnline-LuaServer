function start_require(path)
    if not string.find(path, ':') then
        local prefix, _ = parse_path(debug.getinfo(2).source)
        return start_require(prefix..':'..path)
    end

    local old_path = path
    local prefix, file = parse_path(path)
    path = prefix..":modules/"..file..".lua"

    if not _G["/$p"] then
        return require(old_path)
    end

    return _G["/$p"][path]
end

local server_echo = start_require("server:multiplayer/server/server_echo")
local protocol = start_require("server:lib/public/protocol")

local function upd(blockid, x, y, z, playerid)
    local data = {
        x,
        y,
        z,
        block.get_states(x, y, z),
        block.get(x, y, z),
        playerid
    }

    server_echo.put_event(
        function (client)
            if client.active ~= true then
                return
            end

            local buffer = protocol.create_databuffer()
            buffer:put_packet(protocol.build_packet("server", protocol.ServerMsg.BlockChanged, unpack(data)))
            client.network:send(buffer.bytes)
        end
    )
end


function on_block_placed( ... )
    upd(...)
end

function on_block_broken( ... )
    upd(...)
end

events.on("server:block_interact", function (...)
    upd(...)
end)

