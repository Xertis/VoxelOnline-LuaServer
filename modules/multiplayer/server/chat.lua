local protect = require "lib/private/protect"
local protocol = require "lib/public/protocol"
local server_echo = require "multiplayer/server/server_echo"
local sandbox = require "lib/private/sandbox/sandbox"
local switcher = require "lib/public/common/switcher"
local module = {}

local colors = {
    red = "[#ff0000]",
    yellow = "[#ffff00]",
    white = ""
}

local commands = switcher.new(function ( ... )
    local values = {...}
    local client = values[3]
    local command = values[1]

    local message = "Unknow command"
    module.tell(string.format("%s %s: %s", colors.red, message, command), client)
end)

commands:add_case("list", function ( ... )
    local values = {...}
    local client = values[3]
    local players = table.keys(sandbox.get_players())

    local message = "Online players"
    module.tell(string.format("%s %s: %s", colors.white, message, table.tostring(players)), client)

end)

commands:add_case("help", function ( ... )
    local values = {...}
    local client = values[3]
    local message = ''
    local messages= {
        "----- Help (.help) -----",
        ".help - Shows a list of available commands.",
        ".list - Shows a list of online players."
    }

    for _, m in ipairs(messages) do
        message = message .. m .. '\n'
    end

    module.tell(string.format("%s %s", colors.white, message), client)

end)

commands:add_case("register", function ( ... )
    local values = {...}
    local client = values[3]
    local account = client.account
    local passwords = values[2]

    if account.is_logged then
        module.tell(string.format("%s You are already logged in.", colors.yellow), client)
        return
    elseif account.password ~= nil then
        module.tell(string.format("%s Please log in using the command .login <password> to access your account.", colors.yellow), client)
        return
    end

    if passwords[1] ~= passwords[2] then
        module.tell(string.format("%s The passwords you entered do not match. Please try again using the command .register", colors.red), client)
        return
    end

    local status = account:set_password(passwords[1])

    if status == CODES.accounts.PasswordUnvalidated then
        module.tell(string.format("%s Your password does not meet the requirements, create a new one.", colors.red), client)
        return
    end

    account.is_logged = true
    module.tell(string.format("%s You have successfully registered!", colors.yellow), client)
end)

commands:add_case("login", function ( ... )
    local values = {...}
    local client = values[3]
    local account = client.account
    local password = values[2][1]

    if account.is_logged then
        module.tell(string.format("%s You are already logged in.", colors.yellow), client)
        return
    elseif account.password == nil then
        module.tell(string.format("%s Please register using the command .register <password> <confirm password> to secure your account.", colors.yellow), client)
        return
    end

    local status = account:check_password(password)
    if status == CODES.accounts.WrongPassword then
        module.tell(string.format("%s Incorrect password. Please try again using the command .login <password>.", colors.red), client)
        return
    end

    module.tell(string.format("%s You have successfully logged in!", colors.yellow), client)
end)

function module.echo(message)
    logger.log(message)
    server_echo.put_event(function (client)
        local buffer = protocol.create_databuffer()
        buffer:put_packet(protocol.build_packet("server", protocol.ServerMsg.ChatMessage, message))
        client.network:send(buffer.bytes)
    end)
end

function module.tell(message, client)
    local buffer = protocol.create_databuffer()
    buffer:put_packet(protocol.build_packet("server", protocol.ServerMsg.ChatMessage, message))
    client.network:send(buffer.bytes)
end

function module.command(message, client)
    if message[1] ~= '.' then
        return
    end

    message = string.sub(message, 2)
    local args = string.split(message, " ")
    local executable = args[1]
    table.remove(args, 1)

    commands:switch(executable, executable, args, client)
end

return protect.protect_return(module)