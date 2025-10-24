-- Infinite Map System for Game_0
-- Handles chunk-based infinite map generation and management

local InfiniteMap = {}
InfiniteMap.__index = InfiniteMap

function InfiniteMap.new()
    local self = setmetatable({}, InfiniteMap)
    
    self.chunkSize = 20  -- 20x20 tiles per chunk
    self.loadedChunks = {}  -- Store loaded chunks
    self.chunkRadius = 3  -- Load chunks within 3 radius of player
    
    return self
end

function InfiniteMap:getChunkKey(x, y)
    return string.format("%d,%d", x, y)
end

function InfiniteMap:getChunkFromWorldPos(worldX, worldY)
    local chunkX = math.floor(worldX / (self.chunkSize * 32))  -- 32 is TILE size
    local chunkY = math.floor(worldY / (self.chunkSize * 32))
    return chunkX, chunkY
end

function InfiniteMap:generateChunk(chunkX, chunkY)
    local chunkKey = self:getChunkKey(chunkX, chunkY)
    if self.loadedChunks[chunkKey] then
        return self.loadedChunks[chunkKey]
    end
    
    local chunk = {
        tiles = {},
        rooms = {},
        enemies = {},
        generated = true
    }
    
    -- Generate tiles for this chunk
    for x = 0, self.chunkSize - 1 do
        chunk.tiles[x] = {}
        for y = 0, self.chunkSize - 1 do
            local worldX = chunkX * self.chunkSize + x
            local worldY = chunkY * self.chunkSize + y
            
            -- Use noise or simple pattern for terrain
            local noise = math.sin(worldX * 0.1) * math.cos(worldY * 0.1)
            if noise > 0.3 then
                chunk.tiles[x][y] = 0  -- Floor
            else
                chunk.tiles[x][y] = 1  -- Wall
            end
        end
    end
    
    -- Generate rooms in this chunk
    local numRooms = math.random(1, 3)
    for _ = 1, numRooms do
        local roomX = math.random(2, self.chunkSize - 8)
        local roomY = math.random(2, self.chunkSize - 8)
        local roomW = math.random(4, 8)
        local roomH = math.random(4, 8)
        
        -- Make sure room fits in chunk
        if roomX + roomW < self.chunkSize and roomY + roomH < self.chunkSize then
            for x = roomX, roomX + roomW - 1 do
                for y = roomY, roomY + roomH - 1 do
                    chunk.tiles[x][y] = 0  -- Floor
                end
            end
            table.insert(chunk.rooms, {x = roomX, y = roomY, w = roomW, h = roomH})
        end
    end
    
    self.loadedChunks[chunkKey] = chunk
    return chunk
end

function InfiniteMap:getTileAtWorldPos(worldX, worldY)
    local chunkX, chunkY = self:getChunkFromWorldPos(worldX, worldY)
    local chunk = self:generateChunk(chunkX, chunkY)
    
    local localX = math.floor((worldX % (self.chunkSize * 32)) / 32)
    local localY = math.floor((worldY % (self.chunkSize * 32)) / 32)
    
    if chunk.tiles[localX] and chunk.tiles[localX][localY] then
        return chunk.tiles[localX][localY]
    end
    return 1  -- Default to wall
end

function InfiniteMap:update(playerX, playerY)
    -- Get player's chunk
    local playerChunkX, playerChunkY = self:getChunkFromWorldPos(playerX, playerY)
    
    -- Load chunks around player
    for x = playerChunkX - self.chunkRadius, playerChunkX + self.chunkRadius do
        for y = playerChunkY - self.chunkRadius, playerChunkY + self.chunkRadius do
            self:generateChunk(x, y)
        end
    end
    
    -- Unload distant chunks to save memory
    for chunkKey, chunk in pairs(self.loadedChunks) do
        local chunkX, chunkY = chunkKey:match("([^,]+),([^,]+)")
        chunkX, chunkY = tonumber(chunkX), tonumber(chunkY)
        
        local distance = math.sqrt((chunkX - playerChunkX)^2 + (chunkY - playerChunkY)^2)
        if distance > self.chunkRadius + 2 then
            self.loadedChunks[chunkKey] = nil
        end
    end
end

function InfiniteMap:rectCollidesWalls(rect)
    local leftTile = math.floor(rect.x / 32)
    local rightTile = math.floor((rect.x + rect.w - 1) / 32)
    local topTile = math.floor(rect.y / 32)
    local bottomTile = math.floor((rect.y + rect.h - 1) / 32)
    
    for x = leftTile, rightTile do
        for y = topTile, bottomTile do
            local worldX = x * 32
            local worldY = y * 32
            if self:getTileAtWorldPos(worldX, worldY) == 1 then
                return true
            end
        end
    end
    return false
end

function InfiniteMap:randomFloorTile(playerX, playerY)
    -- Find a random floor tile near the player
    local attempts = 0
    while attempts < 100 do
        local worldX = playerX + math.random(-200, 200)
        local worldY = playerY + math.random(-200, 200)
        
        if self:getTileAtWorldPos(worldX, worldY) == 0 then
            return math.floor(worldX / 32), math.floor(worldY / 32)
        end
        attempts = attempts + 1
    end
    
    -- Fallback: return player's position
    return math.floor(playerX / 32), math.floor(playerY / 32)
end

function InfiniteMap:render(cameraX, cameraY, cameraZoom, screenW, screenH)
    local TILE = 32
    local COLOR_WALL = {50/255, 50/255, 70/255}
    local COLOR_FLOOR = {22/255, 22/255, 28/255}
    
    -- Draw infinite map tiles
    local visibleLeft = math.floor(cameraX / TILE) - 1
    local visibleRight = math.floor((cameraX + screenW / cameraZoom) / TILE) + 1
    local visibleTop = math.floor(cameraY / TILE) - 1
    local visibleBottom = math.floor((cameraY + screenH / cameraZoom) / TILE) + 1
    
    for y = visibleTop, visibleBottom do
        for x = visibleLeft, visibleRight do
            local worldX = x * TILE
            local worldY = y * TILE
            local tile = self:getTileAtWorldPos(worldX, worldY)
            local color = tile == 1 and COLOR_WALL or COLOR_FLOOR
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle('fill', worldX, worldY, TILE, TILE)
        end
    end
end

return InfiniteMap
