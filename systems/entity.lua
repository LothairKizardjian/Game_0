-- Entity System for Game_0
-- Handles all entity-related functionality

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
        self.bonuses = {}
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
        self.baseAutoAttackCooldown = 0.5
        self.multiStrike = 1
        self.chainLightning = 0
        self.explosiveAttack = 0
        self.speedBurst = 0
        self.speedBurstTime = 0

        -- Magical Powers
        self.fireball = false
        self.iceShard = false
        self.lightningBolt = false
        self.meteor = false
        self.arcaneMissile = false
        self.shadowBolt = false

        -- Power cooldowns
        self.fireballCooldown = 0
        self.iceShardCooldown = 0
        self.lightningBoltCooldown = 0
        self.meteorCooldown = 0
        self.arcaneMissileCooldown = 0
        self.shadowBoltCooldown = 0

        -- Animation properties
        self.animationTime = 0
        self.animations = {}
    end

    return self
end

function Entity:getRect()
    return {x = self.x, y = self.y, w = self.w, h = self.h}
end

function Entity:collidesWith(other)
    return self.x < other.x + other.w and
           self.x + self.w > other.x and
           self.y < other.y + other.h and
           self.y + self.h > other.y
end

function Entity:takeDamage(damage, currentTime)
    if currentTime - self.lastDamageTime < self.damageCooldown then
        return false
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

    self.xp = self.xp - self.xpToNext
    self.level = self.level + 1
    self.xpToNext = math.floor(self.xpToNext * 1.5)

    -- Heal player on level up
    self.hp = self.maxHp

    return true
end

function Entity:applyBonus(bonus)
    if not self.isPlayer then return end

    -- Check if player already has this bonus
    local existingBonus = nil
    for i, existing in ipairs(self.bonuses) do
        if existing.id == bonus.id then
            existingBonus = existing
            -- Upgrade existing bonus
            existing.level = existing.level + 1
            -- Recalculate all bonus effects
            self:recalculateBonusEffects()
            return
        end
    end

    -- If not found, add new bonus
    table.insert(self.bonuses, bonus)

    -- Apply bonus effects (only for new bonuses, upgrades are handled by level increase)
    if not existingBonus then
        if bonus.effect == "max_health" then
            self.maxHp = self.maxHp + bonus:getScaledValue()
            self.hp = self.hp + bonus:getScaledValue()
        elseif bonus.effect == "speed_mult" then
            self.speedMultiplier = self.speedMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "damage_reduction" then
            self.damageReduction = self.damageReduction + bonus:getScaledValue()
        elseif bonus.effect == "xp_mult" then
            self.xpMultiplier = self.xpMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "health_regen" then
            self.healthRegen = bonus:getScaledValue()
        elseif bonus.effect == "collect_radius_mult" then
            self.collectRadiusMultiplier = self.collectRadiusMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "crit_chance" then
            self.critChance = self.critChance + bonus:getScaledValue()
        elseif bonus.effect == "enemy_slow" then
            self.enemySlow = bonus:getScaledValue()
        elseif bonus.effect == "damage_immunity" then
            self.damageImmunity = bonus:getScaledValue()
        elseif bonus.effect == "thorns" then
            self.thorns = self.thorns + bonus:getScaledValue()
        elseif bonus.effect == "speed_burst" then
            self.speedBurst = bonus:getScaledValue()
        elseif bonus.effect == "life_steal" then
            self.lifeSteal = self.lifeSteal + bonus:getScaledValue()
        elseif bonus.effect == "explosive_death" then
            self.explosiveDeath = self.explosiveDeath + bonus:getScaledValue()
        elseif bonus.effect == "time_slow" then
            self.timeSlow = self.timeSlow - bonus:getScaledValue()
        elseif bonus.effect == "xp_magnet" then
            self.xpMagnet = self.xpMagnet + bonus:getScaledValue()
        elseif bonus.effect == "immortality" then
            self.immortality = true
        elseif bonus.effect == "god_mode" then
            self.godMode = true
        elseif bonus.effect == "xp_rain" then
            self.xpRain = bonus:getScaledValue()
        elseif bonus.effect == "teleport" then
            self.teleport = true
        elseif bonus.effect == "multi_strike" then
            self.multiStrike = self.multiStrike + bonus:getScaledValue()
        elseif bonus.effect == "chain_lightning" then
            self.chainLightning = self.chainLightning + bonus:getScaledValue()
        elseif bonus.effect == "explosive_attack" then
            self.explosiveAttack = self.explosiveAttack + bonus:getScaledValue()
        elseif bonus.effect == "fireball" then
            self.fireball = true
        elseif bonus.effect == "ice_shard" then
            self.iceShard = true
        elseif bonus.effect == "lightning_bolt" then
            self.lightningBolt = true
        elseif bonus.effect == "meteor" then
            self.meteor = true
        elseif bonus.effect == "arcane_missile" then
            self.arcaneMissile = true
        elseif bonus.effect == "shadow_bolt" then
            self.shadowBolt = true
        end
    end
