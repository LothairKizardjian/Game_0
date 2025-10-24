-- Game Over Scene for Game_0
-- Handles game over screen with restart and exit options

local GameOverScene = {}
GameOverScene.__index = GameOverScene

-- Colors
local COLOR_BG = {12/255, 12/255, 16/255}
local COLOR_UI = {230/255, 230/255, 230/255}
local COLOR_BUTTON = {80/255, 200/255, 120/255}
local COLOR_BUTTON_HOVER = {100/255, 220/255, 140/255}

function GameOverScene.new(finalLevel, finalXP, enemiesKilled)
    local self = setmetatable({}, GameOverScene)

    self.finalLevel = finalLevel or 1
    self.finalXP = finalXP or 0
    self.enemiesKilled = enemiesKilled or 0

    self.buttons = {
        {
            text = "New Game",
            x = 300,
            y = 300,
            width = 200,
            height = 50,
            action = "restart"
        },
        {
            text = "Exit",
            x = 300,
            y = 370,
            width = 200,
            height = 50,
            action = "exit"
        }
    }

    self.hoveredButton = nil
    self.font = nil
    self.titleFont = nil

    return self
end

function GameOverScene:onEnter()
    self.font = love.graphics.newFont(18)
    self.titleFont = love.graphics.newFont(32)
end

function GameOverScene:onExit()
    -- Cleanup if needed
end

function GameOverScene:keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'return' or key == 'space' then
        if self.hoveredButton then
            self:handleButtonClick(self.hoveredButton.action)
        end
    end
end

function GameOverScene:keyreleased(key)
    -- Not needed for game over screen
end

function GameOverScene:update(dt)
    local mx, my = love.mouse.getPosition()

    -- Check button hover
    self.hoveredButton = nil
    for _, button in ipairs(self.buttons) do
        if mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height then
            self.hoveredButton = button
            break
        end
    end
end

function GameOverScene:render()
    love.graphics.clear(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3])

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.printf("GAME OVER", 0, 100, 800, 'center')

    -- Stats
    love.graphics.setFont(self.font)
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.printf("Final Level: " .. self.finalLevel, 0, 180, 800, 'center')
    love.graphics.printf("Experience: " .. self.finalXP, 0, 210, 800, 'center')
    love.graphics.printf("Enemies Defeated: " .. self.enemiesKilled, 0, 240, 800, 'center')

    -- Buttons
    for _, button in ipairs(self.buttons) do
        local color = COLOR_BUTTON
        if button == self.hoveredButton then
            color = COLOR_BUTTON_HOVER
        end

        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle('fill', button.x, button.y, button.width, button.height)

        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(button.text, button.x, button.y + 15, button.width, 'center')
    end

    -- Instructions
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.printf("Click a button or use ENTER/SPACE", 0, 450, 800, 'center')
    love.graphics.printf("Press ESC to exit", 0, 480, 800, 'center')
end

function GameOverScene:handleButtonClick(action)
    if action == "restart" then
        -- This will be handled by the engine
        return "restart"
    elseif action == "exit" then
        love.event.quit()
    end
end

function GameOverScene:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        if self.hoveredButton then
            local result = self:handleButtonClick(self.hoveredButton.action)
            if result == "restart" then
                -- Restart the game
                local Engine = require('core.engine')
                local RogueScene = require('game.scene_refactored')
                Engine.init()
                Engine.pushScene(RogueScene.new())
            end
        end
    end
end

return GameOverScene
