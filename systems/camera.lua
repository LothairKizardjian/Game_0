-- Camera System for Game_0
-- Handles camera following, zoom, and transformations

local Camera = {}
Camera.__index = Camera

function Camera.new()
    local self = setmetatable({}, Camera)

    self.x = 0
    self.y = 0
    self.targetX = 0
    self.targetY = 0
    self.zoom = 2.0
    self.smooth = 5.0

    return self
end

function Camera:update(dt, playerX, playerY, playerW, playerH)
    -- Calculate camera target to follow player
    local playerCenterX = playerX + playerW / 2
    local playerCenterY = playerY + playerH / 2

    -- Calculate screen center in world coordinates
    local screenW, screenH = love.graphics.getDimensions()
    local screenCenterX = screenW / (2 * self.zoom)
    local screenCenterY = screenH / (2 * self.zoom)

    -- Set target camera position
    self.targetX = playerCenterX - screenCenterX
    self.targetY = playerCenterY - screenCenterY

    -- No boundaries for infinite map - camera can move freely

    -- Smooth camera movement
    local lerpFactor = self.smooth * dt
    self.x = self.x + (self.targetX - self.x) * lerpFactor
    self.y = self.y + (self.targetY - self.y) * lerpFactor
end

function Camera:apply()
    love.graphics.push()
    love.graphics.scale(self.zoom, self.zoom)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:reset()
    love.graphics.pop()
end

function Camera:zoomIn()
    self.zoom = math.min(self.zoom + 0.5, 4.0)
end

function Camera:zoomOut()
    self.zoom = math.max(self.zoom - 0.5, 0.5)
end

function Camera:resetZoom()
    self.zoom = 2.0
end

return Camera
