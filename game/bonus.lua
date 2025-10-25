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

    if self.id == "orbiting_blades" then
        -- Calculate blade count for current and new level
        local currentBlades = 3
        local newBlades = 3
        if self.level >= 5 then
            newBlades = newBlades + 1
        end
        if self.level >= 10 then
            newBlades = newBlades + 1
        end

        if currentDamage > 0 then
            -- Player already has this power - show upgrade
            local damageIncrease = newDamage - currentDamage
            return newBlades .. " blades orbit around you, dealing " .. currentDamage .. " ( + " .. damageIncrease .. " ) damage."
        else
            -- New power - show initial damage
            return newBlades .. " blades orbit around you, dealing " .. newDamage .. " damage."
        end
    elseif self.id == "meteor" then
        local currentRadius = currentDamage > 0 and (40 + (self.level - 2) * 10) or 40
        local newRadius = 40 + (self.level - 1) * 10
        local currentMeteors = currentDamage > 0 and math.min(5, math.floor(self.level / 2)) or 1
        local newMeteors = math.min(5, math.floor((self.level + 1) / 2))

        if currentDamage > 0 then
            -- Player already has this power - show upgrade
            local damageIncrease = newDamage - currentDamage
            return "Meteors fall from the sky dealing damage on impact. Radius: " .. newRadius .. "px, Meteors: " .. newMeteors .. "\n\nCurrent: " .. currentDamage .. " damage\nUpgrade to: " .. newDamage .. " damage"
        else
            -- New power - show initial damage
            return "Meteors fall from the sky dealing damage on impact. Radius: " .. newRadius .. "px, Meteors: " .. newMeteors .. "\n\nDamage: " .. newDamage
        end
    end

    -- Fallback for other powers
    if currentDamage > 0 then
        local damageIncrease = newDamage - currentDamage
        return self.description .. "\n\nCurrent: " .. currentDamage .. " damage\nUpgrade to: " .. newDamage .. " damage"
    else
        return self.description .. "\n\nDamage: " .. newDamage
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

