-- Sprite System for Game_0
-- Handles animated sprites and sprite management

local SpriteSystem = {}
SpriteSystem.__index = SpriteSystem

function SpriteSystem.new()
    local self = setmetatable({}, SpriteSystem)
    
    self.sprites = {}
    self.loadedSprites = {}
    
    return self
end

function SpriteSystem:loadSprite(name, path)
    if self.loadedSprites[name] then
        return self.loadedSprites[name]
    end
    
    local success, sprite = pcall(love.graphics.newImage, path)
    if success then
        self.loadedSprites[name] = sprite
        return sprite
    else
        print("Failed to load sprite: " .. path)
        return nil
    end
end

function SpriteSystem:createAnimatedSprite(name, sprite, frameWidth, frameHeight, frameCount, frameDuration)
    local animatedSprite = {
        sprite = sprite,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        frameCount = frameCount,
        frameDuration = frameDuration,
        currentFrame = 1,
        frameTime = 0,
        playing = true,
        loop = true
    }
    
    self.sprites[name] = animatedSprite
    return animatedSprite
end

function SpriteSystem:update(dt)
    for name, sprite in pairs(self.sprites) do
        if sprite.playing then
            sprite.frameTime = sprite.frameTime + dt
            
            if sprite.frameTime >= sprite.frameDuration then
                sprite.frameTime = sprite.frameTime - sprite.frameDuration
                sprite.currentFrame = sprite.currentFrame + 1
                
                if sprite.currentFrame > sprite.frameCount then
                    if sprite.loop then
                        sprite.currentFrame = 1
                    else
                        sprite.currentFrame = sprite.frameCount
                        sprite.playing = false
                    end
                end
            end
        end
    end
end

function SpriteSystem:render(name, x, y, rotation, scale)
    local sprite = self.sprites[name]
    if not sprite then return end
    
    local frame = sprite.currentFrame
    local frameX = (frame - 1) * sprite.frameWidth
    local frameY = 0
    
    love.graphics.draw(
        sprite.sprite,
        x, y,
        rotation or 0,
        scale or 1,
        scale or 1,
        sprite.frameWidth / 2,
        sprite.frameHeight / 2
    )
end

function SpriteSystem:setDirection(name, direction)
    local sprite = self.sprites[name]
    if not sprite then return end
    
    -- Map direction to frame
    -- Knight_rotations_8dir.gif has 8 frames for 8 directions
    -- We'll use only 4 main directions (N, E, S, W)
    local frame = 1  -- Default to first frame
    
    if direction.x == 0 and direction.y == -1 then
        frame = 1  -- North
    elseif direction.x == 1 and direction.y == 0 then
        frame = 3  -- East
    elseif direction.x == 0 and direction.y == 1 then
        frame = 5  -- South
    elseif direction.x == -1 and direction.y == 0 then
        frame = 7  -- West
    end
    
    sprite.currentFrame = frame
end

return SpriteSystem
