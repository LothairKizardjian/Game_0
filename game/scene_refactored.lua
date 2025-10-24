-- Refactored Roguelike Game Scene for Game_0
-- Clean, modular architecture with separated concerns

local RogueScene = {}
RogueScene.__index = RogueScene

-- Import systems
local Entity = require('systems.entity')
local InfiniteMap = require('systems.infinite_map')
local Camera = require('systems.camera')
local AnimationSystem = require('systems.animation')
local CombatSystem = require('systems.combat')
local EnemySpawner = require('systems.enemy_spawner')
local BonusSystem = require('game.bonus')
local XPShardSystem = require('game.xp_shard')
local GameOverScene = require('game.gameover')

-- Constants
local TILE = 32
local SCREEN_W, SCREEN_H = 800, 576

-- Colors
local COLOR_BG = {12/255, 12/255, 16/255}
local COLOR_WALL = {50/255, 50/255, 70/255}
local COLOR_FLOOR = {22/255, 22/255, 28/255}
local COLOR_PLAYER = {80/255, 200/255, 120/255}
local COLOR_ENEMY = {220/255, 80/255, 80/255}
local COLOR_UI = {230/255, 230/255, 230/255}

function RogueScene.new()
    local self = setmetatable({}, RogueScene)

    -- Initialize systems
    self.infiniteMap = InfiniteMap.new()
    self.camera = Camera.new()
    self.animationSystem = AnimationSystem.new()
    self.combatSystem = CombatSystem.new()
    self.enemySpawner = EnemySpawner.new()

    -- Game state
    self.player = Entity.new(0, 0, TILE - 12, TILE - 12, COLOR_PLAYER, 150, 10, true)
    self.enemies = {}
    self.moveDir = {x = 0, y = 0}
    self.keys = {}

    -- Ensure player spawns in a safe area
    self:findSafeSpawnPosition()

    -- XP and bonus systems
    self.xpShardManager = XPShardSystem.XPShardManager.new()
    self.bonusSelection = nil
    self.showingBonusSelection = false
    self.gameOver = false
    self.gameOverScene = nil

    -- Initialize bonus selection at start
    self:showBonusSelection()

    return self
end

function RogueScene:onEnter()
    -- Initialize any scene-specific resources
end

function RogueScene:onExit()
    -- Cleanup any scene-specific resources
end

function RogueScene:showBonusSelection()
    self.bonusSelection = BonusSystem.BonusSelection.new()
    self.bonusSelection:generateBonuses(3, self.player.bonuses)
    self.bonusSelection:onEnter()
    self.showingBonusSelection = true
end

function RogueScene:selectBonus(bonus)
    self.player:applyBonus(bonus)
    self.showingBonusSelection = false
    self.bonusSelection = nil
end

function RogueScene:findSafeSpawnPosition()
    -- Try to find a safe spawn position
    local attempts = 0
    while attempts < 100 do
        local x = math.random(-200, 200)
        local y = math.random(-200, 200)

        -- Check if this position is safe (floor tile)
        if self.infiniteMap:getTileAtWorldPos(x, y) == 0 then
            self.player.x = x
            self.player.y = y
            return
        end
        attempts = attempts + 1
    end

    -- Fallback: spawn at origin and force floor
    self.player.x = 0
    self.player.y = 0
end

function RogueScene:restartGame()
    -- Reset all game state
    self.player = Entity.new(0, 0, TILE - 12, TILE - 12, COLOR_PLAYER, 150, 10, true)
    self.enemies = {}
    self.moveDir = {x = 0, y = 0}
    self.keys = {}

    -- Reset systems
    self.infiniteMap = InfiniteMap.new()
    self.animationSystem = AnimationSystem.new()
    self.combatSystem = CombatSystem.new()
    self.enemySpawner = EnemySpawner.new()
    self.xpShardManager = XPShardSystem.XPShardManager.new()

    -- Reset game state
    self.bonusSelection = nil
    self.showingBonusSelection = false
    self.gameOver = false
    self.gameOverScene = nil

    -- Find safe spawn position
    self:findSafeSpawnPosition()

    -- Show bonus selection
    self:showBonusSelection()
end

