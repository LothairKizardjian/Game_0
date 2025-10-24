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
    -- Find a random floor tile away from player
    local attempts = 0
    local x, y
    repeat
        x, y = infiniteMap:randomFloorTile(player.x, player.y)
        attempts = attempts + 1

        -- Check distance from player
        local playerTileX = math.floor(player.x / 32) + 1
        local playerTileY = math.floor(player.y / 32) + 1
        local distance = math.sqrt((x - playerTileX)^2 + (y - playerTileY)^2)

        if distance >= 5 or attempts > 20 then  -- At least 5 tiles away or give up
            break
        end
    until false

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
