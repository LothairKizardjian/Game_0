-- Optimized Roguelike Game Scene for Game_0
-- Uses object pooling, spatial partitioning, and performance monitoring

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

-- Import optimization systems
local ObjectPool = require('systems.object_pool')
local Performance = require('systems.performance')
local SpatialGrid = require('systems.spatial_grid')
local Renderer = require('systems.renderer')
local GameState = require('systems.game_state')
local InputManager = require('systems.input_manager')
local Config = require('systems.config')

-- Constants
local TILE = Config.GAMEPLAY.TILE_SIZE
local SCREEN_W, SCREEN_H = Config.WINDOW.WIDTH, Config.WINDOW.HEIGHT

function RogueScene.new()
    local self = setmetatable({}, RogueScene)

    -- Initialize optimization systems
    self.performance = Performance.new()
    self.gameState = GameState.new()
    self.inputManager = InputManager.new()
    self.renderer = Renderer.new()
    self.spatialGrid = SpatialGrid.new(64)  -- 64px grid cells
    
    -- Initialize object pools
    self.projectilePool = ObjectPool.new("projectile", 50)
    self.damageNumberPool = ObjectPool.new("damage_number", 30)
    self.animationPool = ObjectPool.new("animation", 40)

    -- Initialize core systems
    self.infiniteMap = InfiniteMap.new()
    self.camera = Camera.new()
    self.animationSystem = AnimationSystem.new()
    self.combatSystem = CombatSystem.new()
    self.enemySpawner = EnemySpawner.new()

    -- Set up renderer
    self.renderer:setCamera(self.camera)

    -- Game state
    self.player = Entity.new(0, 0, TILE - 12, TILE - 12, Config.COLORS.PLAYER, 150, 10, true)
    self.enemies = {}
    self.moveDir = {x = 0, y = 0}

    -- Ensure player spawns in a safe area
    self:findSafeSpawnPosition()

    -- XP and bonus systems
    self.xpShardManager = XPShardSystem.XPShardManager.new()
    self.bonusSelection = nil
    self.gameOverScene = nil

    -- Initialize bonus selection at start
    self:showBonusSelection()

    return self
end

function RogueScene:onEnter()
    -- Initialize any scene-specific resources
end

function RogueScene:onExit()
    -- Cleanup resources
    self.projectilePool:clear()
    self.damageNumberPool:clear()
    self.animationPool:clear()
    self.spatialGrid:clear()
end

function RogueScene:findSafeSpawnPosition()
    local attempts = 0
    local maxAttempts = 50
    
    repeat
        local x, y = self.infiniteMap:randomFloorTile(0, 0)
        self.player.x = x * 32 + 4
        self.player.y = y * 32 + 4
        attempts = attempts + 1
    until self.infiniteMap:getTileAtWorldPos(self.player.x, self.player.y) == 0 or attempts >= maxAttempts
end

function RogueScene:showBonusSelection()
    self.gameState:goToBonusSelection()
    self.bonusSelection = BonusSystem.BonusSelection.new(self.player.bonuses)
end

function RogueScene:keypressed(key)
    if self.gameState:isBonusSelection() then
        if key == '1' then
            self:selectBonus(1)
        elseif key == '2' then
            self:selectBonus(2)
        elseif key == '3' then
            self:selectBonus(3)
        end
    elseif self.gameState:isGameOver() then
        if key == 'r' then
            self:restartGame()
        elseif key == 'escape' then
            love.event.quit()
        end
    else
        if key == 'space' then
            self:performAutoAttack()
        end
    end
end

function RogueScene:keyreleased(key)
    -- Handle key releases if needed
end

function RogueScene:mousepressed(x, y, button)
    if self.gameState:isGameOver() and self.gameOverScene then
        self.gameOverScene:mousepressed(x, y, button)
        if self.gameOverScene.restartRequested then
            self:restartGame()
        end
        return
    end
    
    if self.gameState:isBonusSelection() and self.bonusSelection then
        self.bonusSelection:mousepressed(x, y, button)
    end
end

function RogueScene:mousereleased(x, y, button)
    -- Handle mouse releases if needed
end

