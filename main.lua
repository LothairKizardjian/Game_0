-- Game_0 - Love2D Roguelike
-- Entry point for the Love2D version

local Engine = require('core.engine')
local RogueScene = require('game.scene')
local Config = require('systems.config')
local Performance = require('systems.performance')

-- Initialize performance monitoring
local performance = Performance.new()

function love.load()
    -- Initialize configuration
    Config.init()
    
    -- Initialize the engine
    Engine.init()
    Engine.pushScene(RogueScene.new())
end

function love.update(dt)
    -- Update performance monitoring
    performance:update(dt)
    
    -- Smooth delta time for better physics
    local smoothedDt = performance:getSmoothedDeltaTime()
    Engine.update(smoothedDt)
end

function love.draw()
    Engine.draw()
    
    -- Render performance info if enabled
    if Config.get('RENDERING', 'SHOW_FPS', false) then
        performance:render()
    end
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