function RogueScene:keypressed(key)
    -- Handle bonus selection
    if self.showingBonusSelection then
        if key == '1' then
            self:selectBonus(self.bonusSelection.bonuses[1])
        elseif key == '2' then
            self:selectBonus(self.bonusSelection.bonuses[2])
        elseif key == '3' then
            self:selectBonus(self.bonusSelection.bonuses[3])
        end
        return
    end

    -- Auto-attack
    if key == 'space' then
        self.combatSystem:performAutoAttack(self.player, self.enemies, self.animationSystem)
    end

    -- Zoom controls
    if key == '=' or key == '+' then
        self.camera:zoomIn()
    elseif key == '-' then
        self.camera:zoomOut()
    elseif key == '0' then
        self.camera:resetZoom()
    end

    self.keys[key] = true
end

function RogueScene:keyreleased(key)
    self.keys[key] = false
end

function RogueScene:mousepressed(x, y, button)
    -- Handle game over screen mouse clicks
    if self.gameOver and self.gameOverScene then
        self.gameOverScene:mousepressed(x, y, button)
        if self.gameOverScene.restartRequested then
            -- Restart the game
            self:restartGame()
        end
        return
    end

    -- Handle bonus selection mouse clicks
    if self.showingBonusSelection then
        self.bonusSelection:mousepressed(x, y, button)
        if self.bonusSelection.selectedBonus then
            self:selectBonus(self.bonusSelection.selectedBonus)
        end
        return
    end
end

function RogueScene:mousereleased(x, y, button)
    -- Not needed for current functionality
end

