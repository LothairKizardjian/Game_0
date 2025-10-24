-- Enemy Spawning System for Game_0
-- Handles enemy spawning, scaling, and management

local EnemySpawner = {}
EnemySpawner.__index = EnemySpawner

function EnemySpawner.new()
    local self = setmetatable({}, EnemySpawner)

    self.spawnTimer = 0
    self.startTime = love.timer.getTime()

    return self
end

function EnemySpawner:update(dt, enemies, player, infiniteMap)
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
                self:spawnEnemy(enemies, player, infiniteMap)
            end
        end
        self.spawnTimer = 0
    end
end

function EnemySpawner:spawnEnemy(enemies, player, infiniteMap)
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
    local enemy = {
        x = x * 32 + 4,
        y = y * 32 + 4,
        w = enemySize,
        h = enemySize,
        color = scalingFactor > 1.0 and {255/255, 100/255, 100/255} or {220/255, 80/255, 80/255},  -- Brighter red for scaled enemies
        speed = 60 * scalingFactor,
        hp = math.floor(3 * scalingFactor),
        maxHp = math.floor(3 * scalingFactor),
        isPlayer = false,
        damageCooldown = 0.5,
        lastDamageTime = 0,
        attackPower = 1 * scalingFactor,  -- New property for attack power
        scalingFactor = scalingFactor,  -- Store scaling factor for reference
        attackCooldown = 1.0,  -- Attack cooldown in seconds
        lastAttackTime = 0  -- Time of last attack
    }

    -- Add enemy methods
    enemy.getRect = function(self)
        return {x = self.x, y = self.y, w = self.w, h = self.h}
    end

    enemy.collidesWith = function(self, other)
        return self.x < other.x + other.w and
               self.x + self.w > other.x and
               self.y < other.y + other.h and
               self.y + self.h > other.y
    end

    enemy.takeDamage = function(self, damage, currentTime)
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

    enemy.getHealthPercent = function(self)
        return self.hp / self.maxHp
    end

    table.insert(enemies, enemy)
end

return EnemySpawner
