-- Roguelike Game Scene for Game_0
-- Main game logic, entities, and rendering

local RogueScene = {}
RogueScene.__index = RogueScene

-- Constants
local TILE = 32
local GRID_W, GRID_H = 50, 35  -- Much larger map
local SCREEN_W, SCREEN_H = 800, 576  -- Fixed screen size

-- Camera settings
local CAMERA_ZOOM = 2.0
local CAMERA_SMOOTH = 5.0

-- Colors
local COLOR_BG = {12/255, 12/255, 16/255}
local COLOR_WALL = {50/255, 50/255, 70/255}
local COLOR_FLOOR = {22/255, 22/255, 28/255}
local COLOR_PLAYER = {80/255, 200/255, 120/255}
local COLOR_ENEMY = {220/255, 80/255, 80/255}
local COLOR_UI = {230/255, 230/255, 230/255}

-- Entity class
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
    return self
end

function Entity:getRect()
    return {x = self.x, y = self.y, w = self.w, h = self.h}
end

function Entity:collidesWith(other)
    local r1 = self:getRect()
    local r2 = other:getRect()
    return r1.x < r2.x + r2.w and
           r1.x + r1.w > r2.x and
           r1.y < r2.y + r2.h and
           r1.y + r1.h > r2.y
end

function Entity:takeDamage(damage, currentTime)
    if currentTime - self.lastDamageTime >= self.damageCooldown then
        self.hp = math.max(0, self.hp - damage)
        self.lastDamageTime = currentTime
        return true
    end
    return false
end

function Entity:getHealthPercent()
    return self.hp / self.maxHp
end

-- Map generation with improved algorithm
local function generateMap(w, h)
    local map = {}
    for y = 1, h do
        map[y] = {}
        for x = 1, w do
            map[y][x] = 0
        end
    end

    -- Borders
    for x = 1, w do
        map[1][x] = 1
        map[h][x] = 1
    end
    for y = 1, h do
        map[y][1] = 1
        map[y][w] = 1
    end

    -- Generate rooms and corridors
    local rooms = {}
    local numRooms = math.random(8, 15)

    -- Create rooms
    for i = 1, numRooms do
        local roomW = math.random(4, 12)
        local roomH = math.random(4, 8)
        local roomX = math.random(2, w - roomW - 1)
        local roomY = math.random(2, h - roomH - 1)

        -- Check if room overlaps with existing rooms
        local overlaps = false
        for _, room in ipairs(rooms) do
            if roomX < room.x + room.w and roomX + roomW > room.x and
               roomY < room.y + room.h and roomY + roomH > room.y then
                overlaps = true
                break
            end
        end

        if not overlaps then
            table.insert(rooms, {x = roomX, y = roomY, w = roomW, h = roomH})

            -- Clear room area
            for ry = roomY, roomY + roomH - 1 do
                for rx = roomX, roomX + roomW - 1 do
                    map[ry][rx] = 0
                end
            end
        end
    end

    -- Connect rooms with corridors
    for i = 2, #rooms do
        local prevRoom = rooms[i-1]
        local currRoom = rooms[i]

        -- Horizontal corridor
        local startX = math.min(prevRoom.x + math.floor(prevRoom.w/2), currRoom.x + math.floor(currRoom.w/2))
        local endX = math.max(prevRoom.x + math.floor(prevRoom.w/2), currRoom.x + math.floor(currRoom.w/2))
        for x = startX, endX do
            map[prevRoom.y + math.floor(prevRoom.h/2)][x] = 0
        end

        -- Vertical corridor
        local startY = math.min(prevRoom.y + math.floor(prevRoom.h/2), currRoom.y + math.floor(currRoom.h/2))
        local endY = math.max(prevRoom.y + math.floor(prevRoom.h/2), currRoom.y + math.floor(currRoom.h/2))
        for y = startY, endY do
            map[y][currRoom.x + math.floor(currRoom.w/2)] = 0
        end
    end

    -- Add some random obstacles in non-room areas
    for _ = 1, math.random(20, 40) do
        local rx, ry = math.random(2, w-1), math.random(2, h-1)
        if map[ry][rx] == 0 then
            -- Check if it's not in a room
            local inRoom = false
            for _, room in ipairs(rooms) do
                if rx >= room.x and rx < room.x + room.w and
                   ry >= room.y and ry < room.y + room.h then
                    inRoom = true
                    break
                end
            end
            if not inRoom then
                map[ry][rx] = 1
            end
        end
    end

    return map, rooms
end

