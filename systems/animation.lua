-- Animation System for Game_0
-- Handles all animations and visual effects

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

function AnimationSystem.new()
    local self = setmetatable({}, AnimationSystem)
    
    self.animations = {}
    
    return self
end

function AnimationSystem:update(dt)
    -- Update and remove expired animations
    for i = #self.animations, 1, -1 do
        local anim = self.animations[i]
        anim.life = anim.life - dt
        
        if anim.life <= 0 then
            table.remove(self.animations, i)
        else
            -- Update animation properties
            if anim.type == "fireball" then
                anim.x = anim.x + anim.vx * dt
                anim.y = anim.y + anim.vy * dt
            elseif anim.type == "explosion" then
                anim.radius = anim.radius + anim.growth * dt
            end
        end
    end
end

function AnimationSystem:addAnimation(type, x, y, vx, vy, life, color)
    table.insert(self.animations, {
        type = type,
        x = x,
        y = y,
        vx = vx or 0,
        vy = vy or 0,
        life = life,
        color = color or {1, 1, 1},
        radius = 5,
        growth = 50
    })
end

function AnimationSystem:render()
    for _, anim in ipairs(self.animations) do
        love.graphics.setColor(anim.color[1], anim.color[2], anim.color[3], anim.life / 1.0)
        
        if anim.type == "fireball" then
            love.graphics.circle('fill', anim.x, anim.y, 8)
            love.graphics.setColor(1, 0.5, 0, anim.life / 1.0)
            love.graphics.circle('fill', anim.x, anim.y, 5)
        elseif anim.type == "explosion" then
            love.graphics.circle('fill', anim.x, anim.y, anim.radius)
            love.graphics.setColor(1, 0.8, 0, anim.life / 1.0)
            love.graphics.circle('line', anim.x, anim.y, anim.radius)
        elseif anim.type == "lightning" then
            love.graphics.setLineWidth(3)
            love.graphics.line(anim.x, anim.y, anim.x + anim.vx * 20, anim.y + anim.vy * 20)
            love.graphics.setLineWidth(1)
        end
    end
end

return AnimationSystem
