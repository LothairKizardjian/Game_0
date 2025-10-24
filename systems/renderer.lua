-- Optimized Renderer for Game_0
-- Handles efficient rendering with batching and culling

local Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local self = setmetatable({}, Renderer)

    -- Rendering state
    self.camera = nil
    self.batchOperations = {}
    self.renderCalls = 0
    self.lastRenderCalls = 0

    -- Culling
    self.viewport = {x = 0, y = 0, width = 800, height = 576}
    self.cullingEnabled = true

    return self
end

function Renderer:setCamera(camera)
    self.camera = camera
end

function Renderer:setViewport(x, y, width, height)
    self.viewport = {x = x, y = y, width = width, height = height}
end

function Renderer:isInViewport(x, y, width, height)
    if not self.cullingEnabled then return true end

    local screenX = x - (self.camera and self.camera.x or 0)
    local screenY = y - (self.camera and self.camera.y or 0)

    return screenX + width >= self.viewport.x and
           screenX <= self.viewport.x + self.viewport.width and
           screenY + height >= self.viewport.y and
           screenY <= self.viewport.y + self.viewport.height
end

function Renderer:drawRectangle(mode, x, y, width, height, color)
    if not self:isInViewport(x, y, width, height) then return end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    love.graphics.rectangle(mode, x, y, width, height)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawCircle(mode, x, y, radius, color)
    if not self:isInViewport(x - radius, y - radius, radius * 2, radius * 2) then return end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    love.graphics.circle(mode, x, y, radius)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawLine(x1, y1, x2, y2, color, width)
    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    if width then
        love.graphics.setLineWidth(width)
    end

    love.graphics.line(x1, y1, x2, y2)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawText(text, x, y, color, scale)
    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    if scale then
        love.graphics.print(text, x, y, 0, scale, scale)
    else
        love.graphics.print(text, x, y)
    end

    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawHealthBar(entity, x, y, width, height)
    if not self:isInViewport(x, y, width, height) then return end

    local healthPercent = entity:getHealthPercent()

    -- Background (red)
    love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
    love.graphics.rectangle('fill', x, y, width, height)

    -- Health (green)
    love.graphics.setColor(0.2, 0.8, 0.2, 0.8)
    love.graphics.rectangle('fill', x, y, width * healthPercent, height)

    -- Border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('line', x, y, width, height)

    self.renderCalls = self.renderCalls + 3
end

function Renderer:drawEntity(entity, color)
    if not self:isInViewport(entity.x, entity.y, entity.w, entity.h) then return end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    love.graphics.rectangle('fill', entity.x, entity.y, entity.w, entity.h)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawProjectile(projectile, color)
    if not self:isInViewport(projectile.x - projectile.size, projectile.y - projectile.size,
                            projectile.size * 2, projectile.size * 2) then return end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end

    love.graphics.circle('fill', projectile.x, projectile.y, projectile.size)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:drawDamageNumber(damageNum, color)
    if not self:isInViewport(damageNum.x - 20, damageNum.y - 10, 40, 20) then return end

    if color then
        love.graphics.setColor(color[1], color[2], color[3], damageNum.life)
    end

    love.graphics.print(tostring(damageNum.damage), damageNum.x - 10, damageNum.y, 0, 0.8, 0.8)
    self.renderCalls = self.renderCalls + 1
end

function Renderer:beginBatch()
    self.batchOperations = {}
end

function Renderer:addToBatch(operation)
    table.insert(self.batchOperations, operation)
end

function Renderer:endBatch()
    for _, operation in ipairs(self.batchOperations) do
        if operation.type == "rectangle" then
            self:drawRectangle(operation.mode, operation.x, operation.y,
                              operation.width, operation.height, operation.color)
        elseif operation.type == "circle" then
            self:drawCircle(operation.mode, operation.x, operation.y,
                           operation.radius, operation.color)
        elseif operation.type == "line" then
            self:drawLine(operation.x1, operation.y1, operation.x2, operation.y2,
                         operation.color, operation.width)
        end
    end
    self.batchOperations = {}
end

function Renderer:getRenderStats()
    local stats = {
        renderCalls = self.renderCalls,
        lastRenderCalls = self.lastRenderCalls,
        cullingEnabled = self.cullingEnabled
    }

    self.lastRenderCalls = self.renderCalls
    self.renderCalls = 0

    return stats
end

function Renderer:setCulling(enabled)
    self.cullingEnabled = enabled
end

return Renderer