-- Collision detection
local function rectCollidesWalls(rect, tilemap)
    local tilesToCheck = {}
    local corners = {
        {rect.x, rect.y},
        {rect.x + rect.w, rect.y},
        {rect.x, rect.y + rect.h},
        {rect.x + rect.w, rect.y + rect.h}
    }

    for _, corner in ipairs(corners) do
        local tx, ty = math.floor(corner[1] / TILE) + 1, math.floor(corner[2] / TILE) + 1
        if tx >= 1 and tx <= GRID_W and ty >= 1 and ty <= GRID_H then
            if tilemap[ty][tx] == 1 then
                return true
            end
        end
    end
    return false
end

function RogueScene.new()
    local self = setmetatable({}, RogueScene)

    self.tilemap, self.rooms = generateMap(GRID_W, GRID_H)

    -- Smaller player for easier movement
    local playerSize = TILE - 12  -- Much smaller than before
    self.player = Entity.new(2 * TILE, 2 * TILE, playerSize, playerSize, COLOR_PLAYER, 150, 10, true)
    self.player.damageCooldown = 1.0  -- 1 second damage cooldown for player
    self.enemies = {}

    -- Create more enemies for larger map
    local numEnemies = math.random(8, 15)
    for _ = 1, numEnemies do
        local x, y = self:randomFloorTile()
        local enemySize = TILE - 8
        local enemy = Entity.new(
            x * TILE + 4, y * TILE + 4, enemySize, enemySize,
            COLOR_ENEMY, 90, 3, false
        )
        enemy.damageCooldown = 0.5  -- 0.5 second damage cooldown for enemies
        table.insert(self.enemies, enemy)
    end

    self.moveDir = {x = 0, y = 0}
    self.keys = {}

    -- Camera system
    self.camera = {
        x = 0,
        y = 0,
        targetX = 0,
        targetY = 0,
        zoom = CAMERA_ZOOM
    }

    return self
end

function RogueScene:onEnter()
    -- Initialize any scene-specific resources
end

function RogueScene:onExit()
    -- Cleanup any scene-specific resources
end

function RogueScene:keypressed(key)
    self.keys[key] = true

    -- Zoom controls
    if key == '=' or key == '+' then
        self.camera.zoom = math.min(self.camera.zoom + 0.5, 4.0)
    elseif key == '-' then
        self.camera.zoom = math.max(self.camera.zoom - 0.5, 0.5)
    elseif key == '0' then
        self.camera.zoom = 1.0
    end
end

function RogueScene:keyreleased(key)
    self.keys[key] = false
end

function RogueScene:update(dt)
    -- Update movement direction
    local x = 0
    local y = 0

    if self.keys['d'] or self.keys['right'] then x = x + 1 end
    if self.keys['a'] or self.keys['left'] then x = x - 1 end
    if self.keys['s'] or self.keys['down'] then y = y + 1 end
    if self.keys['w'] or self.keys['up'] then y = y - 1 end

    if x ~= 0 or y ~= 0 then
        local length = math.sqrt(x*x + y*y)
        self.moveDir.x = x / length
        self.moveDir.y = y / length
    else
        self.moveDir.x = 0
        self.moveDir.y = 0
    end

    -- Player movement with collision
    if self.moveDir.x ~= 0 or self.moveDir.y ~= 0 then
        self:moveEntity(self.player, self.moveDir.x * self.player.speed * dt, self.moveDir.y * self.player.speed * dt)
    end

    -- Enemy AI - chase player
    for _, enemy in ipairs(self.enemies) do
        local dx = self.player.x - enemy.x
        local dy = self.player.y - enemy.y
        local length = math.sqrt(dx*dx + dy*dy)

        if length > 0 then
            local dirX = dx / length
            local dirY = dy / length
            self:moveEntity(enemy, dirX * enemy.speed * dt, dirY * enemy.speed * dt)
        end
    end

    -- Combat - enemies damage player on collision
    for _, enemy in ipairs(self.enemies) do
        if self.player:collidesWith(enemy) then
            if self.player:takeDamage(1, love.timer.getTime()) then
                -- Player took damage, could add visual feedback here
            end
        end
    end

    -- Remove dead enemies
    local aliveEnemies = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy.hp > 0 then
            table.insert(aliveEnemies, enemy)
        end
    end
    self.enemies = aliveEnemies

    -- Update camera to follow player
    self:updateCamera(dt)
end