function RogueScene:update(dt)
    -- Handle bonus selection screen
    if self.showingBonusSelection then
        return
    end

    -- Check for game over
    if self.player.hp <= 0 then
        self.gameOver = true
        if not self.gameOverScene then
            self.gameOverScene = GameOverScene.new(self.player.level, self.player.xp, self.player.enemiesKilled)
            self.gameOverScene:onEnter()
        end
        -- Update game over scene to handle mouse hover
        self.gameOverScene:update(dt)
        return
    end

    -- Player movement
    local x, y = 0, 0
    if self.keys['w'] or self.keys['up'] then y = y - 1 end
    if self.keys['s'] or self.keys['down'] then y = y + 1 end
    if self.keys['d'] or self.keys['right'] then x = x + 1 end
    if self.keys['a'] or self.keys['left'] then x = x - 1 end

    if x ~= 0 or y ~= 0 then
        local length = math.sqrt(x*x + y*y)
        self.moveDir.x = x / length
        self.moveDir.y = y / length

        -- Update facing direction when moving
        self.player.facingDirection.x = self.moveDir.x
        self.player.facingDirection.y = self.moveDir.y
    else
        self.moveDir.x = 0
        self.moveDir.y = 0
    end

    -- Calculate player speed with bonuses
    local playerSpeed = self.player.baseSpeed * self.player.speedMultiplier
    if self.player.speedBurstTime > 0 then
        playerSpeed = playerSpeed * (1 + self.player.speedBurst)
    end

    -- Player movement with collision
    if self.moveDir.x ~= 0 or self.moveDir.y ~= 0 then
        self:moveEntity(self.player, self.moveDir.x * playerSpeed * dt, self.moveDir.y * playerSpeed * dt)
    end

    -- Enemy AI - chase player (with slow effect)
    local enemySpeedMultiplier = 1.0
    if self.player.enemySlow then
        enemySpeedMultiplier = 1.0 - self.player.enemySlow
    end

    for _, enemy in ipairs(self.enemies) do
        local dx = self.player.x - enemy.x
        local dy = self.player.y - enemy.y
        local length = math.sqrt(dx*dx + dy*dy)

        if length > 0 then
            local dirX = dx / length
            local dirY = dy / length
            self:moveEntity(enemy, dirX * enemy.speed * enemySpeedMultiplier * dt, dirY * enemy.speed * enemySpeedMultiplier * dt)
        end
    end

    -- Combat - enemies damage player on collision
    for _, enemy in ipairs(self.enemies) do
        if self.player:collidesWith(enemy) then
            -- Check for damage immunity and enemy attack cooldown
            local currentTime = love.timer.getTime()
            if self.player.damageImmunityTime <= 0 and (currentTime - enemy.lastAttackTime) >= enemy.attackCooldown then
                local enemyDamage = enemy.attackPower or 1  -- Use enemy's attack power
                local damage = math.max(1, enemyDamage - self.player.damageReduction)
                if self.player:takeDamage(damage, currentTime) then
                    self.player.damageImmunityTime = self.player.damageImmunity
                    enemy.lastAttackTime = currentTime  -- Update enemy's last attack time
                end
            end
        end
    end

    -- Remove dead enemies and handle effects
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if enemy.hp <= 0 then
            -- Calculate XP based on time elapsed (tier scaling)
            local timeElapsed = love.timer.getTime() - self.enemySpawner.startTime
            local xpValue = math.floor(1 + timeElapsed / 30)  -- +1 XP every 30 seconds

            -- Drop XP shards with scaled value
            self.xpShardManager:addShard(enemy.x + enemy.w/2, enemy.y + enemy.h/2, xpValue)
            self.player.enemiesKilled = self.player.enemiesKilled + 1

            -- Apply bonuses
            if self.player.lifeSteal > 0 then
                self.player.hp = math.min(self.player.maxHp, self.player.hp + self.player.lifeSteal)
            end

            if self.player.speedBurst > 0 then
                self.player.speedBurstTime = 1.0
            end

            if self.player.explosiveDeath > 0 then
                self.combatSystem:createExplosion(enemy.x + enemy.w/2, enemy.y + enemy.h/2, self.player.explosiveDeath, self.enemies, self.animationSystem)
            end

            table.remove(self.enemies, i)
        end
    end

    -- Update cooldowns
    if self.player.damageImmunityTime > 0 then
        self.player.damageImmunityTime = self.player.damageImmunityTime - dt
    end

    if self.player.speedBurstTime > 0 then
        self.player.speedBurstTime = self.player.speedBurstTime - dt
    end

    -- Update auto-attack cooldown
    if self.player.autoAttackCooldown > 0 then
        self.player.autoAttackCooldown = self.player.autoAttackCooldown - dt
    end

    -- Update magical power cooldowns
    if self.player.fireballCooldown > 0 then
        self.player.fireballCooldown = self.player.fireballCooldown - dt
    end
    if self.player.iceShardCooldown > 0 then
        self.player.iceShardCooldown = self.player.iceShardCooldown - dt
    end
    if self.player.lightningBoltCooldown > 0 then
        self.player.lightningBoltCooldown = self.player.lightningBoltCooldown - dt
    end
    if self.player.meteorCooldown > 0 then
        self.player.meteorCooldown = self.player.meteorCooldown - dt
    end
    if self.player.arcaneMissileCooldown > 0 then
        self.player.arcaneMissileCooldown = self.player.arcaneMissileCooldown - dt
    end
    if self.player.shadowBoltCooldown > 0 then
        self.player.shadowBoltCooldown = self.player.shadowBoltCooldown - dt
    end

    -- Update infinite map
    self.infiniteMap:update(self.player.x, self.player.y)

    -- Update enemy spawning
    self.enemySpawner:update(dt, self.enemies, self.player, self.infiniteMap)

    -- Handle passive bonuses
    self:updatePassiveBonuses(dt)

    -- Automatic magical powers
    self.combatSystem:updateAutomaticPowers(self.player, self.enemies, self.animationSystem)

    -- Update animations
    self.animationSystem:update(dt)

    -- Update XP shards
    local collectedXP = self.xpShardManager:update(dt, self.player.x + self.player.w/2, self.player.y + self.player.h/2,
        self.player.collectRadius * self.player.collectRadiusMultiplier, 200 * self.player.xpMagnet)

    -- Add collected XP to player
    if collectedXP > 0 then
        self.player.xp = self.player.xp + collectedXP

        -- Check for level up
        while self.player.xp >= self.player.xpToNext do
            self.player:levelUp()
            self:showBonusSelection()
        end
    end

    -- Update camera to follow player
    self.camera:update(dt, self.player.x, self.player.y, self.player.w, self.player.h)
end

function RogueScene:moveEntity(entity, dx, dy)
    -- Move X
    entity.x = entity.x + dx
    if self.infiniteMap:rectCollidesWalls(entity:getRect()) then
        entity.x = entity.x - dx
    end

    -- Move Y
    entity.y = entity.y + dy
    if self.infiniteMap:rectCollidesWalls(entity:getRect()) then
        entity.y = entity.y - dy
    end
end

