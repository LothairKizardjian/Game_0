-- Game_0 - Love2D Roguelike
-- Entry point for the Love2D version

local Engine = require('core.engine')
local RogueScene = require('game.scene')

function love.load()
    -- Set window properties
    love.window.setTitle("Game_0")
    love.window.setMode(800, 576) -- 25x18 tiles at 32px each

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
