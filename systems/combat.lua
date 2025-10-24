-- Combat System for Game_0
-- Handles auto-attack, magical powers, and combat mechanics

local CombatSystem = {}
CombatSystem.__index = CombatSystem

function CombatSystem.new()
    local self = setmetatable({}, CombatSystem)

    return self
end

function CombatSystem:performAutoAttack(player, enemies, animationSystem)
    if player.autoAttackCooldown > 0 then return end

    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    -- Use player's facing direction for attack
    local attackDirX = player.facingDirection.x
    local attackDirY = player.facingDirection.y

    -- Normalize direction
    local length = math.sqrt(attackDirX * attackDirX + attackDirY * attackDirY)
    if length > 0 then
        attackDirX = attackDirX / length
        attackDirY = attackDirY / length
    end

    -- Perform multi-strike attacks
    for strike = 1, player.multiStrike do
        local hitEnemies = {}

        -- Check enemies in cone
        for _, enemy in ipairs(enemies) do
            local dx = enemy.x + enemy.w/2 - playerCenterX
            local dy = enemy.y + enemy.h/2 - playerCenterY
            local distance = math.sqrt(dx*dx + dy*dy)

            if distance <= player.autoAttackRange then
                -- Check if enemy is in cone
                local dot = dx * attackDirX + dy * attackDirY
                local angle = math.acos(math.max(-1, math.min(1, dot / distance)))

                if angle <= player.autoAttackAngle / 2 then
                    -- Apply damage with crit chance
                    local damage = player.autoAttackDamage
                    if math.random() < player.critChance then
                        damage = damage * 2
                    end
                    enemy:takeDamage(damage, love.timer.getTime())
                    table.insert(hitEnemies, enemy)

                    -- Explosive attack
                    if player.explosiveAttack > 0 then
                        self:createExplosion(enemy.x + enemy.w/2, enemy.y + enemy.h/2, player.explosiveAttack, enemies, animationSystem)
                    end
                end
            end
        end

        -- Chain lightning effect
        if player.chainLightning > 0 and #hitEnemies > 0 then
            self:chainLightningAttack(hitEnemies[1], player.chainLightning, enemies, player, animationSystem)
        end
    end

    -- Set cooldown based on bonuses
    player.autoAttackCooldown = player.baseAutoAttackCooldown
end

function CombatSystem:castFireball(player, enemies, animationSystem)
    if player.fireballCooldown > 0 then return end

    -- Find nearest enemy
    local nearestEnemy = nil
    local nearestDistance = math.huge
    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance < nearestDistance then
            nearestEnemy = enemy
            nearestDistance = distance
        end
    end

    if nearestEnemy then
        -- Create fireball projectile
        self:createProjectile(playerCenterX, playerCenterY, nearestEnemy.x + nearestEnemy.w/2, nearestEnemy.y + nearestEnemy.h/2, "fireball", 3, 200, enemies)

        -- Add fireball animation
        local dx = nearestEnemy.x + nearestEnemy.w/2 - playerCenterX
        local dy = nearestEnemy.y + nearestEnemy.h/2 - playerCenterY
        local length = math.sqrt(dx*dx + dy*dy)
        if length > 0 then
            animationSystem:addAnimation("fireball", playerCenterX, playerCenterY, dx/length * 200, dy/length * 200, 1.0, {1, 0.3, 0})
        end

        player.fireballCooldown = 2.0
    end
end

function CombatSystem:castIceShard(player, enemies, animationSystem)
    if player.iceShardCooldown > 0 then return end

    -- Find nearest enemy
    local nearestEnemy = nil
    local nearestDistance = math.huge
    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance < nearestDistance then
            nearestEnemy = enemy
            nearestDistance = distance
        end
    end

    if nearestEnemy then
        -- Create ice shard projectile
        self:createProjectile(playerCenterX, playerCenterY, nearestEnemy.x + nearestEnemy.w/2, nearestEnemy.y + nearestEnemy.h/2, "ice_shard", 2, 150, enemies)

        -- Add ice shard animation
        local dx = nearestEnemy.x + nearestEnemy.w/2 - playerCenterX
        local dy = nearestEnemy.y + nearestEnemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        local vx = (dx / distance) * 150
        local vy = (dy / distance) * 150

        animationSystem:addAnimation("ice_shard", playerCenterX, playerCenterY, vx, vy, 1.0, {0.5, 0.8, 1}, {
            rotation = 0
        })

        player.iceShardCooldown = 1.5
    end
end

