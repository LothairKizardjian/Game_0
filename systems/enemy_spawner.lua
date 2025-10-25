-- Enemy Spawning System for Game_0
-- Handles enemy spawning, scaling, and management

local Enemy = require('systems.enemy')

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner.new()
    local self = setmetatable({}, EnemySpawner)

    self.spawnTimer = 0
    self.startTime = love.timer.getTime()

    return self
end

function EnemySpawner:update(dt, enemies, player, infiniteMap, spriteSystem)
    self.spawnTimer = self.spawnTimer + dt
    local timeElapsed = love.timer.getTime() - self.startTime

    -- Spawn more frequently with more enemies
    local spawnRate = math.max(1.5, 2.5 - timeElapsed * 0.02)  -- Spawn faster over time

    -- Increase enemies per tier and spawn more frequently
    local enemiesPerSpawn = math.floor(1 + timeElapsed / 20)  -- More enemies per spawn every 20 seconds
    local maxEnemies = math.min(60, 20 + timeElapsed * 2.0)  -- More max enemies

    if self.spawnTimer >= spawnRate and #enemies < maxEnemies then
        -- Spawn multiple enemies at once
        for i = 1, enemiesPerSpawn do
            if #enemies < maxEnemies then
                self:spawnEnemy(enemies, player, infiniteMap, spriteSystem)
            end
        end
        self.spawnTimer = 0
    end
end

function EnemySpawner:spawnEnemy(enemies, player, infiniteMap, spriteSystem)
    -- Get screen dimensions for camera bounds
    local screenW, screenH = love.graphics.getDimensions()
    local cameraX = player.x - screenW / 4  -- Approximate camera position
    local cameraY = player.y - screenH / 4

    -- Spawn enemies outside camera view
    local attempts = 0
    local x, y
    repeat
        -- Try to spawn outside camera bounds but closer to player
        local baseDistance = math.max(screenW, screenH) / 2 + 50  -- Outside screen + smaller buffer
        local spawnDistance = baseDistance + math.random(0, 100)  -- Add some variation (50-150px beyond screen)
        local angle = math.random() * 2 * math.pi
        local spawnX = player.x + math.cos(angle) * spawnDistance
        local spawnY = player.y + math.sin(angle) * spawnDistance

        -- Convert to tile coordinates
        x = math.floor(spawnX / 32)
        y = math.floor(spawnY / 32)

        -- Check if it's a floor tile
        if infiniteMap:getTileAtWorldPos(x * 32, y * 32) == 0 then
            break
        end

        attempts = attempts + 1
    until attempts > 50  -- Give up after 50 attempts

    -- Calculate scaling based on time elapsed
    local timeElapsed = love.timer.getTime() - self.startTime
    local scalingFactor = 1.0

    if timeElapsed >= 30 then
        -- Scale enemies after 30 seconds
        local scalingTime = timeElapsed - 30
        scalingFactor = 1.0 + (scalingTime / 60) * 0.5  -- Gradual scaling over 60 seconds
        scalingFactor = math.min(scalingFactor, 2.0)  -- Cap at 2x scaling
    end

    -- Create enemy with scaling
    local enemySize = 32 - 8
    local enemyColor = scalingFactor > 1.0 and {255/255, 100/255, 100/255} or {220/255, 80/255, 80/255}
    local enemy = Enemy.new(
        x * 32 + 4,
        y * 32 + 4,
        enemySize,
        enemySize,
        enemyColor,
        60 * scalingFactor,
        math.floor(3 * scalingFactor),
        scalingFactor
    )

    -- Create individual sprite for this enemy
    if spriteSystem then
        spriteSystem:createEnemySprite(enemy.spriteName, "assets/skeleton_walk")
        enemy:setSpriteSystem(spriteSystem)
    end

    -- Enemy is now a proper Entity with all methods inherited

    table.insert(enemies, enemy)
end

return EnemySpawner
