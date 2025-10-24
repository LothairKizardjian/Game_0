-- Object Pool System for Game_0
-- Reduces garbage collection by reusing objects

local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new(objectType, initialSize)
    local self = setmetatable({}, ObjectPool)
    
    self.objectType = objectType
    self.pool = {}
    self.activeObjects = {}
    self.initialSize = initialSize or 50
    
    -- Initialize pool with objects
    for i = 1, self.initialSize do
        table.insert(self.pool, self:createObject())
    end
    
    return self
end

function ObjectPool:createObject()
    if self.objectType == "projectile" then
        return {
            x = 0, y = 0, vx = 0, vy = 0,
            type = "", damage = 0, life = 0,
            size = 8, piercing = false,
            active = false
        }
    elseif self.objectType == "damage_number" then
        return {
            x = 0, y = 0, damage = 0, life = 0,
            active = false
        }
    elseif self.objectType == "animation" then
        return {
            type = "", x = 0, y = 0, vx = 0, vy = 0,
            life = 0, color = {1, 1, 1}, radius = 5,
            growth = 50, rotation = 0, alpha = 1.0,
            active = false
        }
    end
    return {}
end

function ObjectPool:get()
    local obj = table.remove(self.pool)
    if not obj then
        -- Pool is empty, create new object
        obj = self:createObject()
    end
    obj.active = true
    table.insert(self.activeObjects, obj)
    return obj
end

function ObjectPool:release(obj)
    if not obj then return end
    
    obj.active = false
    -- Reset object properties
    if self.objectType == "projectile" then
        obj.x, obj.y, obj.vx, obj.vy = 0, 0, 0, 0
        obj.type, obj.damage, obj.life = "", 0, 0
        obj.size, obj.piercing = 8, false
    elseif self.objectType == "damage_number" then
        obj.x, obj.y, obj.damage, obj.life = 0, 0, 0, 0
    elseif self.objectType == "animation" then
        obj.type, obj.x, obj.y, obj.vx, obj.vy = "", 0, 0, 0, 0
        obj.life, obj.radius, obj.growth = 0, 5, 50
        obj.rotation, obj.alpha = 0, 1.0
        obj.color = {1, 1, 1}
    end
    
    -- Remove from active objects
    for i, activeObj in ipairs(self.activeObjects) do
        if activeObj == obj then
            table.remove(self.activeObjects, i)
            break
        end
    end
    
    table.insert(self.pool, obj)
end

function ObjectPool:update(dt, updateFunc)
    for i = #self.activeObjects, 1, -1 do
        local obj = self.activeObjects[i]
        if updateFunc then
            updateFunc(obj, dt)
        end
        if not obj.active or (obj.life and obj.life <= 0) then
            self:release(obj)
        end
    end
end

function ObjectPool:render(renderFunc)
    for _, obj in ipairs(self.activeObjects) do
        if obj.active and renderFunc then
            renderFunc(obj)
        end
    end
end

function ObjectPool:getActiveCount()
    return #self.activeObjects
end

function ObjectPool:getPoolSize()
    return #self.pool
end

function ObjectPool:clear()
    -- Release all active objects
    for i = #self.activeObjects, 1, -1 do
        self:release(self.activeObjects[i])
    end
end

return ObjectPool