function CombatSystem:castLightningBolt(player, enemies, animationSystem)
    if player.lightningBoltCooldown > 0 then return end

    -- Find nearest enemy
    local nearestEnemy = nil
    local nearestDistance = math.huge
    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance < nearestDistance then
            nearestEnemy = enemy
            nearestDistance = distance
        end
    end

    if nearestEnemy then
        -- Add lightning bolt animation
        local dx = nearestEnemy.x + nearestEnemy.w/2 - playerCenterX
        local dy = nearestEnemy.y + nearestEnemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        local vx = (dx / distance) * 200
        local vy = (dy / distance) * 200

        animationSystem:addAnimation("lightning_bolt", playerCenterX, playerCenterY, vx, vy, 0.5, {1, 1, 0.5}, {
            alpha = 1.0
        })

        -- Chain lightning effect
        self:chainLightningAttack(nearestEnemy, 3, enemies, player, animationSystem)
        player.lightningBoltCooldown = 3.0
    end
end

function CombatSystem:castMeteor(player, enemies, animationSystem)
    if player.meteorCooldown > 0 then return end

    -- Find random enemy
    if #enemies > 0 then
        local targetEnemy = enemies[math.random(1, #enemies)]
        -- Create meteor projectile from above
        self:createProjectile(targetEnemy.x + targetEnemy.w/2, -50, targetEnemy.x + targetEnemy.w/2, targetEnemy.y + targetEnemy.h/2, "meteor", 5, 100, enemies)

        -- Add meteor animation
        animationSystem:addAnimation("meteor", targetEnemy.x + targetEnemy.w/2, -50, 0, 100, 2.0, {1, 0.3, 0}, {
            radius = 10
        })

        player.meteorCooldown = 4.0
    end
end

function CombatSystem:castArcaneMissile(player, enemies, animationSystem)
    if player.arcaneMissileCooldown > 0 then return end

    -- Find nearest 3 enemies
    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2
    local enemiesByDistance = {}

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        table.insert(enemiesByDistance, {enemy = enemy, distance = distance})
    end

    table.sort(enemiesByDistance, function(a, b) return a.distance < b.distance end)

    for i = 1, math.min(3, #enemiesByDistance) do
        local target = enemiesByDistance[i].enemy
        self:createProjectile(playerCenterX, playerCenterY, target.x + target.w/2, target.y + target.h/2, "arcane_missile", 1, 300, enemies)

        -- Add arcane missile animation
        local dx = target.x + target.w/2 - playerCenterX
        local dy = target.y + target.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        local vx = (dx / distance) * 300
        local vy = (dy / distance) * 300

        animationSystem:addAnimation("arcane_missile", playerCenterX, playerCenterY, vx, vy, 0.8, {0.8, 0.3, 1}, {
            rotation = 0
        })
    end

    player.arcaneMissileCooldown = 1.0
end

function CombatSystem:castShadowBolt(player, enemies, animationSystem)
    if player.shadowBoltCooldown > 0 then return end

    -- Find nearest enemy
    local nearestEnemy = nil
    local nearestDistance = math.huge
    local playerCenterX = player.x + player.w / 2
    local playerCenterY = player.y + player.h / 2

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - playerCenterX
        local dy = enemy.y + enemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance < nearestDistance then
            nearestEnemy = enemy
            nearestDistance = distance
        end
    end

    if nearestEnemy then
        -- Create shadow bolt projectile
        self:createProjectile(playerCenterX, playerCenterY, nearestEnemy.x + nearestEnemy.w/2, nearestEnemy.y + nearestEnemy.h/2, "shadow_bolt", 4, 250, enemies)

        -- Add shadow bolt animation
        local dx = nearestEnemy.x + nearestEnemy.w/2 - playerCenterX
        local dy = nearestEnemy.y + nearestEnemy.h/2 - playerCenterY
        local distance = math.sqrt(dx*dx + dy*dy)
        local vx = (dx / distance) * 250
        local vy = (dy / distance) * 250

        animationSystem:addAnimation("shadow_bolt", playerCenterX, playerCenterY, vx, vy, 1.2, {0.2, 0.1, 0.3}, {
            alpha = 1.0
        })

        player.shadowBoltCooldown = 2.5
    end
end

function CombatSystem:createProjectile(startX, startY, targetX, targetY, type, damage, speed, enemies)
    -- Simple projectile system - for now just deal damage immediately
    local dx = targetX - startX
    local dy = targetY - startY
    local distance = math.sqrt(dx*dx + dy*dy)

    if distance > 0 then
        -- Find enemies in the path
        for _, enemy in ipairs(enemies) do
            local enemyX = enemy.x + enemy.w/2
            local enemyY = enemy.y + enemy.h/2

            -- Check if enemy is in the path (simplified)
            local enemyDx = enemyX - startX
            local enemyDy = enemyY - startY
            local dot = (dx * enemyDx + dy * enemyDy) / (distance * distance)

            if dot >= 0 and dot <= 1 then
                local projDx = enemyX - startX
                local projDy = enemyY - startY
                local projDistance = math.sqrt(projDx*projDx + projDy*projDy)
                local lineDistance = math.abs(dx * enemyDy - dy * enemyDx) / distance

                if lineDistance < 20 and projDistance <= distance then  -- Within 20 pixels of line
                    enemy:takeDamage(damage, love.timer.getTime())

                    -- Special effects
                    if type == "ice_shard" then
                        -- Slow enemy (simplified)
                        enemy.speed = enemy.speed * 0.5
                    end
                end
            end
        end
    end
end

function CombatSystem:createExplosion(x, y, damage, enemies, animationSystem)
    -- Find all enemies within explosion radius
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x + enemy.w/2 - x
        local dy = enemy.y + enemy.h/2 - y
        local distance = math.sqrt(dx*dx + dy*dy)

        if distance <= 40 then  -- Explosion radius
            enemy:takeDamage(damage, love.timer.getTime())
        end
    end

    -- Add explosion animation
    animationSystem:addAnimation("explosion", x, y, 0, 0, 1.0, {1, 0.5, 0})
end

function CombatSystem:chainLightningAttack(sourceEnemy, chainCount, enemies, player, animationSystem)
    local chainedEnemies = {sourceEnemy}
    local usedEnemies = {[sourceEnemy] = true}

    for i = 1, chainCount do
        local nearestEnemy = nil
        local nearestDistance = math.huge

        for _, enemy in ipairs(enemies) do
            if not usedEnemies[enemy] then
                local dx = enemy.x + enemy.w/2 - (sourceEnemy.x + sourceEnemy.w/2)
                local dy = enemy.y + enemy.h/2 - (sourceEnemy.y + sourceEnemy.h/2)
                local distance = math.sqrt(dx*dx + dy*dy)

                if distance < nearestDistance and distance <= 80 then  -- Chain range
                    nearestEnemy = enemy
                    nearestDistance = distance
                end
            end
        end

        if nearestEnemy then
            table.insert(chainedEnemies, nearestEnemy)
            usedEnemies[nearestEnemy] = true
            sourceEnemy = nearestEnemy
        else
            break
        end
    end

    -- Damage all chained enemies and create animations
    for i, enemy in ipairs(chainedEnemies) do
        if enemy ~= chainedEnemies[1] then  -- Don't damage the original target again
            local damage = player.autoAttackDamage
            if math.random() < player.critChance then
                damage = damage * 2
            end
            enemy:takeDamage(damage, love.timer.getTime())

            -- Create chain lightning animation
            if i > 1 then  -- Don't animate from first enemy to itself
                local prevEnemy = chainedEnemies[i-1]
                local x1 = prevEnemy.x + prevEnemy.w/2
                local y1 = prevEnemy.y + prevEnemy.h/2
                local x2 = enemy.x + enemy.w/2
                local y2 = enemy.y + enemy.h/2

                animationSystem:addAnimation("chain_lightning", x1, y1, 0, 0, 0.3, {0.8, 0.8, 1}, {
                    x1 = x1, y1 = y1, x2 = x2, y2 = y2, alpha = 1.0
                })
            end
        end
    end
end

function CombatSystem:updateAutomaticPowers(player, enemies, animationSystem)
    -- Automatic fireball
    if player.fireball and player.fireballCooldown <= 0 and #enemies > 0 then
        self:castFireball(player, enemies, animationSystem)
    end

    -- Automatic ice shard
    if player.iceShard and player.iceShardCooldown <= 0 and #enemies > 0 then
        self:castIceShard(player, enemies, animationSystem)
    end

    -- Automatic lightning bolt
    if player.lightningBolt and player.lightningBoltCooldown <= 0 and #enemies > 0 then
        self:castLightningBolt(player, enemies, animationSystem)
    end

    -- Automatic meteor
    if player.meteor and player.meteorCooldown <= 0 and #enemies > 0 then
        self:castMeteor(player, enemies, animationSystem)
    end

    -- Automatic arcane missile
    if player.arcaneMissile and player.arcaneMissileCooldown <= 0 and #enemies > 0 then
        self:castArcaneMissile(player, enemies, animationSystem)
    end

    -- Automatic shadow bolt
    if player.shadowBolt and player.shadowBoltCooldown <= 0 and #enemies > 0 then
        self:castShadowBolt(player, enemies, animationSystem)
    end
end

return CombatSystem