end

function Entity:recalculateBonusEffects()
    if not self.isPlayer then return end

    -- Reset all bonus effects to base values
    self.speedMultiplier = 1.0
    self.damageReduction = 0
    self.xpMultiplier = 1.0
    self.collectRadiusMultiplier = 1.0
    self.critChance = 0
    self.enemySlow = 0
    self.damageImmunity = 0
    self.thorns = 0
    self.speedBurst = 0
    self.lifeSteal = 0
    self.explosiveDeath = 0
    self.timeSlow = 1.0
    self.xpMagnet = 1.0
    self.multiStrike = 1
    self.chainLightning = 0
    self.explosiveAttack = 0
    self.xpRain = 0

    -- Reapply all bonuses
    for _, bonus in ipairs(self.bonuses) do
        if bonus.effect == "max_health" then
            self.maxHp = self.baseMaxHp + bonus:getScaledValue()
        elseif bonus.effect == "speed_mult" then
            self.speedMultiplier = self.speedMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "damage_reduction" then
            self.damageReduction = self.damageReduction + bonus:getScaledValue()
        elseif bonus.effect == "xp_mult" then
            self.xpMultiplier = self.xpMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "health_regen" then
            self.healthRegen = bonus:getScaledValue()
        elseif bonus.effect == "collect_radius_mult" then
            self.collectRadiusMultiplier = self.collectRadiusMultiplier + bonus:getScaledValue()
        elseif bonus.effect == "crit_chance" then
            self.critChance = self.critChance + bonus:getScaledValue()
        elseif bonus.effect == "enemy_slow" then
            self.enemySlow = bonus:getScaledValue()
        elseif bonus.effect == "damage_immunity" then
            self.damageImmunity = bonus:getScaledValue()
        elseif bonus.effect == "thorns" then
            self.thorns = self.thorns + bonus:getScaledValue()
        elseif bonus.effect == "speed_burst" then
            self.speedBurst = bonus:getScaledValue()
        elseif bonus.effect == "life_steal" then
            self.lifeSteal = self.lifeSteal + bonus:getScaledValue()
        elseif bonus.effect == "explosive_death" then
            self.explosiveDeath = self.explosiveDeath + bonus:getScaledValue()
        elseif bonus.effect == "time_slow" then
            self.timeSlow = self.timeSlow - bonus:getScaledValue()
        elseif bonus.effect == "xp_magnet" then
            self.xpMagnet = self.xpMagnet + bonus:getScaledValue()
        elseif bonus.effect == "multi_strike" then
            self.multiStrike = self.multiStrike + bonus:getScaledValue()
        elseif bonus.effect == "chain_lightning" then
            self.chainLightning = self.chainLightning + bonus:getScaledValue()
        elseif bonus.effect == "explosive_attack" then
            self.explosiveAttack = self.explosiveAttack + bonus:getScaledValue()
        elseif bonus.effect == "xp_rain" then
            self.xpRain = bonus:getScaledValue()
        end
    end
end

return Entity
