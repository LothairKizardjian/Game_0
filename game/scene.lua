-- Refactored Roguelike Game Scene for Game_0
-- Clean, modular architecture with separated concerns

local RogueScene = {}
RogueScene.__index = RogueScene

-- Import systems
local Player = require('systems.player')
local Enemy = require('systems.enemy')
local InfiniteMap = require('systems.infinite_map')
local Camera = require('systems.camera')
local AnimationSystem = require('systems.animation')
local CombatSystem = require('systems.combat')
local EnemySpawner = require('systems.enemy_spawner')
local PowerSystem = require('game.bonus')
local XPShardSystem = require('game.xp_shard')
local GameOverScene = require('game.gameover')
local PauseMenu = require('game.pause')
local SpriteSystem = require('systems.sprite')

-- Constants
local TILE = 32
-- Screen dimensions will be set dynamically
local SCREEN_W, SCREEN_H = 800, 576  -- Default fallback

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
    self.spriteSystem = SpriteSystem.new()

    -- Load player sprite
    self:loadPlayerSprite()

    -- Load enemy sprite
    self:loadEnemySprite()

    -- Game state
    self.player = Player.new(0, 0, TILE - 12, TILE - 12, COLOR_PLAYER, 150, 10)
    self.player:setSpriteSystem(self.spriteSystem)
    self.enemies = {}
    self.projectiles = {}
    self.damageNumbers = {}
    self.moveDir = {x = 0, y = 0}
    self.keys = {}

    -- Ensure player spawns in a safe area
    self:findSafeSpawnPosition()

    -- XP and power systems
    self.xpShardManager = XPShardSystem.XPShardManager.new()
    self.powerSelection = nil
    self.showingPowerSelection = false
    self.gameOver = false
    self.gameOverScene = nil

    -- Pause state
    self.paused = false
    self.pauseMenu = nil

    -- Initialize power selection at start
    self:showPowerSelection()

    return self
end

function RogueScene:loadPlayerSprite()
    -- Load directional knight sprites using PNG files
    print("Loading knight sprites...")
    local success = self.spriteSystem:createDirectionalSprite("player", "assets/Knight_walk")

    if success and self.spriteSystem.sprites["player"] then
        print("Knight sprites loaded successfully")
    else
        print("Failed to load knight sprites - using fallback")
        -- Create a simple colored rectangle as fallback
        self.spriteSystem:createFallbackSprite("player")
    end
end

function RogueScene:loadEnemySprite()
    -- Load directional skeleton sprites using PNG files
    print("Loading skeleton sprites...")
    local success = self.spriteSystem:createEnemySprite("enemy", "assets/skeleton_walk")

    if success and self.spriteSystem.sprites["enemy"] then
        print("Skeleton sprites loaded successfully")
    else
        print("Failed to load skeleton sprites - using fallback")
        -- Create a simple colored rectangle as fallback
        self.spriteSystem:createFallbackSprite("enemy")
    end
end

function RogueScene:onEnter()
    -- Initialize any scene-specific resources
end

function RogueScene:onExit()
    -- Cleanup any scene-specific resources
end

function RogueScene:showPowerSelection()
    self.powerSelection = PowerSystem.PowerSelection.new(self.player.powers)
    self.powerSelection:generatePowers(3)
    self.powerSelection:onEnter()
    self.showingPowerSelection = true
end

function RogueScene:selectPower(power)
    self.player:applyPower(power)
    self.showingPowerSelection = false
    self.powerSelection = nil
end

function RogueScene:pauseGame()
    self.paused = true
    if not self.pauseMenu then
        self.pauseMenu = PauseMenu.new()
        self.pauseMenu:load()
    end
end

function RogueScene:resumeGame()
    self.paused = false
    self.pauseMenu = nil
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

    -- Show power selection
    self:showPowerSelection()
end