-- Power definitions
local POWER_DEFINITIONS = {
    {id = "orbiting_blades", name = "Orbiting Blades", description = "3 blades orbit around you, dealing damage on contact. +1 blade at level 5, +1 blade at level 10", rarity = "rare", baseDamage = 2, baseRadius = 60},
    {id = "meteor", name = "Meteor", description = "Meteors fall from the sky dealing damage on impact. Radius: 40px, Meteors: 1", rarity = "epic", baseDamage = 3, baseRadius = 40}
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

    -- Calculate number of blades based on level
    local numBlades = 3  -- Base number of blades
    if self.level >= 5 then
        numBlades = numBlades + 1  -- +1 blade at level 5
    end
    if self.level >= 10 then
        numBlades = numBlades + 1  -- +1 blade at level 10
    end

    -- Create blades
    for i = 1, numBlades do
        table.insert(self.blades, {
            angle = (i - 1) * (2 * math.pi / numBlades),  -- Evenly spaced
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
    local numBlades = #self.blades
    for i, blade in ipairs(self.blades) do
        blade.angle = self.angle + (i - 1) * (2 * math.pi / numBlades)
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

-- Meteor Power Implementation
local Meteor = {}
Meteor.__index = Meteor

function Meteor.new(level)
    local self = setmetatable({}, Meteor)

    self.level = level or 1
    self.damage = 3 * self.level
    self.radius = 40 + (self.level - 1) * 10  -- Radius increases with level
    self.meteors = {}
    self.spawnTimer = 0
    self.spawnInterval = 2.0  -- Spawn every 2 seconds
    self.maxMeteors = math.min(5, math.floor((self.level + 1) / 2))  -- One meteor every 2 levels, max 5

    return self
end

function Meteor:update(dt, playerX, playerY, playerW, playerH, enemies)
    self.spawnTimer = self.spawnTimer + dt
    
    -- Debug output
    if self.spawnTimer >= self.spawnInterval then
        print("Meteor spawn check: timer=" .. self.spawnTimer .. ", interval=" .. self.spawnInterval .. ", meteors=" .. #self.meteors .. ", max=" .. self.maxMeteors)
    end
    
    -- Spawn meteors with delay between each
    if self.spawnTimer >= self.spawnInterval and #self.meteors < self.maxMeteors then
        -- Spawn one meteor at a time with delay
        print("Spawning meteor!")
        self:spawnMeteor(playerX, playerY)
        self.spawnTimer = 0
        -- Keep the interval at 0.3 for continuous spawning
        self.spawnInterval = 0.3  -- 0.3 second delay between meteors
    end

    -- Update existing meteors
    for i = #self.meteors, 1, -1 do
        local meteor = self.meteors[i]
        meteor.y = meteor.y + meteor.speed * dt

        -- Check if meteor hit ground or enemy
        if meteor.y >= meteor.targetY then
            -- Check for enemy hits
            for _, enemy in ipairs(enemies) do
                local dx = meteor.x - (enemy.x + enemy.w/2)
                local dy = meteor.y - (enemy.y + enemy.h/2)
                local distance = math.sqrt(dx*dx + dy*dy)

                if distance <= self.radius then
                    enemy:takeDamage(self.damage, love.timer.getTime())
                end
            end

            -- Remove meteor
            print("Meteor hit ground, removing. Count before: " .. #self.meteors)
            table.remove(self.meteors, i)
            print("Meteor removed. Count after: " .. #self.meteors)
        end
    end

    -- No need to reset spawn interval - keep it at 0.3 for continuous spawning
end

function Meteor:spawnMeteor(playerX, playerY)
    local meteor = {
        x = playerX + (math.random() - 0.5) * 200,  -- Random position around player
        y = -50,  -- Start above screen
        targetY = playerY + math.random(-50, 50),  -- Target near player
        speed = 200 + math.random(0, 100),  -- Random fall speed
        size = 8 + math.random(0, 4)  -- Random size
    }

    table.insert(self.meteors, meteor)
end

function Meteor:render()
    for _, meteor in ipairs(self.meteors) do
        -- Draw meteor
        love.graphics.setColor(1.0, 0.3, 0.1)  -- Orange-red color
        love.graphics.circle('fill', meteor.x, meteor.y, meteor.size)

        -- Draw meteor trail
        love.graphics.setColor(1.0, 0.6, 0.2)
        love.graphics.circle('fill', meteor.x, meteor.y - 10, meteor.size * 0.7)

        -- Draw impact area when close to ground
        if meteor.y >= meteor.targetY - 20 then
            love.graphics.setColor(1.0, 0.8, 0.0, 0.3)  -- Yellow impact area
            love.graphics.circle('fill', meteor.x, meteor.targetY, self.radius)
        end
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

    -- Offer random powers from available definitions
    for i = 1, count do
        local powerDef = POWER_DEFINITIONS[math.random(1, #POWER_DEFINITIONS)]

        -- Check if player already has this power
        local existingLevel = 1
        local isMaxLevel = false
        for _, existingPower in ipairs(self.playerPowers) do
            if existingPower.id == powerDef.id then
                if existingPower.level >= 10 then
                    isMaxLevel = true
                    break
                end
                existingLevel = math.min(10, existingPower.level + 1)  -- Cap at level 10
                break
            end
        end

        -- Skip if power is already at max level
        if not isMaxLevel then
            local power = Power.new(powerDef.id, powerDef.name, powerDef.description, powerDef.rarity, existingLevel)
            power.playerPowers = self.playerPowers  -- Pass player powers for damage calculation
            table.insert(self.powers, power)
        end
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

        -- Description with damage info
        local damageInfo = power:getDamageInfo()
        local descriptionText = power.description

        if damageInfo.hasUpgrade then
            descriptionText = descriptionText .. "\n\nCurrent: " .. damageInfo.current .. " damage\nUpgrade to: " .. (damageInfo.current + damageInfo.increase) .. " damage"
        else
            descriptionText = descriptionText .. "\n\nDamage: " .. damageInfo.current
        end

        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(descriptionText, x + 10, y + 80, 180, 'center')
    end
end

return {
    Power = Power,
    PowerSelection = PowerSelection,
    OrbitingBlades = OrbitingBlades,
    Meteor = Meteor,
    POWER_DEFINITIONS = POWER_DEFINITIONS,
    RARITY_COLORS = RARITY_COLORS
}