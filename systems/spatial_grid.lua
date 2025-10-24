-- Spatial Grid System for Game_0
-- Optimizes collision detection by dividing space into grid cells

local SpatialGrid = {}
SpatialGrid.__index = SpatialGrid

function SpatialGrid.new(cellSize)
    local self = setmetatable({}, SpatialGrid)

    self.cellSize = cellSize or 64
    self.grid = {}
    self.entities = {}

    return self
end

function SpatialGrid:getCellKey(x, y)
    local cellX = math.floor(x / self.cellSize)
    local cellY = math.floor(y / self.cellSize)
    return cellX .. "," .. cellY
end

function SpatialGrid:addEntity(entity)
    if not entity then return end

    local key = self:getCellKey(entity.x, entity.y)

    if not self.grid[key] then
        self.grid[key] = {}
    end

    table.insert(self.grid[key], entity)
    entity._spatialKey = key
    self.entities[entity] = key
end

function SpatialGrid:removeEntity(entity)
    if not entity or not entity._spatialKey then return end

    local key = entity._spatialKey
    if self.grid[key] then
        for i, e in ipairs(self.grid[key]) do
            if e == entity then
                table.remove(self.grid[key], i)
                break
            end
        end
    end

    self.entities[entity] = nil
    entity._spatialKey = nil
end

function SpatialGrid:updateEntity(entity)
    if not entity then return end

    local newKey = self:getCellKey(entity.x, entity.y)

    if entity._spatialKey ~= newKey then
        self:removeEntity(entity)
        self:addEntity(entity)
    end
end

function SpatialGrid:getEntitiesInRadius(centerX, centerY, radius)
    local entities = {}
    local cellRadius = math.ceil(radius / self.cellSize)
    local centerCellX = math.floor(centerX / self.cellSize)
    local centerCellY = math.floor(centerY / self.cellSize)

    for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
            local cellX = centerCellX + dx
            local cellY = centerCellY + dy
            local key = cellX .. "," .. cellY

            if self.grid[key] then
                for _, entity in ipairs(self.grid[key]) do
                    local distance = math.sqrt((entity.x - centerX)^2 + (entity.y - centerY)^2)
                    if distance <= radius then
                        table.insert(entities, entity)
                    end
                end
            end
        end
    end

    return entities
end

function SpatialGrid:getEntitiesInRect(x, y, width, height)
    local entities = {}
    local startCellX = math.floor(x / self.cellSize)
    local startCellY = math.floor(y / self.cellSize)
    local endCellX = math.floor((x + width) / self.cellSize)
    local endCellY = math.floor((y + height) / self.cellSize)

    for cellX = startCellX, endCellX do
        for cellY = startCellY, endCellY do
            local key = cellX .. "," .. cellY

            if self.grid[key] then
                for _, entity in ipairs(self.grid[key]) do
                    if entity.x >= x and entity.x < x + width and
                       entity.y >= y and entity.y < y + height then
                        table.insert(entities, entity)
                    end
                end
            end
        end
    end

    return entities
end

function SpatialGrid:getNearestEntity(centerX, centerY, maxDistance, filterFunc)
    local nearestEntity = nil
    local nearestDistance = maxDistance or math.huge

    local cellRadius = math.ceil(nearestDistance / self.cellSize)
    local centerCellX = math.floor(centerX / self.cellSize)
    local centerCellY = math.floor(centerY / self.cellSize)

    for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
            local cellX = centerCellX + dx
            local cellY = centerCellY + dy
            local key = cellX .. "," .. cellY

            if self.grid[key] then
                for _, entity in ipairs(self.grid[key]) do
                    if not filterFunc or filterFunc(entity) then
                        local distance = math.sqrt((entity.x - centerX)^2 + (entity.y - centerY)^2)
                        if distance < nearestDistance then
                            nearestEntity = entity
                            nearestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return nearestEntity, nearestDistance
end

function SpatialGrid:clear()
    self.grid = {}
    self.entities = {}
end

function SpatialGrid:getStats()
    local totalEntities = 0
    local usedCells = 0

    for _, cell in pairs(self.grid) do
        if #cell > 0 then
            usedCells = usedCells + 1
            totalEntities = totalEntities + #cell
        end
    end

    return {
        totalEntities = totalEntities,
        usedCells = usedCells,
        cellSize = self.cellSize
    }
end

return SpatialGrid
