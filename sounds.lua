require("libs.slam")

local sounds = {}

local function src(file, volume, usage)
    local src = love.audio.newSource("media/sounds/" .. file, usage or "static")
    if volume then
        src:setVolume(volume)
    end
    return src
end

sounds.dash = src("dash.wav", 0.15)
sounds.strike  = src("strike.wav")
sounds.tackle = src("tackle.wav")
sounds.strikeBlock = src("strikeBlock.wav", 0.3)
--sounds.strikeHit = src("strikeHit.wav")
--sounds.tackleHit = src("tackleHit.wav")
sounds.die = src("die.wav")

sounds.music = src("music.ogg", 0.05, "stream")
sounds.music:setLooping(true)
sounds.music:play()

return sounds
