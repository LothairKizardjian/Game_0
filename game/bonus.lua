-- Bonus System for Game_0
-- Handles bonuses with different rarities and effects

local Bonus = {}
Bonus.__index = Bonus

-- Rarity definitions
local RARITIES = {
    common = {name = "Common", color = {0.7, 0.7, 0.7}, weight = 50},
    rare = {name = "Rare", color = {0.2, 0.6, 1.0}, weight = 25},
    epic = {name = "Epic", color = {0.6, 0.2, 1.0}, weight = 15},
    legendary = {name = "Legendary", color = {1.0, 0.6, 0.0}, weight = 8},
    godly = {name = "Godly", color = {1.0, 0.2, 0.2}, weight = 2}
}

-- Bonus definitions
local BONUS_DEFINITIONS = {
    -- Common bonuses
    {id = "health_boost", name = "Vitality", description = "+2 Max Health", rarity = "common", effect = "max_health", value = 2},
    {id = "speed_boost", name = "Swiftness", description = "+20% Movement Speed", rarity = "common", effect = "speed_mult", value = 0.2},
    {id = "damage_reduction", name = "Toughness", description = "+1 Damage Reduction", rarity = "common", effect = "damage_reduction", value = 1},
    {id = "xp_boost", name = "Wisdom", description = "+25% XP Gain", rarity = "common", effect = "xp_mult", value = 0.25},

    -- Rare bonuses
    {id = "health_regen", name = "Regeneration", description = "Heal 1 HP every 3 seconds", rarity = "rare", effect = "health_regen", value = 1},
    {id = "collect_radius", name = "Magnetism", description = "+50% Collect Radius", rarity = "rare", effect = "collect_radius_mult", value = 0.5},
    {id = "crit_chance", name = "Precision", description = "10% Chance to deal 2x damage", rarity = "rare", effect = "crit_chance", value = 0.1},
    {id = "enemy_slow", name = "Chill", description = "Enemies move 20% slower", rarity = "rare", effect = "enemy_slow", value = 0.2},

    -- Epic bonuses
    {id = "double_xp", name = "Scholar", description = "Double XP from enemies", rarity = "epic", effect = "xp_mult", value = 1.0},
    {id = "damage_immunity", name = "Fortress", description = "Immune to damage for 2s after taking damage", rarity = "epic", effect = "damage_immunity", value = 2.0},
    {id = "enemy_damage", name = "Thorns", description = "Deal 1 damage to enemies that touch you", rarity = "epic", effect = "thorns", value = 1},
    {id = "speed_burst", name = "Dash", description = "Gain 50% speed for 1s after killing enemy", rarity = "epic", effect = "speed_burst", value = 0.5},

    -- Legendary bonuses
    {id = "life_steal", name = "Vampirism", description = "Heal 1 HP for each enemy killed", rarity = "legendary", effect = "life_steal", value = 1},
    {id = "explosive_death", name = "Detonation", description = "Enemies explode on death, dealing 2 damage", rarity = "legendary", effect = "explosive_death", value = 2},
    {id = "time_slow", name = "Chronos", description = "Time moves 30% slower", rarity = "legendary", effect = "time_slow", value = 0.3},
    {id = "xp_magnet", name = "Attraction", description = "XP shards move 3x faster to you", rarity = "legendary", effect = "xp_magnet", value = 3.0},

    -- Godly bonuses
    {id = "immortality", name = "Divine Protection", description = "Cannot die while above 1 HP", rarity = "godly", effect = "immortality", value = 1},
    {id = "god_mode", name = "Divine Wrath", description = "Deal 5 damage to all enemies every 2 seconds", rarity = "godly", effect = "god_mode", value = 5},
    {id = "xp_rain", name = "Divine Blessing", description = "Gain 1 XP every second", rarity = "godly", effect = "xp_rain", value = 1},
    {id = "teleport", name = "Divine Movement", description = "Teleport to random location every 5 seconds", rarity = "godly", effect = "teleport", value = 5},

    -- New Offensive Bonuses
    {id = "attack_damage", name = "Power Strike", description = "+1 Attack Damage", rarity = "common", effect = "auto_attack_damage", value = 1},
    {id = "attack_range", name = "Long Reach", description = "+20% Attack Range", rarity = "common", effect = "auto_attack_range", value = 0.2},
    {id = "attack_speed", name = "Quick Strike", description = "-0.1s Attack Cooldown", rarity = "rare", effect = "auto_attack_speed", value = 0.1},
    {id = "attack_angle", name = "Wide Arc", description = "+20% Attack Angle", rarity = "rare", effect = "auto_attack_angle", value = 0.2},
    {id = "piercing_attack", name = "Piercing Strike", description = "Attack pierces through enemies", rarity = "epic", effect = "piercing_attack", value = 1},
    {id = "multi_strike", name = "Double Strike", description = "Attack twice per use", rarity = "epic", effect = "multi_strike", value = 1},
    {id = "chain_lightning", name = "Chain Lightning", description = "Attack chains to nearby enemies", rarity = "legendary", effect = "chain_lightning", value = 3},
    {id = "explosive_attack", name = "Explosive Strike", description = "Attack creates explosion on impact", rarity = "legendary", effect = "explosive_attack", value = 2},
    
    -- Magical Powers
    {id = "fireball", name = "Fireball", description = "Cast fireballs at enemies (Q key)", rarity = "common", effect = "fireball", value = 1},
    {id = "ice_shard", name = "Ice Shard", description = "Cast ice shards that slow enemies (E key)", rarity = "rare", effect = "ice_shard", value = 1},
    {id = "lightning_bolt", name = "Lightning Bolt", description = "Cast lightning that chains between enemies (R key)", rarity = "epic", effect = "lightning_bolt", value = 1},
    {id = "meteor", name = "Meteor", description = "Summon meteors from the sky (T key)", rarity = "legendary", effect = "meteor", value = 1},
    {id = "arcane_missile", name = "Arcane Missile", description = "Rapid-fire magical projectiles (F key)", rarity = "rare", effect = "arcane_missile", value = 1},
    {id = "shadow_bolt", name = "Shadow Bolt", description = "Dark energy that pierces through enemies (G key)", rarity = "epic", effect = "shadow_bolt", value = 1}
}

