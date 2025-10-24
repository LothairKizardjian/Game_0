-- Input Manager for Game_0
-- Centralized input handling with key mapping and input buffering

local InputManager = {}
InputManager.__index = InputManager

function InputManager.new()
    local self = setmetatable({}, InputManager)
    
    -- Key states
    self.keys = {}
    self.keysPressed = {}
    self.keysReleased = {}
    
    -- Mouse states
    self.mouse = {
        x = 0, y = 0,
        buttons = {},
        buttonsPressed = {},
        buttonsReleased = {}
    }
    
    -- Input mapping
    self.keyMappings = {
        -- Movement
        up = {'w', 'up'},
        down = {'s', 'down'},
        left = {'a', 'left'},
        right = {'d', 'right'},
        
        -- Actions
        attack = {'space'},
        pause = {'escape', 'p'},
        
        -- UI
        select = {'enter', 'return'},
        cancel = {'escape'}
    }
    
    -- Input buffering
    self.inputBuffer = {}
    self.bufferTime = 0.2  -- 200ms buffer
    self.maxBufferSize = 10
    
    return self
end

function InputManager:update(dt)
    -- Clear pressed/released states
    self.keysPressed = {}
    self.mouse.buttonsPressed = {}
    self.mouse.buttonsReleased = {}
    
    -- Update input buffer
    for i = #self.inputBuffer, 1, -1 do
        local input = self.inputBuffer[i]
        input.time = input.time - dt
        if input.time <= 0 then
            table.remove(self.inputBuffer, i)
        end
    end
end

function InputManager:keypressed(key)
    self.keys[key] = true
    self.keysPressed[key] = true
    
    -- Add to input buffer
    table.insert(self.inputBuffer, {
        type = "key",
        key = key,
        time = self.bufferTime
    })
    
    -- Limit buffer size
    if #self.inputBuffer > self.maxBufferSize then
        table.remove(self.inputBuffer, 1)
    end
end

function InputManager:keyreleased(key)
    self.keys[key] = false
    self.keysReleased[key] = true
end

function InputManager:mousepressed(x, y, button)
    self.mouse.x = x
    self.mouse.y = y
    self.mouse.buttons[button] = true
    self.mouse.buttonsPressed[button] = true
end

function InputManager:mousereleased(x, y, button)
    self.mouse.x = x
    self.mouse.y = y
    self.mouse.buttons[button] = false
    self.mouse.buttonsReleased[button] = true
end

function InputManager:isKeyDown(key)
    return self.keys[key] == true
end

function InputManager:isKeyPressed(key)
    return self.keysPressed[key] == true
end

function InputManager:isKeyReleased(key)
    return self.keysReleased[key] == true
end

function InputManager:isMouseButtonDown(button)
    return self.mouse.buttons[button] == true
end

function InputManager:isMouseButtonPressed(button)
    return self.mouse.buttonsPressed[button] == true
end

function InputManager:isMouseButtonReleased(button)
    return self.mouse.buttonsReleased[button] == true
end

function InputManager:getMousePosition()
    return self.mouse.x, self.mouse.y
end

function InputManager:isActionDown(action)
    local keys = self.keyMappings[action]
    if not keys then return false end
    
    for _, key in ipairs(keys) do
        if self:isKeyDown(key) then
            return true
        end
    end
    return false
end

function InputManager:isActionPressed(action)
    local keys = self.keyMappings[action]
    if not keys then return false end
    
    for _, key in ipairs(keys) do
        if self:isKeyPressed(key) then
            return true
        end
    end
    return false
end

function InputManager:getMovementVector()
    local x, y = 0, 0
    
    if self:isActionDown('up') then y = y - 1 end
    if self:isActionDown('down') then y = y + 1 end
    if self:isActionDown('left') then x = x - 1 end
    if self:isActionDown('right') then x = x + 1 end
    
    -- Normalize diagonal movement
    if x ~= 0 and y ~= 0 then
        local length = math.sqrt(x*x + y*y)
        x = x / length
        y = y / length
    end
    
    return x, y
end

function InputManager:getBufferedInputs(inputType)
    local inputs = {}
    for _, input in ipairs(self.inputBuffer) do
        if input.type == inputType then
            table.insert(inputs, input)
        end
    end
    return inputs
end

function InputManager:clearBuffer()
    self.inputBuffer = {}
end

function InputManager:setKeyMapping(action, keys)
    self.keyMappings[action] = keys
end

function InputManager:getKeyMapping(action)
    return self.keyMappings[action]
end

return InputManager