function RogueScene:updatePassiveBonuses(dt)
    local currentTime = love.timer.getTime()

    -- Health regeneration
    if self.player.healthRegen and currentTime - self.player.lastHealthRegen >= 3.0 then
        self.player.hp = math.min(self.player.maxHp, self.player.hp + self.player.healthRegen)
        self.player.lastHealthRegen = currentTime
    end

    -- XP Rain
    if self.player.xpRain and currentTime - self.player.lastXPRain >= 1.0 then
        self.player:addXP(self.player.xpRain)
        self.player.lastXPRain = currentTime
    end

    -- God Mode
    if self.player.godMode and currentTime - self.player.lastGodMode >= 2.0 then
        for _, enemy in ipairs(self.enemies) do
            enemy:takeDamage(5, currentTime)  -- God mode deals 5 damage
        end
        self.player.lastGodMode = currentTime
    end

    -- Teleport
    if self.player.teleport and currentTime - self.player.lastTeleport >= 5.0 then
        local x, y = self.infiniteMap:randomFloorTile(self.player.x, self.player.y)
        self.player.x = x * TILE + 4
        self.player.y = y * TILE + 4
        self.player.lastTeleport = currentTime
    end
end

function RogueScene:render()
    love.graphics.clear(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3])

    -- Handle bonus selection screen
    if self.showingBonusSelection then
        self.bonusSelection:render()
        return
    end

    -- Handle game over screen
    if self.gameOver then
        self.gameOverScene:render()
        return
    end

    -- Apply camera transformation
    self.camera:apply()

    -- Draw infinite map tiles
    self.infiniteMap:render(self.camera.x, self.camera.y, self.camera.zoom, SCREEN_W, SCREEN_H)

    -- Draw XP shards
    self.xpShardManager:render()

    -- Draw entities
    love.graphics.setColor(COLOR_PLAYER[1], COLOR_PLAYER[2], COLOR_PLAYER[3])
    love.graphics.rectangle('fill', self.player.x, self.player.y, self.player.w, self.player.h)

    for _, enemy in ipairs(self.enemies) do
        love.graphics.setColor(COLOR_ENEMY[1], COLOR_ENEMY[2], COLOR_ENEMY[3])
        love.graphics.rectangle('fill', enemy.x, enemy.y, enemy.w, enemy.h)
    end

    -- Draw health bars
    if self.player.hp < self.player.maxHp then
        self:drawHealthBar(self.player, self.player.x, self.player.y - 6, self.player.w, 3)
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy.hp < enemy.maxHp then
            self:drawHealthBar(enemy, enemy.x, enemy.y - 6, enemy.w, 3)
        end
    end

    -- Collect radius animation removed

    -- Draw auto-attack cone when attacking
    if self.player.autoAttackCooldown > 0.4 then  -- Show for first 0.1 seconds
        self:drawAttackCone()
    end

    -- Draw animations
    self.animationSystem:render()

    -- Reset transformation for HUD
    self.camera:reset()

    -- HUD (not affected by camera)
    self:renderHUD()
end

function RogueScene:drawHealthBar(entity, x, y, width, height)
    local healthPercent = entity:getHealthPercent()
    local barWidth = width * healthPercent

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle('fill', x, y, width, height)

    -- Health bar
    if healthPercent > 0.6 then
        love.graphics.setColor(0.2, 0.8, 0.2)  -- Green
    elseif healthPercent > 0.3 then
        love.graphics.setColor(0.8, 0.8, 0.2)  -- Yellow
    else
        love.graphics.setColor(0.8, 0.2, 0.2)  -- Red
    end
    love.graphics.rectangle('fill', x, y, barWidth, height)

    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('line', x, y, width, height)
end

function RogueScene:drawAttackCone()
    local playerCenterX = self.player.x + self.player.w / 2
    local playerCenterY = self.player.y + self.player.h / 2

    -- Use player's facing direction for attack cone
    local attackDirX = self.player.facingDirection.x
    local attackDirY = self.player.facingDirection.y

    -- Normalize direction
    local length = math.sqrt(attackDirX * attackDirX + attackDirY * attackDirY)
    if length > 0 then
        attackDirX = attackDirX / length
        attackDirY = attackDirY / length
    end

    -- Calculate cone points
    local range = self.player.autoAttackRange
    local halfAngle = self.player.autoAttackAngle / 2

    local leftX = attackDirX * math.cos(halfAngle) - attackDirY * math.sin(halfAngle)
    local leftY = attackDirX * math.sin(halfAngle) + attackDirY * math.cos(halfAngle)
    local rightX = attackDirX * math.cos(-halfAngle) - attackDirY * math.sin(-halfAngle)
    local rightY = attackDirX * math.sin(-halfAngle) + attackDirY * math.cos(-halfAngle)

    -- Draw cone
    love.graphics.setColor(1, 0.8, 0.2, 0.6)  -- Orange with transparency
    love.graphics.polygon('fill',
        playerCenterX, playerCenterY,
        playerCenterX + leftX * range, playerCenterY + leftY * range,
        playerCenterX + rightX * range, playerCenterY + rightY * range
    )

    -- Draw cone outline
    love.graphics.setColor(1, 0.6, 0, 0.8)
    love.graphics.polygon('line',
        playerCenterX, playerCenterY,
        playerCenterX + leftX * range, playerCenterY + leftY * range,
        playerCenterX + rightX * range, playerCenterY + rightY * range
    )
