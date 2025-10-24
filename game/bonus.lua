-- Object-Oriented Power System for Game_0
-- Clean, modular power system with leveling

local PowerSystem = {}

-- Power base class
local Power = {}
Power.__index = Power

function Power.new(id, name, description, rarity, level)
    local self = setmetatable({}, Power)

    self.id = id
    self.name = name
    self.description = description
    self.rarity = rarity
    self.level = level or 1

    return self
end

function Power:getDisplayName()
    return self.name .. " (Level " .. self.level .. ")"
end

function Power:getScaledValue(baseValue)
    return baseValue * self.level
end

function Power:getCurrentDamage()
    -- Get current damage if player already has this power
    for _, existingPower in ipairs(self.playerPowers or {}) do
        if existingPower.id == self.id then
            return existingPower:getScaledValue(2)  -- Base damage is 2
        end
    end
    return 0  -- Player doesn't have this power yet
end

function Power:getNewDamage()
    -- Get damage after leveling up
    return self:getScaledValue(2)  -- Base damage is 2
end

function Power:getEnhancedDescription()
    local currentDamage = self:getCurrentDamage()
    local newDamage = self:getNewDamage()

    if currentDamage > 0 then
        -- Player already has this power - show upgrade
        local damageIncrease = newDamage - currentDamage
        return "3 blades orbit around you, dealing " .. currentDamage .. " ( + " .. damageIncrease .. " ) damage."
    else
        -- New power - show initial damage
        return "3 blades orbit around you, dealing " .. newDamage .. " damage."
    end
end

function Power:getDamageInfo()
    local currentDamage = self:getCurrentDamage()
    local newDamage = self:getNewDamage()

    if currentDamage > 0 then
        local damageIncrease = newDamage - currentDamage
        return {
            current = currentDamage,
            increase = damageIncrease,
            hasUpgrade = true
        }
    else
        return {
            current = newDamage,
            increase = 0,
            hasUpgrade = false
        }
    end
end

-- Rarity colors
local RARITY_COLORS = {
    common = {0.7, 0.7, 0.7},
    rare = {0.2, 0.6, 1.0},
    epic = {0.6, 0.2, 1.0},
    legendary = {1.0, 0.6, 0.0},
    godly = {1.0, 1.0, 1.0}
}

-- Power definitions - Only Orbiting Blades for now
local POWER_DEFINITIONS = {
    {id = "orbiting_blades", name = "Orbiting Blades", description = "3 blades orbit around you, dealing damage on contact", rarity = "rare", baseDamage = 2, baseRadius = 60}
}

-- Orbiting Blades Power Implementation
local OrbitingBlades = {}
OrbitingBlades.__index = OrbitingBlades

function OrbitingBlades.new(level)
    local self = setmetatable({}, OrbitingBlades)

    self.level = level or 1
    self.damage = 2 * self.level
    self.radius = 60
    self.speed = 2.0  -- Rotation speed in radians per second
    self.angle = 0
    self.blades = {}

    -- Create 3 blades
    for i = 1, 3 do
        table.insert(self.blades, {
            angle = (i - 1) * (2 * math.pi / 3),  -- 120 degrees apart
            x = 0,
            y = 0,
            size = 8
        })
    end

    return self
end

function OrbitingBlades:update(dt, playerX, playerY, playerW, playerH, enemies)
    self.angle = self.angle + self.speed * dt

    local centerX = playerX + playerW / 2
    local centerY = playerY + playerH / 2

    -- Update blade positions
    for i, blade in ipairs(self.blades) do
        blade.angle = self.angle + (i - 1) * (2 * math.pi / 3)
        blade.x = centerX + math.cos(blade.angle) * self.radius
        blade.y = centerY + math.sin(blade.angle) * self.radius
    end

    -- Check collisions with enemies
    for _, blade in ipairs(self.blades) do
        for _, enemy in ipairs(enemies) do
            local dx = blade.x - (enemy.x + enemy.w/2)
            local dy = blade.y - (enemy.y + enemy.h/2)
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance < blade.size + enemy.w/2 then
                -- Hit enemy
                enemy:takeDamage(self.damage, love.timer.getTime())
            end
        end
    end
end

function OrbitingBlades:render()
    for _, blade in ipairs(self.blades) do
        -- Draw blade
        love.graphics.setColor(0.8, 0.2, 0.2)  -- Red blade
        love.graphics.circle('fill', blade.x, blade.y, blade.size)

        -- Draw blade outline
        love.graphics.setColor(1, 0.4, 0.4)
        love.graphics.circle('line', blade.x, blade.y, blade.size)
    end
