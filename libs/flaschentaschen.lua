local ffi = require("ffi")
local socket = require("socket")

local flaschentaschen = {}

local sock = nil
local rgbBytes = nil
local pixelCount = nil
local connected = false

local lastFrame = nil

function flaschentaschen.initialize(_pixelCount, host, port)
    host = host or "localhost"
    port = port or 1337

    pixelCount = _pixelCount
    rgbBytes = ffi.new("unsigned char[?]", pixelCount * 3)

    sock = socket.udp()
    sock:settimeout(0)

    connected = sock:setpeername(host, port)

    if not connected then
        print("Couldn't connect to RGBServer on " .. host .. ":" .. port .. "!")
    else
        print("Connected to RGBServer " .. host .. ":" .. port .. "!")
    end
end

function flaschentaschen.sendCanvas(canvas)
    if connected then
        local imageData = canvas:newImageData()
        local rgba = ffi.cast("unsigned char *", imageData:getPointer())

        for i=0, pixelCount-1 do
            rgbBytes[i * 3 + 0] = rgba[i * 4 + 0]
            rgbBytes[i * 3 + 1] = rgba[i * 4 + 1]
            rgbBytes[i * 3 + 2] = rgba[i * 4 + 2]
        end

        local data = "P6 " .. imageData:getWidth() .. " " .. imageData:getHeight() ..
            " 255\n" .. ffi.string(rgbBytes, pixelCount * 3)
        sock:send(data)
        lastFrame = data
    end
end

function flaschentaschen.saveLastFrame(filename)
    if lastFrame then
        local file = assert(love.filesystem.newFile(filename, "w"))
        assert(file:write(lastFrame))
        assert(file:close())
        print("Saved last frame.")
    end
end

return flaschentaschen
