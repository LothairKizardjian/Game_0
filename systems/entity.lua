-- Entity System for Game_0
-- Simplified entity system for new power system

local Entity = {}
Entity.__index = Entity

function Entity.new(x, y, w, h, color, speed, hp, isPlayer)
    local self = setmetatable({}, Entity)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.color = color
    self.speed = speed
    self.hp = hp
    self.maxHp = hp
    self.isPlayer = isPlayer or false
    self.damageCooldown = 0
    self.lastDamageTime = 0

    -- Player-specific stats
    if isPlayer then
        self.level = 1
        self.xp = 0
        self.xpToNext = 10
        self.collectRadius = 40
        self.baseSpeed = speed
        self.baseMaxHp = hp
        self.damageReduction = 0
        self.xpMultiplier = 1.0
        self.speedMultiplier = 1.0
        self.collectRadiusMultiplier = 1.0
        self.enemiesKilled = 0
        self.lastHealthRegen = 0
        self.lastXPRain = 0
        self.lastGodMode = 0
        self.lastTeleport = 0
        self.damageImmunityTime = 0
        self.critChance = 0
        self.enemySlow = 0
        self.damageImmunity = 0
        self.thorns = 0
        self.lifeSteal = 0
        self.explosiveDeath = 0
        self.timeSlow = 1.0
        self.xpMagnet = 1.0
        self.immortality = false
        self.godMode = false
        self.xpRain = false
        self.teleport = false
        self.facingDirection = {x = 1, y = 0}
        self.speedBurst = 0
        self.speedBurstTime = 0

        -- New power system
        self.powers = {}
        self.orbitingBlades = nil
    end

    return self
end

function Entity:takeDamage(damage, currentTime)
    if not self.isPlayer then
        -- Enemy damage cooldown
        if currentTime - self.lastDamageTime < self.damageCooldown then
            return false
        end
    end

    -- Apply damage reduction for players
    if self.isPlayer and self.damageReduction > 0 then
        damage = damage * (1 - self.damageReduction)
    end

    self.hp = self.hp - damage
    self.lastDamageTime = currentTime

    if self.hp <= 0 then
        self.hp = 0
    end

    return true
end

function Entity:getHealthPercent()
    return self.hp / self.maxHp
end

function Entity:getRect()
    return {
        x = self.x,
        y = self.y,
        w = self.w,
        h = self.h
    }
end

function Entity:collidesWith(other)
    return self.x < other.x + other.w and
           self.x + self.w > other.x and
           self.y < other.y + other.h and
           self.y + self.h > other.y
end

function Entity:addXP(amount)
    if not self.isPlayer then return false end

    self.xp = self.xp + amount
    local leveledUp = false
    while self.xp >= self.xpToNext do
        leveledUp = self:levelUp() or leveledUp
    end
    return leveledUp
end

function Entity:levelUp()
    if not self.isPlayer then return false end

    self.level = self.level + 1
    self.xp = self.xp - self.xpToNext
    self.xpToNext = math.floor(self.xpToNext * 1.5)  -- Exponential growth

    -- Increase max HP slightly
    self.maxHp = self.maxHp + 5
    self.hp = self.maxHp  -- Full heal on level up

    return true
end

function Entity:applyPower(power)
    if not self.isPlayer then return end

    -- Check if player already has this power
    local existingPower = nil
    for i, existing in ipairs(self.powers) do
        if existing.id == power.id then
            existingPower = existing
            -- Upgrade existing power
            existing.level = existing.level + 1
            break
        end
    end

    -- If not found, add new power
    if not existingPower then
        table.insert(self.powers, power)
    end

    -- Apply power effects
    if power.id == "orbiting_blades" then
        if self.orbitingBlades then
            -- Upgrade existing orbiting blades
            self.orbitingBlades.level = self.orbitingBlades.level + 1
            self.orbitingBlades.damage = 2 * self.orbitingBlades.level
        else
            -- Create new orbiting blades
            local OrbitingBlades = require('game.bonus').OrbitingBlades
            self.orbitingBlades = OrbitingBlades.new(power.level)
        end
    end
end

function Entity:updatePowers(dt, enemies)
    if not self.isPlayer then return end

    -- Update orbiting blades
    if self.orbitingBlades then
        self.orbitingBlades:update(dt, self.x, self.y, self.w, self.h, enemies)
    end
end

function Entity:renderPowers()
    if not self.isPlayer then return end

    -- Render orbiting blades
    if self.orbitingBlades then
        self.orbitingBlades:render()
    end
end

return Entity