function RogueScene:keypressed(key)
    -- Handle pause menu
    if self.paused then
        if key == 'escape' then
            self:resumeGame()
        end
        return
    end

    -- Handle pause toggle
    if key == 'escape' then
        self:pauseGame()
        return
    end

    -- Handle power selection
    if self.showingPowerSelection then
        if key == '1' then
            self:selectPower(self.powerSelection.powers[1])
        elseif key == '2' then
            self:selectPower(self.powerSelection.powers[2])
        elseif key == '3' then
            self:selectPower(self.powerSelection.powers[3])
        end
        return
    end

    -- Auto-attack system removed

    -- Zoom controls
    if key == '=' or key == '+' then
        self.camera:zoomIn()
    elseif key == '-' then
        self.camera:zoomOut()
    elseif key == '0' then
        self.camera:resetZoom()
    end
    
    -- Debug: Level up with L key
    if key == 'l' then
        self.player:levelUp()
        print("Debug: Player leveled up to level " .. self.player.level)
    end

    self.keys[key] = true
end

function RogueScene:keyreleased(key)
    self.keys[key] = false
end

function RogueScene:mousepressed(x, y, button)
    -- Handle pause menu mouse clicks
    if self.paused and self.pauseMenu then
        local action = self.pauseMenu:mousepressed(x, y, button)
        if action == "resume" then
            self:resumeGame()
        elseif action == "exit" then
            love.event.quit()
        end
        return
    end

    -- Handle game over screen mouse clicks
    if self.gameOver and self.gameOverScene then
        self.gameOverScene:mousepressed(x, y, button)
        if self.gameOverScene.restartRequested then
            -- Restart the game
            self:restartGame()
        end
        return
    end

    -- Handle power selection mouse clicks
    if self.showingPowerSelection then
        self.powerSelection:mousepressed(x, y, button)
        if self.powerSelection.selectedPower then
            self:selectPower(self.powerSelection.selectedPower)
        end
        return
    end
end

function RogueScene:mousereleased(x, y, button)
    -- Not needed for current functionality
end

function RogueScene:update(dt)
    -- Handle pause menu
    if self.paused then
        if self.pauseMenu then
            self.pauseMenu:update(dt)
        end
        return
    end

    -- Handle power selection screen
    if self.showingPowerSelection then
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
        self.player:updateFacingDirection(self.moveDir.x, self.moveDir.y)

        -- Start animation
        if self.spriteSystem.sprites["player"] then
            self.spriteSystem.sprites["player"].playing = true
        end
    else
        self.moveDir.x = 0
        self.moveDir.y = 0

        -- Stop animation when not moving
        if self.spriteSystem.sprites["player"] then
            self.spriteSystem.sprites["player"].playing = false
            self.spriteSystem.sprites["player"].currentFrame = 1  -- Reset to first frame
        end
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

            -- Update enemy facing direction
            enemy:updateFacingDirection(dirX, dirY)

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

    -- Auto-attack system removed

    -- Magical power system removed

    -- Update infinite map
    self.infiniteMap:update(self.player.x, self.player.y)

    -- Update enemy spawning
    self.enemySpawner:update(dt, self.enemies, self.player, self.infiniteMap, self.spriteSystem)

    -- Handle passive bonuses
    self:updatePassiveBonuses(dt)

    -- Magical power system removed

    -- Update animations
    self.animationSystem:update(dt)

    -- Update player powers
    self.player:updatePowers(dt, self.enemies)

    -- Update sprite system
    self.spriteSystem:update(dt)

    -- Update XP shards
    local collectedXP = self.xpShardManager:update(dt, self.player.x + self.player.w/2, self.player.y + self.player.h/2,
        self.player.collectRadius * self.player.collectRadiusMultiplier, 200 * self.player.xpMagnet)

    -- Add collected XP to player
    if collectedXP > 0 then
        self.player.xp = self.player.xp + collectedXP * self.player.xpMultiplier

        -- Check for level up
        while self.player.xp >= self.player.xpToNext do
            self.player:levelUp()
            self:showPowerSelection()
        end
    end

    -- Update projectiles
    self:updateProjectiles(dt)

    -- Update damage numbers
    self:updateDamageNumbers(dt)

    -- Update camera to follow player
    self.camera:update(dt, self.player.x, self.player.y, self.player.w, self.player.h)
end

