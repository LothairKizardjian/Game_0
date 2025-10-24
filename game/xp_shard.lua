-- XP Shard System for Game_0
-- Handles experience shards that drop from enemies

local XPShard = {}
XPShard.__index = XPShard

-- Colors for XP shards
local XP_COLOR = {0.2, 0.8, 1.0}  -- Bright blue
local XP_GLOW_COLOR = {0.4, 0.9, 1.0}  -- Lighter blue for glow

function XPShard.new(x, y, xpValue)
    local self = setmetatable({}, XPShard)
    self.x = x
    self.y = y
    self.xpValue = xpValue or 1
    self.size = 4
    self.collected = false
    self.attractionRadius = 0
    self.attractionSpeed = 0
    self.angle = math.random() * math.pi * 2
    self.rotation = 0
    return self
end

function XPShard:update(dt, playerX, playerY, collectRadius, attractionSpeed)
    if self.collected then return end

    local dx = playerX - self.x
    local dy = playerY - self.y
    local distance = math.sqrt(dx*dx + dy*dy)

    -- Check if within collect radius
    if distance <= collectRadius then
        -- Move towards player
        local moveSpeed = attractionSpeed * dt
        local moveX = (dx / distance) * moveSpeed
        local moveY = (dy / distance) * moveSpeed

        self.x = self.x + moveX
        self.y = self.y + moveY

        -- Check if reached player
        if distance <= 8 then
            self.collected = true
            return true  -- Signal that shard was collected
        end
    end

    -- Rotate the shard for visual effect
    self.rotation = self.rotation + dt * 3

    return false
end

function XPShard:render()
    if self.collected then return end

    -- Glow effect
    love.graphics.setColor(XP_GLOW_COLOR[1], XP_GLOW_COLOR[2], XP_GLOW_COLOR[3], 0.3)
    love.graphics.circle('fill', self.x, self.y, self.size + 2)

    -- Main shard
    love.graphics.setColor(XP_COLOR[1], XP_COLOR[2], XP_COLOR[3])
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.rectangle('fill', -self.size/2, -self.size/2, self.size, self.size)
    love.graphics.pop()

    -- Sparkle effect
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle('fill', self.x + math.cos(self.rotation) * 3, self.y + math.sin(self.rotation) * 3, 1)
end

-- XP Shard Manager
local XPShardManager = {}
XPShardManager.__index = XPShardManager

function XPShardManager.new()
    local self = setmetatable({}, XPShardManager)
    self.shards = {}
    return self
end

function XPShardManager:addShard(x, y, xpValue)
    table.insert(self.shards, XPShard.new(x, y, xpValue))
end

function XPShardManager:update(dt, playerX, playerY, collectRadius, attractionSpeed)
    local collectedXP = 0

    for i = #self.shards, 1, -1 do
        local shard = self.shards[i]
        if shard:update(dt, playerX, playerY, collectRadius, attractionSpeed) then
            collectedXP = collectedXP + shard.xpValue
            table.remove(self.shards, i)
        end
    end

    return collectedXP
end

function XPShardManager:render()
    for _, shard in ipairs(self.shards) do
        shard:render()
    end
end

function XPShardManager:getShardCount()
    return #self.shards
end

return {
    XPShard = XPShard,
    XPShardManager = XPShardManager
}
