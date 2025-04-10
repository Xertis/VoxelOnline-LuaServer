local protect = require "lib/private/protect"
local container = require "lib/private/common/container"
local Player = require "lib/private/sandbox/classes/player"
local metadata = require "lib/private/files/metadata"
local module = {
    by_username = {}
}

function module.join_player(account)
    local account_player = container.player_online.get(account.username) or Player.new(account.username)

    local status = account_player:revive()

    if status == CODES.players.ReviveSuccess or status == CODES.players.WithoutChanges then
        -- Ну мы его разбудили правильно, ничего делать не надо, мы молодцы
    elseif status == CODES.players.DataLoss then
        local pid = player.create(account_player.username, table.count_pairs(metadata.players.get_all())+1)
        logger.log(string.format('Player "%s" has been created with pid: %s', account.username, pid))
        account_player:set("pid", pid)
        account_player:set("entity_id", player.get_entity(account_player.pid))

        local y = 0
        while block.get(0, y, 0) ~= 0 and block.get(0, y, 0) ~= -1 do
            y = y + 1
        end

        player.set_pos(account_player.pid, 0, y+1, 0)

        account:set("world", CONFIG.game.main_world)
        account_player:set("active", true)
    end

    if account_player:is_active() then
        container.player_online.put(account_player.username, account_player)
    end

    logger.log(string.format('Player "%s" is join.', account_player.username))
    account_player:save()

    if player.is_suspended(account_player.pid) then
        player.set_suspended(account_player.pid, false)
    end

    return account_player
end

function module.leave_player(account_player)
    account_player:abort()

    logger.log(string.format('Player "%s" is leave.', account_player.username))

    container.player_online.put(account_player.username, nil)

    player.set_suspended(account_player.pid, true)

    return account_player
end

function module.get_players()
    return container.player_online.get()
end

function module.get_player(account)
    return container.player_online.get(account.username)
end

function module.get_chunk(pos)
    return world.get_chunk_data(pos.x, pos.z)
end

function module.place_block(block_state, pid)
    if type(block_state.id)[1] == 's' then
        block_state.id = block.index(block_state.id)
    end

    block.place(block_state.x, block_state.y, block_state.z, block_state.id, block_state.states, pid)

    if block_state.rotation then
        block.set_rotation(block_state.x, block_state.y, block_state.z, block_state.rotation)
    end
end

function module.destroy_block(pos, pid)
    block.destruct(pos.x, pos.y, pos.z, pid)
end

function module.set_player_state(account_player, state)
    if state.x and state.y and state.z then
        player.set_pos(account_player.pid, state.x, state.y, state.z)
    end

    if state.yaw and state.pitch then
        player.set_rot(account_player.pid, state.yaw, state.pitch, 0)
    end

    if state.noclip ~= nil and state.flight ~= nil then
        player.set_noclip(account_player.pid, state.noclip)
        player.set_flight(account_player.pid, state.flight)
    end
end

function module.get_player_state(account_player)
    local x, y, z = player.get_pos(account_player.pid)
    local yaw, pitch = player.get_rot(account_player.pid, true)
    local noclip = player.is_noclip(account_player.pid)
    local flight = player.is_flight(account_player.pid)

    return {
        x = x,
        y = y,
        z = z,
        yaw = yaw,
        pitch = pitch,
        noclip = noclip,
        flight = flight
    }
end

function module.set_day_time(time)
    if time == "day" then
        time = 0.5
    elseif time == "night" then
        time = 0
    elseif type(time)[1] ~= 'n' and not tonumber(time) then
        return false
    end

    time = math.normalize(tonumber(time))
    world.set_day_time(time)
    return true
end

function module.by_username.is_online(name)
    if module.get_players()[name] then
        return true
    end

    return false
end

return protect.protect_return(module)