function RogueScene:updateProjectiles(dt)
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        -- Update position
        projectile.x = projectile.x + projectile.vx * dt
        projectile.y = projectile.y + projectile.vy * dt
        projectile.life = projectile.life - dt

        -- Check collision with enemies
        for _, enemy in ipairs(self.enemies) do
            local dx = projectile.x - (enemy.x + enemy.w/2)
            local dy = projectile.y - (enemy.y + enemy.h/2)
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance < projectile.size + enemy.w/2 then
                -- Hit enemy
                enemy:takeDamage(projectile.damage, love.timer.getTime())

                -- Add damage number
                self:addDamageNumber(enemy.x + enemy.w/2, enemy.y, projectile.damage)

                -- Special effects
                if projectile.type == "ice_shard" then
                    enemy.speed = enemy.speed * 0.5  -- Slow enemy
                end

                -- Remove projectile unless piercing
                if not projectile.piercing then
                    table.remove(self.projectiles, i)
                    break
                end
            end
        end

        -- Remove expired projectiles
        if projectile.life <= 0 then
            table.remove(self.projectiles, i)
        end
    end
end

function RogueScene:updateDamageNumbers(dt)
    for i = #self.damageNumbers, 1, -1 do
        local damageNum = self.damageNumbers[i]
        damageNum.y = damageNum.y - 50 * dt  -- Float upward
        damageNum.life = damageNum.life - dt

        if damageNum.life <= 0 then
            table.remove(self.damageNumbers, i)
        end
    end
end

function RogueScene:addDamageNumber(x, y, damage)
    table.insert(self.damageNumbers, {
        x = x,
        y = y,
        damage = damage,
        life = 1.0
    })
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

    -- Handle pause menu
    if self.paused then
        if self.pauseMenu then
            self.pauseMenu:render()
        end
        return
    end

    -- Handle power selection screen
    if self.showingPowerSelection then
        self.powerSelection:render()
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
    local screenW, screenH = love.graphics.getDimensions()
    self.infiniteMap:render(self.camera.x, self.camera.y, self.camera.zoom, screenW, screenH)

    -- Draw XP shards
    self.xpShardManager:render()

    -- Draw entities
    -- Draw player using entity render method
    self.player:render()

    for _, enemy in ipairs(self.enemies) do
        -- Draw enemy using entity render method
        enemy:render()
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

    -- Draw projectiles
    for _, projectile in ipairs(self.projectiles) do
        love.graphics.setColor(1, 0.5, 0, 0.8)
        love.graphics.circle('fill', projectile.x, projectile.y, projectile.size)
    end

    -- Draw damage numbers
    for _, damageNum in ipairs(self.damageNumbers) do
        love.graphics.setColor(1, 0.2, 0.2, damageNum.life)
        love.graphics.print(tostring(damageNum.damage), damageNum.x - 10, damageNum.y, 0, 0.8, 0.8)
    end

    -- Auto-attack system removed

    -- Draw animations
    self.animationSystem:render()

    -- Draw player powers
    self.player:renderPowers()

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


function RogueScene:renderHUD()
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, 8, 6)
    love.graphics.print("Level: " .. self.player.level, 8, 28)
    love.graphics.print("XP: " .. self.player.xp .. "/" .. self.player.xpToNext, 8, 50)
    love.graphics.print("Enemies: " .. #self.enemies .. " | Killed: " .. self.player.enemiesKilled, 8, 72)
    love.graphics.print("Zoom: " .. string.format("%.1f", self.camera.zoom), 8, 94)

    -- Auto-attack system removed

    -- Magical power system removed

    -- Player health bar in HUD
    local hudBarWidth = 120
    local hudBarHeight = 8
    self:drawHealthBar(self.player, 8, 120, hudBarWidth, hudBarHeight)

    -- XP bar
    local xpPercent = self.player.xp / self.player.xpToNext
    local xpBarWidth = 120
    local xpBarHeight = 6
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle('fill', 8, 145, xpBarWidth, xpBarHeight)
    love.graphics.setColor(0.2, 0.8, 1.0)
    love.graphics.rectangle('fill', 8, 145, xpBarWidth * xpPercent, xpBarHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle('line', 8, 145, xpBarWidth, xpBarHeight)

    -- Active powers display
    if #self.player.powers > 0 then
        love.graphics.print("Powers:", 8, 165)
        for i, power in ipairs(self.player.powers) do
            if i <= 5 then  -- Show only first 5 powers
                love.graphics.setColor(0.8, 0.8, 0.8)
                love.graphics.print("• " .. power:getDisplayName(), 8, 185 + (i-1) * 15)
            end
        end
    end
end

return RogueScene
