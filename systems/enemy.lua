-- Enemy class inheriting from Entity
local Entity = require('systems.entity')

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, {__index = Entity})

function Enemy.new(x, y, w, h, color, speed, hp, scalingFactor)
    local self = Entity.new(x, y, w, h, color, speed, hp, false)
    setmetatable(self, Enemy)
    
    -- Enemy-specific properties
    self.scalingFactor = scalingFactor or 1.0
    self.attackPower = 1 * scalingFactor
    self.attackCooldown = 1.0
    self.lastAttackTime = 0
    
    -- Generate unique sprite name for each enemy
    self.spriteName = "enemy_" .. tostring(self):sub(-8)  -- Use object address as unique ID
    
    return self
end

return Enemy
