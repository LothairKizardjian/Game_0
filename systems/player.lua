-- Player class inheriting from Entity
local Entity = require('systems.entity')

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player.new(x, y, w, h, color, speed, hp)
    local self = Entity.new(x, y, w, h, color, speed, hp, true)
    setmetatable(self, Player)
    
    -- Set player sprite name
    self.spriteName = "player"
    
    return self
end

return Player
