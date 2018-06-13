-- if you are missing something you want to tweak
-- => const.lua has all the constants in the game!
-- => input.lua defines keys for control sets

local env = {
    STAB_MODE = false,

    FT_IP = "localhost",
    FT_PORT = 1337,
}

env.FLASCHENTASCHEN = env.STAB_MODE
env.CONTROL_SET = env.STAB_MODE and "stab" or "keyboard"
env.ENTRY_SCENE = env.STAB_MODE and "game" or "mainmenu"

return env
