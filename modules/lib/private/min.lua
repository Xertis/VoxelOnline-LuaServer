require "std/stdmin"

local protect = require "lib/private/protect"
local hash = require "lib/private/hash"

local lib = {
    server = {},
    world = {},
    roles = {},
    validate = {},
    hash = hash
}

---WORLD---

function lib.world.preparation_main()
    --Загружаем мир
    local packs = table.freeze_unpack(CONFIG.game.content_packs)
    table.insert(packs, "server")

    app.config_packs(packs)
    app.load_content()

    if not file.exists("user:worlds/" .. CONFIG.game.main_world .. "/world.json") then
        logger.log("Creating a main world...")
        local name = CONFIG.game.main_world
        app.new_world(
            CONFIG.game.main_world,
            CONFIG.game.worlds[name].seed,
            CONFIG.game.worlds[name].generator
        )

        logger.log("Loading chunks...")
        player.create("server")
        local ctime = time.uptime()

        while world.count_chunks() < 12*CONFIG.server.chunks_loading_distance do
            app.tick()

            if ((time.uptime() - ctime) / 60) > 1 then
                logger.log("Chunk loading timeout exceeded, exiting. Try changing the chunks_loading_speed.", "W")
                break
            end
        end

        logger.log("Chunks loaded successfully.")

        app.close_world(true)
    end
end

function lib.world.open_main()
    logger.log("Discovery of the main world")
    app.open_world(CONFIG.game.main_world)
end

function lib.roles.is_higher(role1, role2)
    if role1.priority > role2.priority then
        return true
    end

    return false
end

function lib.roles.exists(role)
    return CONFIG.roles[role] and true or false
end

function lib.validate.username(name)
    name = name:lower()
    local alphabet = {
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
        'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',

        'а', 'б', 'в', 'г', 'д', 'е', 'ё', 'ж', 'з', 'и', 'й', 'к', 'л', 'м',
        'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ',
        'ъ', 'ы', 'ь', 'э', 'ю', 'я'
    }

    local numbers = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

    if #name > 16 then
        return false
    end

    if not table.has(alphabet, name[1]) and name[1] ~= '_' then
        return false
    end

    for i=2, #name do
        local char = name[i]

        if not table.has(alphabet, char) and not table.has(numbers, char) then
            return false
        end
    end

    return true
end

return protect.protect_return(lib)