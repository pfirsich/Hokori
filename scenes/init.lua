local scenes = {}

scenes.current = nil
scenes.list = {}

function scenes.enter(scene, ...)
    assert(scene, "Scene does not exist")
    if scenes.current then
        if scenes.current.exit then
            scenes.current.exit(scene)
        end
    end

    scenes.current = scene
    if scene.enter then
        scene.enter(...)
    end
end

function scenes.import()
    for _, item in ipairs(lf.getDirectoryItems("scenes")) do
        local path = "scenes/" .. item

        local reqPath = nil

        if lf.getInfo(path, "file") and item ~= "init.lua" then
            reqPath = "scenes." .. item:sub(1, -5)
        elseif lf.getInfo(path, "directory") then
            reqPath = "scenes." .. item
        end

        if reqPath then
            local scene = require(reqPath)
            scenes[scene.name] = scene
            scenes.list[scene.name] = scene
        end
    end
end

return scenes