function RogueScene:selectBonus(index)
    if not self.bonusSelection then return end
    
    local selectedBonus = self.bonusSelection:selectBonus(index)
    if selectedBonus then
        self.player:applyBonus(selectedBonus)
        self.gameState:resumePlaying()
        self.bonusSelection = nil
    end
end

function RogueScene:performAutoAttack()
    if self.player.autoAttackCooldown > 0 then return end
    
    local attackAngle = math.atan2(self.player.facingDirection.y, self.player.facingDirection.x)
    local startAngle = attackAngle - self.player.autoAttackAngle / 2
    local endAngle = attackAngle + self.player.autoAttackAngle / 2
    
    local playerCenterX = self.player.x + self.player.w / 2
    local playerCenterY = self.player.y + self.player.h / 2
    
    -- Find enemies in attack range using spatial grid
    local nearbyEnemies = self.spatialGrid:getEntitiesInRadius(
        playerCenterX, playerCenterY, self.player.autoAttackRange
    )
    
    local hitEnemies = {}
    for _, enemy in ipairs(nearbyEnemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local angle = math.atan2(dy, dx)
        
        if angle >= startAngle and angle <= endAngle then
            table.insert(hitEnemies, enemy)
        end
    end
    
    -- Perform multi-strike attacks
    for i = 1, self.player.multiStrike do
        for _, enemy in ipairs(hitEnemies) do
            local damage = self.player.autoAttackDamage
            if math.random() < self.player.critChance then
                damage = damage * 2
            end
            
            enemy:takeDamage(damage, love.timer.getTime())
            
            -- Add damage number using object pool
            local damageNum = self.damageNumberPool:get()
            damageNum.x = enemy.x + enemy.w/2
            damageNum.y = enemy.y
            damageNum.damage = damage
            damageNum.life = 1.0
        end
    end
    
    -- Chain lightning effect
    if self.player.chainLightning > 0 and #hitEnemies > 0 then
        self.combatSystem:chainLightningAttack(
            hitEnemies[1], self.player.chainLightning, self.enemies, self.player, self.animationSystem
        )
    end
    
    -- Explosive attack effect
    if self.player.explosiveAttack > 0 then
        for _, enemy in ipairs(hitEnemies) do
            self.animationSystem:addAnimation("explosion", 
                enemy.x + enemy.w/2, enemy.y + enemy.h/2, 0, 0, 0.3, {1, 0.5, 0})
        end
    end
    
    self.player.autoAttackCooldown = self.player.baseAutoAttackCooldown
end

function RogueScene:update(dt)
    -- Update performance monitoring
    self.performance:update(dt)
    
    -- Handle different game states
    if self.gameState:isBonusSelection() then
        return
    end
    
    if self.gameState:isGameOver() then
        if self.gameOverScene then
            self.gameOverScene:update(dt)
        end
        return
    end
    
    -- Update input manager
    self.inputManager:update(dt)
    
    -- Get movement input
    local x, y = self.inputManager:getMovementVector()
    
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
    
    -- Update spatial grid
    self.spatialGrid:updateEntity(self.player)
    
    -- Enemy AI - chase player (with slow effect)
    local enemySpeedMultiplier = 1.0
    if self.player.enemySlow then
        enemySpeedMultiplier = 1.0 - self.player.enemySlow
    end
    
    for _, enemy in ipairs(self.enemies) do
        local dx = self.player.x + self.player.w/2 - (enemy.x + enemy.w/2)
        local dy = self.player.y + self.player.h/2 - (enemy.y + enemy.h/2)
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 0 then
            local moveX = (dx / distance) * enemy.speed * enemySpeedMultiplier * dt
            local moveY = (dy / distance) * enemy.speed * enemySpeedMultiplier * dt
            self:moveEntity(enemy, moveX, moveY)
        end
        
        -- Update spatial grid for enemy
        self.spatialGrid:updateEntity(enemy)
        
        -- Enemy attack player
        if distance < 20 and love.timer.getTime() - enemy.lastAttackTime >= enemy.attackCooldown then
            local damage = enemy.attackPower or 1
            if not self.player.godMode then
                self.player:takeDamage(damage, love.timer.getTime())
            end
            enemy.lastAttackTime = love.timer.getTime()
        end
    end
    
    -- Update cooldowns
    if self.player.autoAttackCooldown > 0 then
        self.player.autoAttackCooldown = self.player.autoAttackCooldown - dt
    end
    
    -- Update infinite map
    self.infiniteMap:update(self.player.x, self.player.y)
    
    -- Update enemy spawning
    self.enemySpawner:update(dt, self.enemies, self.player, self.infiniteMap)
    
    -- Handle passive bonuses
    self:updatePassiveBonuses(dt)
    
    -- Automatic magical powers
    self:updateAutomaticPowers(dt)
    
    -- Update animations
    self.animationSystem:update(dt)
    
    -- Update XP shards
    local collectedXP = self.xpShardManager:update(dt, self.player.x + self.player.w/2, self.player.y + self.player.h/2,
        self.player.collectRadius * self.player.collectRadiusMultiplier, 200 * self.player.xpMagnet)
    
    -- Add collected XP to player
    if collectedXP > 0 then
        self.player.xp = self.player.xp + collectedXP * self.player.xpMultiplier
        
        -- Check for level up
        while self.player.xp >= self.player.xpToNext do
            self.player:levelUp()
            self:showBonusSelection()
        end
    end
    
    -- Update projectiles using object pool
    self:updateProjectiles(dt)
    
    -- Update damage numbers using object pool
    self:updateDamageNumbers(dt)
    
    -- Update camera to follow player
    self.camera:update(dt, self.player.x, self.player.y, self.player.w, self.player.h)
    
    -- Check for game over
    if self.player.hp <= 0 then
        self.gameState:goToGameOver()
        if not self.gameOverScene then
            self.gameOverScene = GameOverScene.new(self.player.level, self.player.xp, self.player.enemiesKilled)
            self.gameOverScene:onEnter()
        end
    end
end

function RogueScene:updateProjectiles(dt)
    self.projectilePool:update(dt, function(projectile, deltaTime)
        -- Update position
        projectile.x = projectile.x + projectile.vx * deltaTime
        projectile.y = projectile.y + projectile.vy * deltaTime
        projectile.life = projectile.life - deltaTime
        
        -- Check collision with enemies using spatial grid
        local nearbyEnemies = self.spatialGrid:getEntitiesInRadius(
            projectile.x, projectile.y, projectile.size + 20
        )
        
        for _, enemy in ipairs(nearbyEnemies) do
            local dx = projectile.x - (enemy.x + enemy.w/2)
            local dy = projectile.y - (enemy.y + enemy.h/2)
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance < projectile.size + enemy.w/2 then
                -- Hit enemy
                enemy:takeDamage(projectile.damage, love.timer.getTime())
                
                -- Add damage number using object pool
                local damageNum = self.damageNumberPool:get()
                damageNum.x = enemy.x + enemy.w/2
                damageNum.y = enemy.y
                damageNum.damage = projectile.damage
                damageNum.life = 1.0
                
                -- Special effects
                if projectile.type == "ice_shard" then
                    enemy.speed = enemy.speed * 0.5  -- Slow enemy
                end
                
                -- Remove projectile unless piercing
                if not projectile.piercing then
                    projectile.active = false
                    return
                end
            end
        end
        
        -- Remove expired projectiles
        if projectile.life <= 0 then
            projectile.active = false
        end
    end)
end

function RogueScene:updateDamageNumbers(dt)
    self.damageNumberPool:update(dt, function(damageNum, deltaTime)
        damageNum.y = damageNum.y - 50 * deltaTime  -- Float upward
        damageNum.life = damageNum.life - deltaTime
    end)
end

function RogueScene:updatePassiveBonuses(dt)
    local currentTime = love.timer.getTime()
    
    -- Health regeneration
    if self.player.healthRegen > 0 and currentTime - self.player.lastHealthRegen >= 1.0 then
        self.player.hp = math.min(self.player.maxHp, self.player.hp + self.player.healthRegen)
        self.player.lastHealthRegen = currentTime
    end
    
    -- Speed burst
    if self.player.speedBurstTime > 0 then
        self.player.speedBurstTime = self.player.speedBurstTime - dt
    end
    
    -- XP Rain
    if self.player.xpRain and currentTime - self.player.lastXPRain >= 1.0 then
        self.player:addXP(self.player.xpRain)
        self.player.lastXPRain = currentTime
    end
    
    -- God Mode
    if self.player.godMode and currentTime - self.player.lastGodMode >= 2.0 then
        for _, enemy in ipairs(self.enemies) do
            enemy:takeDamage(5, currentTime)
        end
        self.player.lastGodMode = currentTime
    end
    
    -- Teleport
    if self.player.teleport and currentTime - self.player.lastTeleport >= 3.0 then
        local x, y = self.infiniteMap:randomFloorTile(self.player.x, self.player.y)
        self.player.x = x * 32 + 4
        self.player.y = y * 32 + 4
        self.player.lastTeleport = currentTime
    end
end

function RogueScene:updateAutomaticPowers(dt)
    -- Update cooldowns
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
    
    -- Cast magical powers
    if self.player.fireball and self.player.fireballCooldown <= 0 and #self.enemies > 0 then
        local projectile = self.combatSystem:castFireball(self.player, self.enemies, self.animationSystem)
        if projectile then
            self.projectilePool:get()
            -- Copy projectile data to pooled object
            for k, v in pairs(projectile) do
                self.projectilePool.activeObjects[#self.projectilePool.activeObjects][k] = v
            end
        end
    end
    
    if self.player.iceShard and self.player.iceShardCooldown <= 0 and #self.enemies > 0 then
        local projectile = self.combatSystem:castIceShard(self.player, self.enemies, self.animationSystem)
        if projectile then
            self.projectilePool:get()
            -- Copy projectile data to pooled object
            for k, v in pairs(projectile) do
                self.projectilePool.activeObjects[#self.projectilePool.activeObjects][k] = v
            end
        end
    end
    
    if self.player.lightningBolt and self.player.lightningBoltCooldown <= 0 and #self.enemies > 0 then
        self.combatSystem:castLightningBolt(self.player, self.enemies, self.animationSystem)
    end
    
    if self.player.meteor and self.player.meteorCooldown <= 0 and #self.enemies > 0 then
        local projectile = self.combatSystem:castMeteor(self.player, self.enemies, self.animationSystem)
        if projectile then
            self.projectilePool:get()
            -- Copy projectile data to pooled object
            for k, v in pairs(projectile) do
                self.projectilePool.activeObjects[#self.projectilePool.activeObjects][k] = v
            end
        end
    end
    
    if self.player.arcaneMissile and self.player.arcaneMissileCooldown <= 0 and #self.enemies > 0 then
        local projectile = self.combatSystem:castArcaneMissile(self.player, self.enemies, self.animationSystem)
        if projectile then
            self.projectilePool:get()
            -- Copy projectile data to pooled object
            for k, v in pairs(projectile) do
                self.projectilePool.activeObjects[#self.projectilePool.activeObjects][k] = v
            end
        end
    end
    
    if self.player.shadowBolt and self.player.shadowBoltCooldown <= 0 and #self.enemies > 0 then
        local projectile = self.combatSystem:castShadowBolt(self.player, self.enemies, self.animationSystem)
        if projectile then
            self.projectilePool:get()
            -- Copy projectile data to pooled object
            for k, v in pairs(projectile) do
                self.projectilePool.activeObjects[#self.projectilePool.activeObjects][k] = v
            end
        end
    end
end

function RogueScene:moveEntity(entity, dx, dy)
    local newX = entity.x + dx
    local newY = entity.y + dy
    
    -- Check collision with walls
    local canMoveX = true
    local canMoveY = true
    
    -- Check X movement
    if dx ~= 0 then
        local tile1 = self.infiniteMap:getTileAtWorldPos(newX, entity.y)
        local tile2 = self.infiniteMap:getTileAtWorldPos(newX, entity.y + entity.h)
        if tile1 == 1 or tile2 == 1 then
            canMoveX = false
        end
    end
    
    -- Check Y movement
    if dy ~= 0 then
        local tile1 = self.infiniteMap:getTileAtWorldPos(entity.x, newY)
        local tile2 = self.infiniteMap:getTileAtWorldPos(entity.x + entity.w, newY)
        if tile1 == 1 or tile2 == 1 then
            canMoveY = false
        end
    end
    
    -- Apply movement
    if canMoveX then
        entity.x = newX
    end
    if canMoveY then
        entity.y = newY
    end
end

function RogueScene:restartGame()
    -- Reset all game state
    self.player = Entity.new(0, 0, TILE - 12, TILE - 12, Config.COLORS.PLAYER, 150, 10, true)
    self.enemies = {}
    self.moveDir = {x = 0, y = 0}
    
    -- Clear object pools
    self.projectilePool:clear()
    self.damageNumberPool:clear()
    self.animationPool:clear()
    self.spatialGrid:clear()
    
    -- Reset systems
    self.infiniteMap = InfiniteMap.new()
    self.animationSystem = AnimationSystem.new()
    self.combatSystem = CombatSystem.new()
    self.enemySpawner = EnemySpawner.new()
    self.xpShardManager = XPShardSystem.XPShardManager.new()
    
    -- Reset game state
    self.gameState:resumePlaying()
    self.bonusSelection = nil
    self.gameOverScene = nil
    
    -- Find safe spawn position
    self:findSafeSpawnPosition()
    
    -- Show bonus selection
    self:showBonusSelection()
end

function RogueScene:drawHealthBar(entity, x, y, width, height)
    self.renderer:drawHealthBar(entity, x, y, width, height)
end

function RogueScene:render()
    love.graphics.clear(Config.COLORS.BACKGROUND[1], Config.COLORS.BACKGROUND[2], Config.COLORS.BACKGROUND[3])
    
    -- Handle bonus selection screen
    if self.gameState:isBonusSelection() then
        if self.bonusSelection then
            self.bonusSelection:render()
        end
        return
    end
    
    -- Handle game over screen
    if self.gameState:isGameOver() then
        if self.gameOverScene then
            self.gameOverScene:render()
        end
        return
    end
    
    -- Apply camera transformation
    self.camera:apply()
    
    -- Draw infinite map tiles
    self.infiniteMap:render(self.camera.x, self.camera.y, self.camera.zoom, SCREEN_W, SCREEN_H)
    
    -- Draw XP shards
    self.xpShardManager:render()
    
    -- Draw entities
    self.renderer:drawEntity(self.player, Config.COLORS.PLAYER)
    
    for _, enemy in ipairs(self.enemies) do
        self.renderer:drawEntity(enemy, Config.COLORS.ENEMY)
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
    
    -- Draw projectiles using object pool
    self.projectilePool:render(function(projectile)
        self.renderer:drawProjectile(projectile, {1, 0.5, 0, 0.8})
    end)
    
    -- Draw damage numbers using object pool
    self.damageNumberPool:render(function(damageNum)
        self.renderer:drawDamageNumber(damageNum, {1, 0.2, 0.2})
    end)
    
    -- Draw auto-attack cone when attacking
    if self.player.autoAttackCooldown > 0.4 then
        local playerCenterX = self.player.x + self.player.w / 2
        local playerCenterY = self.player.y + self.player.h / 2
        local attackAngle = math.atan2(self.player.facingDirection.y, self.player.facingDirection.x)
        local startAngle = attackAngle - self.player.autoAttackAngle / 2
        local endAngle = attackAngle + self.player.autoAttackAngle / 2
        
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.arc('fill', playerCenterX, playerCenterY, self.player.autoAttackRange, startAngle, endAngle)
    end
    
    -- Draw animations
    self.animationSystem:render()
    
    -- Draw UI
    love.graphics.setColor(Config.COLORS.UI[1], Config.COLORS.UI[2], Config.COLORS.UI[3])
    love.graphics.print("Level: " .. self.player.level, 10, 10)
    love.graphics.print("HP: " .. math.floor(self.player.hp) .. "/" .. math.floor(self.player.maxHp), 10, 30)
    love.graphics.print("XP: " .. math.floor(self.player.xp) .. "/" .. math.floor(self.player.xpToNext), 10, 50)
    love.graphics.print("Enemies: " .. #self.enemies, 10, 70)
    
    -- Draw performance info if enabled
    if Config.get('RENDERING', 'SHOW_PERFORMANCE', false) then
        self.performance:render(SCREEN_W - 200, 10)
    end
end

return RogueScene