function RogueScene:render()
    love.graphics.clear(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3])

    -- Apply camera transformation
    love.graphics.push()
    love.graphics.scale(self.camera.zoom, self.camera.zoom)
    love.graphics.translate(-self.camera.x, -self.camera.y)

    -- Draw tiles
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local tile = self.tilemap[y][x]
            local color = tile == 1 and COLOR_WALL or COLOR_FLOOR
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle('fill', (x-1) * TILE, (y-1) * TILE, TILE, TILE)
        end
    end

    -- Draw entities
    love.graphics.setColor(self.player.color[1], self.player.color[2], self.player.color[3])
    love.graphics.rectangle('fill', self.player.x, self.player.y, self.player.w, self.player.h)

    for _, enemy in ipairs(self.enemies) do
        love.graphics.setColor(enemy.color[1], enemy.color[2], enemy.color[3])
        love.graphics.rectangle('fill', enemy.x, enemy.y, enemy.w, enemy.h)
    end
    
    -- Draw health bars for entities
    -- Player health bar
    if self.player.hp < self.player.maxHp then
        self:drawHealthBar(self.player, self.player.x, self.player.y - 8, self.player.w, 4)
    end
    
    -- Enemy health bars
    for _, enemy in ipairs(self.enemies) do
        if enemy.hp < enemy.maxHp then
            self:drawHealthBar(enemy, enemy.x, enemy.y - 6, enemy.w, 3)
        end
    end

    -- Reset transformation for HUD
    love.graphics.pop()

    -- HUD (not affected by camera)
    love.graphics.setColor(COLOR_UI[1], COLOR_UI[2], COLOR_UI[3])
    love.graphics.print("HP: " .. self.player.hp .. "/" .. self.player.maxHp, 8, 6)
    love.graphics.print("Move: WASD/Arrows — ESC to quit", 8, 28)
    love.graphics.print("Zoom: " .. string.format("%.1f", self.camera.zoom), 8, 50)
    love.graphics.print("Map: " .. GRID_W .. "x" .. GRID_H .. " tiles", 8, 72)
    love.graphics.print("Enemies: " .. #self.enemies, 8, 94)
    
    -- Player health bar in HUD
    local hudBarWidth = 120
    local hudBarHeight = 8
    self:drawHealthBar(self.player, 8, 116, hudBarWidth, hudBarHeight)
end

function RogueScene:drawHealthBar(entity, x, y, width, height)
    local healthPercent = entity:getHealthPercent()
    local barWidth = width * healthPercent
    
    -- Background (red)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle('fill', x, y, width, height)
    
    -- Health bar (green)
    if healthPercent > 0.6 then
        love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
    elseif healthPercent > 0.3 then
        love.graphics.setColor(0.8, 0.8, 0.2, 0.8)
    else
        love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    end
    love.graphics.rectangle('fill', x, y, barWidth, height)
    
    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('line', x, y, width, height)
end

function RogueScene:moveEntity(entity, dx, dy)
    -- Move X
    entity.x = entity.x + dx
    if rectCollidesWalls(entity:getRect(), self.tilemap) then
        entity.x = entity.x - dx
    end

    -- Move Y
    entity.y = entity.y + dy
    if rectCollidesWalls(entity:getRect(), self.tilemap) then
        entity.y = entity.y - dy
    end
end

function RogueScene:randomFloorTile()
    while true do
        local x, y = math.random(2, GRID_W-1), math.random(2, GRID_H-1)
        if self.tilemap[y][x] == 0 then
            return x, y
        end
    end
end

function RogueScene:updateCamera(dt)
    -- Target camera position (center on player)
    local playerCenterX = self.player.x + self.player.w / 2
    local playerCenterY = self.player.y + self.player.h / 2

    -- Calculate screen center in world coordinates
    local screenCenterX = SCREEN_W / (2 * self.camera.zoom)
    local screenCenterY = SCREEN_H / (2 * self.camera.zoom)

    -- Set target camera position
    self.camera.targetX = playerCenterX - screenCenterX
    self.camera.targetY = playerCenterY - screenCenterY

    -- Apply camera boundaries (prevent camera from going outside map)
    local mapWidth = GRID_W * TILE
    local mapHeight = GRID_H * TILE
    local visibleWidth = SCREEN_W / self.camera.zoom
    local visibleHeight = SCREEN_H / self.camera.zoom
    local maxCameraX = math.max(0, mapWidth - visibleWidth)
    local maxCameraY = math.max(0, mapHeight - visibleHeight)

    self.camera.targetX = math.max(0, math.min(self.camera.targetX, maxCameraX))
    self.camera.targetY = math.max(0, math.min(self.camera.targetY, maxCameraY))

    -- Smooth camera movement
    local lerpFactor = CAMERA_SMOOTH * dt
    self.camera.x = self.camera.x + (self.camera.targetX - self.camera.x) * lerpFactor
    self.camera.y = self.camera.y + (self.camera.targetY - self.camera.y) * lerpFactor
end

return RogueScene