end

-- Power Selection System
local PowerSelection = {}
PowerSelection.__index = PowerSelection

function PowerSelection.new(playerPowers)
    local self = setmetatable({}, PowerSelection)

    self.powers = {}
    self.selectedPower = nil
    self.font = nil
    self.titleFont = nil
    self.playerPowers = playerPowers or {}

    return self
end

function PowerSelection:generatePowers(count)
    self.powers = {}

    -- For now, only offer Orbiting Blades
    for i = 1, count do
        local powerDef = POWER_DEFINITIONS[1]  -- Only orbiting blades for now

        -- Check if player already has this power
        local existingLevel = 1
        for _, existingPower in ipairs(self.playerPowers) do
            if existingPower.id == powerDef.id then
                existingLevel = existingPower.level + 1
                break
            end
        end

        local power = Power.new(powerDef.id, powerDef.name, powerDef.description, powerDef.rarity, existingLevel)
        power.playerPowers = self.playerPowers  -- Pass player powers for damage calculation
        table.insert(self.powers, power)
    end
end

function PowerSelection:onEnter()
    self.font = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(24)
end

function PowerSelection:update(dt)
    -- Power selection doesn't need update logic
end

function PowerSelection:keypressed(key)
    if key == '1' then
        self.selectedPower = self.powers[1]
    elseif key == '2' then
        self.selectedPower = self.powers[2]
    elseif key == '3' then
        self.selectedPower = self.powers[3]
    end
end

function PowerSelection:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Check which power was clicked
        for i, power in ipairs(self.powers) do
            local powerX = 50 + (i - 1) * 250
            local powerY = 150

            if x >= powerX and x <= powerX + 200 and y >= powerY and y <= powerY + 300 then
                self.selectedPower = power
                break
            end
        end
    end
end

function PowerSelection:render()
    love.graphics.clear(0.1, 0.1, 0.15)

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Choose a Power", 0, 50, 800, 'center')

    -- Instructions
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Click a power to select, or press 1, 2, or 3", 0, 100, 800, 'center')

    -- Display powers
    for i, power in ipairs(self.powers) do
        local x = 50 + (i - 1) * 250
        local y = 150

        -- Power box
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle('fill', x, y, 200, 300)

        -- Rarity border
        local color = RARITY_COLORS[power.rarity]
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle('line', x, y, 200, 300)

        -- Power name with level
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(power:getDisplayName(), x, y + 20, 200, 'center')

        -- Rarity
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.printf(power.rarity:upper(), x, y + 50, 200, 'center')

        -- Description with colored damage info
        local damageInfo = power:getDamageInfo()
        local baseDescription = "3 blades orbit around you, dealing "
        local damageText = ""
        
        -- Debug output
        print("Power damage info: current=" .. damageInfo.current .. ", increase=" .. damageInfo.increase .. ", hasUpgrade=" .. tostring(damageInfo.hasUpgrade))
        
        if damageInfo.hasUpgrade then
            damageText = damageInfo.current .. " ( + " .. damageInfo.increase .. " ) damage."
        else
            damageText = damageInfo.current .. " damage."
        end
        
        print("Damage text: " .. damageText)
        
        -- Render the complete description with mixed colors
        local fullText = baseDescription .. damageText
        
        -- Render base description in gray
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(baseDescription, x + 10, y + 80)
        
        -- Calculate position for damage text (right after base description)
        local baseWidth = love.graphics.getFont():getWidth(baseDescription)
        local damageX = x + 10 + baseWidth
        
        -- Render damage text in bright blue for visibility
        love.graphics.setColor(0.0, 0.8, 1.0)  -- Bright blue color
        love.graphics.print(damageText, damageX, y + 80)
        
        -- Debug: Draw a rectangle around the damage text area
        love.graphics.setColor(1.0, 0.0, 0.0)  -- Red debug rectangle
        love.graphics.rectangle('line', damageX, y + 75, love.graphics.getFont():getWidth(damageText), 20)

        -- Key indicator
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Press " .. i, x, y + 250, 200, 'center')
    end
end

return {
    Power = Power,
    PowerSelection = PowerSelection,
    OrbitingBlades = OrbitingBlades,
    POWER_DEFINITIONS = POWER_DEFINITIONS,
    RARITY_COLORS = RARITY_COLORS
}