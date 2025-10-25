-- Pause Menu Scene for Game_0
-- Handles pause menu with resume and exit options

local PauseMenu = {}
PauseMenu.__index = PauseMenu

-- Colors
local COLOR_BG = {0.1, 0.1, 0.15}
local COLOR_UI = {0.9, 0.9, 0.9}
local COLOR_BUTTON = {0.3, 0.3, 0.4}
local COLOR_BUTTON_HOVER = {0.4, 0.4, 0.5}

function PauseMenu.new()
    local self = setmetatable({}, PauseMenu)
    
    -- Calculate button positions based on screen size
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local buttonWidth = 200
    local buttonHeight = 50
    local buttonX = (screenW - buttonWidth) / 2
    
    self.buttons = {
        {
            text = "Resume",
            x = buttonX,
            y = screenH / 2 - 30,
            width = buttonWidth,
            height = buttonHeight,
            action = "resume"
        },
        {
            text = "Exit",
            x = buttonX,
            y = screenH / 2 + 30,
            width = buttonWidth,
            height = buttonHeight,
            action = "exit"
        }
    }
    
    self.hoveredButton = nil
    self.font = nil
    self.titleFont = nil
    
    return self
end

function PauseMenu:load()
    self.font = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(32)
end

function PauseMenu:update(dt)
    -- Update button hover states
    local mouseX, mouseY = love.mouse.getPosition()
    self.hoveredButton = nil
    
    for _, button in ipairs(self.buttons) do
        if mouseX >= button.x and mouseX <= button.x + button.width and
           mouseY >= button.y and mouseY <= button.y + button.height then
            self.hoveredButton = button
            break
        end
    end
end

function PauseMenu:keypressed(key)
    if key == 'escape' then
        return "resume"
    end
end

function PauseMenu:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        for _, button in ipairs(self.buttons) do
            if x >= button.x and x <= button.x + button.width and
               y >= button.y and y <= button.y + button.height then
                return button.action
            end
        end
    end
end

function PauseMenu:render()
    -- Semi-transparent background
    love.graphics.setColor(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3], 0.8)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    local screenW = love.graphics.getWidth()
    love.graphics.printf("PAUSED", 0, 100, screenW, 'center')
    
    -- Instructions
    love.graphics.setFont(self.font)
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.printf("Press ESC to resume", 0, 150, screenW, 'center')
    
    -- Buttons
    for _, button in ipairs(self.buttons) do
        local color = COLOR_BUTTON
        if button == self.hoveredButton then
            color = COLOR_BUTTON_HOVER
        end
        
        -- Button background
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle('fill', button.x, button.y, button.width, button.height)
        
        -- Button border
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle('line', button.x, button.y, button.width, button.height)
        
        -- Button text
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, button.x, button.y + 15, button.width, 'center')
    end
end

return PauseMenu
