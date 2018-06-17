require("libs.slam")
local const = require("const")

local sounds = {}

local function src(files, volume, usage)
    if type(files) ~= "table" then
        files = {files}
    end
    for i, file in ipairs(files) do
        files[i] = "media/sounds/" .. file
    end
    local src = love.audio.newSource(files, usage or "static")
    if volume then
        src:setVolume(volume)
    end
    return src
end

local function dummySrc()
    local noop = function() end
    local src = {play = noop}
    return src
end

local function prepare(name, ...)
    sounds[name] = src(name .. ".wav", ...)
end

prepare("dash", 0.15)
prepare("strike")
prepare("tackle")
prepare("strikeBlock", 0.3)
--prepare("strikeHit")
--prepare("tackleHit")
prepare("die")
prepare("menu")

sounds.counter = dummySrc({"voice/kaunta1.wav", "voice/kaunta2.wav"})
sounds.punish = dummySrc({"voice/punish1.wav", "voice/punish2.wav", "voice/punish3.wav"})
sounds.yomi = dummySrc({"voice/puredictable1.wav", "voice/puredictable2.wav"})
sounds.fight = dummySrc({"voice/fight1.wav", "voice/fight2.wav"})

sounds.music = src("music.ogg", const.musicVolume, "stream")
sounds.music:setLooping(true)
sounds.music:play()

return sounds
