require("libs.slam")

local sounds = {}

local function src(file, volume, usage)
    local src = love.audio.newSource("media/sounds/" .. file, usage or "static")
    if volume then
        src:setVolume(volume)
    end
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

sounds.music = src("music.ogg", 0.05, "stream")
sounds.music:setLooping(true)
sounds.music:play()

return sounds