function Bonus.new(definition, level)
    local self = setmetatable({}, Bonus)
    self.id = definition.id
    self.name = definition.name
    self.description = definition.description
    self.rarity = definition.rarity
    self.effect = definition.effect
    self.value = definition.value
    self.level = level or 1
    self.color = RARITIES[definition.rarity].color
    return self
end

function Bonus:getRarityColor()
    return RARITIES[self.rarity].color
end

function Bonus:getScaledValue()
    -- Scale value based on level (linear scaling)
    return self.value * self.level
end

function Bonus:getDisplayName()
    if self.level > 1 then
        return self.name .. " (Lv." .. self.level .. ")"
    end
    return self.name
end

-- Bonus selection system
local BonusSelection = {}
BonusSelection.__index = BonusSelection

function BonusSelection.new()
    local self = setmetatable({}, BonusSelection)
    self.bonuses = {}
    self.selectedBonus = nil
    self.font = nil
    self.titleFont = nil
    return self
end

function BonusSelection:generateBonuses(count, playerBonuses)
    self.bonuses = {}

    -- Create weighted list of all bonuses
    local weightedBonuses = {}
    for _, bonusDef in ipairs(BONUS_DEFINITIONS) do
        local weight = RARITIES[bonusDef.rarity].weight
        for _ = 1, weight do
            table.insert(weightedBonuses, bonusDef)
        end
    end

    -- Select random bonuses
    for i = 1, count do
        local attempts = 0
        local bonusDef = nil
        local randomIndex = nil

        -- Keep trying until we find a unique bonus
        repeat
            randomIndex = math.random(1, #weightedBonuses)
            bonusDef = weightedBonuses[randomIndex]
            attempts = attempts + 1

            -- Check if this bonus is already selected
            local isDuplicate = false
            for _, existingBonus in ipairs(self.bonuses) do
                if existingBonus.id == bonusDef.id then
                    isDuplicate = true
                    break
                end
            end

            if not isDuplicate or attempts > 50 then  -- Give up after 50 attempts
                break
            end
        until false

        -- Check if player already has this bonus
        local existingLevel = 1
        if playerBonuses then
            for _, existingBonus in ipairs(playerBonuses) do
                if existingBonus.id == bonusDef.id then
                    existingLevel = existingBonus.level + 1
                    break
                end
            end
        end

        table.insert(self.bonuses, Bonus.new(bonusDef, existingLevel))

        -- Remove this bonus from the pool to avoid duplicates
        table.remove(weightedBonuses, randomIndex)
    end
end

function BonusSelection:onEnter()
    self.font = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(24)
end

function BonusSelection:update(dt)
    -- Bonus selection doesn't need update logic
end

function BonusSelection:keypressed(key)
    -- Keep keyboard support as backup
    if key == '1' then
        self.selectedBonus = self.bonuses[1]
    elseif key == '2' then
        self.selectedBonus = self.bonuses[2]
    elseif key == '3' then
        self.selectedBonus = self.bonuses[3]
    end
end

function BonusSelection:mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Check which bonus was clicked
        for i, bonus in ipairs(self.bonuses) do
            local bonusX = 50 + (i - 1) * 250
            local bonusY = 150

            if x >= bonusX and x <= bonusX + 200 and y >= bonusY and y <= bonusY + 300 then
                self.selectedBonus = bonus
                break
            end
        end
    end
end

function BonusSelection:render()
    love.graphics.clear(0.1, 0.1, 0.15)

    -- Title
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Choose a Bonus", 0, 50, 800, 'center')

    -- Instructions
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Click a bonus to select, or press 1, 2, or 3", 0, 100, 800, 'center')

    -- Display bonuses
    for i, bonus in ipairs(self.bonuses) do
        local x = 50 + (i - 1) * 250
        local y = 150

        -- Bonus box
        love.graphics.setColor(0.2, 0.2, 0.3)
        love.graphics.rectangle('fill', x, y, 200, 300)

        -- Rarity border
        love.graphics.setColor(bonus.color[1], bonus.color[2], bonus.color[3])
        love.graphics.rectangle('line', x, y, 200, 300)

        -- Bonus name with level
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(bonus:getDisplayName(), x, y + 20, 200, 'center')

        -- Rarity
        love.graphics.setColor(bonus.color[1], bonus.color[2], bonus.color[3])
        love.graphics.printf(RARITIES[bonus.rarity].name, x, y + 50, 200, 'center')

        -- Description
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.printf(bonus.description, x + 10, y + 80, 180, 'center')

        -- Key indicator
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("Press " .. i, x, y + 250, 200, 'center')
    end
end

return {
    Bonus = Bonus,
    BonusSelection = BonusSelection,
    BONUS_DEFINITIONS = BONUS_DEFINITIONS,
    RARITIES = RARITIES
}
