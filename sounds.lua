require("libs.slam")

local sounds = {}

local function src(file, usage)
    return love.audio.newSource("media/sounds/" .. file, usage or "static")
end

sounds.dash = src("dash.wav")
sounds.dash:setVolume(0.15)
sounds.strike  = src("strike.wav")
sounds.tackle = src("tackle.wav")
sounds.strikeBlock = src("strikeBlock.wav")
--sounds.strikeHit = src("strikeHit.wav")
--sounds.tackleHit = src("tackleHit.wav")
sounds.die = src("die.wav")

sounds.music = src("music.ogg", "stream")
sounds.music:setLooping(true)
sounds.music:setVolume(0.05)
sounds.music:play()

return sounds