end

function RogueScene:renderHUD()
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, 8, 6)
    love.graphics.print("Level: " .. self.player.level, 8, 28)
    love.graphics.print("XP: " .. self.player.xp .. "/" .. self.player.xpToNext, 8, 50)
    love.graphics.print("Enemies: " .. #self.enemies .. " | Killed: " .. self.player.enemiesKilled, 8, 72)
    love.graphics.print("Zoom: " .. string.format("%.1f", self.camera.zoom), 8, 94)

    -- Auto-attack cooldown
    if self.player.autoAttackCooldown > 0 then
        love.graphics.print("Attack: " .. string.format("%.1f", self.player.autoAttackCooldown) .. "s", 8, 116)
    else
        love.graphics.print("Attack: Ready (SPACE)", 8, 116)
    end

    -- Magical Powers
    local powerY = 138
    if self.player.fireball then
        if self.player.fireballCooldown > 0 then
            love.graphics.print("Fireball: " .. string.format("%.1f", self.player.fireballCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Fireball: Ready (Q)", 8, powerY)
        end
        powerY = powerY + 15
    end

    if self.player.iceShard then
        if self.player.iceShardCooldown > 0 then
            love.graphics.print("Ice Shard: " .. string.format("%.1f", self.player.iceShardCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Ice Shard: Ready (E)", 8, powerY)
        end
        powerY = powerY + 15
    end

    if self.player.lightningBolt then
        if self.player.lightningBoltCooldown > 0 then
            love.graphics.print("Lightning: " .. string.format("%.1f", self.player.lightningBoltCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Lightning: Ready (R)", 8, powerY)
        end
        powerY = powerY + 15
    end

    if self.player.meteor then
        if self.player.meteorCooldown > 0 then
            love.graphics.print("Meteor: " .. string.format("%.1f", self.player.meteorCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Meteor: Ready (T)", 8, powerY)
        end
        powerY = powerY + 15
    end

    if self.player.arcaneMissile then
        if self.player.arcaneMissileCooldown > 0 then
            love.graphics.print("Arcane: " .. string.format("%.1f", self.player.arcaneMissileCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Arcane: Ready (F)", 8, powerY)
        end
        powerY = powerY + 15
    end

    if self.player.shadowBolt then
        if self.player.shadowBoltCooldown > 0 then
            love.graphics.print("Shadow: " .. string.format("%.1f", self.player.shadowBoltCooldown) .. "s", 8, powerY)
        else
            love.graphics.print("Shadow: Ready (G)", 8, powerY)
        end
        powerY = powerY + 15
    end

    -- Player health bar in HUD
    local hudBarWidth = 120
    local hudBarHeight = 8
    self:drawHealthBar(self.player, 8, powerY + 10, hudBarWidth, hudBarHeight)

    -- XP bar
    local xpPercent = self.player.xp / self.player.xpToNext
    local xpBarWidth = 120
    local xpBarHeight = 6
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle('fill', 8, powerY + 25, xpBarWidth, xpBarHeight)
    love.graphics.setColor(0.2, 0.8, 1.0)
    love.graphics.rectangle('fill', 8, powerY + 25, xpBarWidth * xpPercent, xpBarHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 8, powerY + 25, xpBarWidth, xpBarHeight)

    -- Active bonuses display
    if #self.player.bonuses > 0 then
        love.graphics.print("Bonuses:", 8, powerY + 45)
        for i, bonus in ipairs(self.player.bonuses) do
            if i <= 5 then  -- Show only first 5 bonuses
                love.graphics.setColor(bonus.color[1], bonus.color[2], bonus.color[3])
                love.graphics.print("• " .. bonus.name, 8, powerY + 65 + (i-1) * 15)
            end
        end
    end
end

return RogueScene
