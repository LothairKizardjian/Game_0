-- Core Engine for Game_0
-- Handles scene management and game loop

local Engine = {}
local scenes = {}
local currentScene = nil

function Engine.init()
    scenes = {}
    currentScene = nil
end

function Engine.pushScene(scene)
    if currentScene then
        currentScene:onExit()
    end
    table.insert(scenes, scene)
    currentScene = scene
    scene:onEnter()
end

function Engine.popScene()
    if #scenes > 0 then
        local scene = table.remove(scenes)
        scene:onExit()
        currentScene = scenes[#scenes] or nil
        if currentScene then
            currentScene:onEnter()
        end
        return scene
    end
    return nil
end

function Engine.update(dt)
    if currentScene then
        currentScene:update(dt)
    end
end

function Engine.draw()
    if currentScene then
        currentScene:render()
    end
end

function Engine.keypressed(key)
    if currentScene then
        currentScene:keypressed(key)
    end
end

function Engine.keyreleased(key)
    if currentScene then
        currentScene:keyreleased(key)
    end
end

return Engine
