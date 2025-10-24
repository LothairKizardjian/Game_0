-- Game_0 - Love2D Roguelike
-- Entry point for the Love2D version

local Engine = require('core.engine')
local RogueScene = require('game.scene_refactored')

function love.load()
    -- Set window properties
    love.window.setTitle("Game_0")
    love.window.setMode(800, 576) -- Fixed screen size for larger world

    -- Initialize the engine
    Engine.init()
    Engine.pushScene(RogueScene.new())
end

function love.update(dt)
    Engine.update(dt)
end

function love.draw()
    Engine.draw()
end

function love.keypressed(key)
    Engine.keypressed(key)
end

function love.keyreleased(key)
    Engine.keyreleased(key)
end

function love.mousepressed(x, y, button)
    Engine.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Engine.mousereleased(x, y, button)
end
