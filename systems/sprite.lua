-- Sprite System for Game_0
-- Handles directional sprites using PNG images

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

    print("Loading sprite: " .. path)
    local success, sprite = pcall(love.graphics.newImage, path)
    if success then
        print("Successfully loaded: " .. name)
        self.loadedSprites[name] = sprite
        return sprite
    else
        print("Failed to load: " .. path .. " - " .. tostring(sprite))
        return nil
    end
end

function SpriteSystem:createDirectionalSprite(name, basePath)
    local directionalSprite = {
        sprites = {},
        currentDirection = "south",  -- Default direction
        frameWidth = 64,  -- Correct size: 64x64 pixels
        frameHeight = 64,
        frameCount = 4,  -- Assuming 4 frames per direction
        frameDuration = 0.15,  -- Faster animation for walking
        currentFrame = 1,
        frameTime = 0,
        playing = true,
        loop = true
    }

    -- Load sprites for each direction
    local directions = {"north", "east", "south", "west"}
    for _, dir in ipairs(directions) do
        local path = basePath .. "_" .. dir .. ".png"
        local sprite = self:loadSprite(name .. "_" .. dir, path)
        if sprite then
            directionalSprite.sprites[dir] = sprite
        end
    end

    self.sprites[name] = directionalSprite
    return directionalSprite
end

function SpriteSystem:createEnemySprite(name, basePath)
    local enemySprite = {
        sprites = {},
        currentDirection = "south",  -- Default direction
        frameWidth = 64,  -- Correct size: 64x64 pixels
        frameHeight = 64,
        frameCount = 4,  -- Assuming 4 frames per direction
        frameDuration = 0.2,  -- Slightly slower animation for enemies
        currentFrame = 1,
        frameTime = 0,
        playing = true,
        loop = true
    }

    -- Load sprites for each direction
    local directions = {"north", "east", "south", "west"}
    for _, dir in ipairs(directions) do
        local path = basePath .. "_" .. dir .. ".png"
        local sprite = self:loadSprite(name .. "_" .. dir, path)
        if sprite then
            enemySprite.sprites[dir] = sprite
        end
    end

    self.sprites[name] = enemySprite
    return enemySprite
end

function SpriteSystem:update(dt)
    for name, sprite in pairs(self.sprites) do
        if sprite.playing and sprite.frameCount > 1 then
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
    if not sprite then
        print("Sprite not found: " .. name)
        return
    end

    -- Handle fallback sprite (colored rectangle)
    if sprite.isFallback then
        love.graphics.setColor(0.2, 0.6, 1.0)  -- Blue color for player
        love.graphics.rectangle('fill', x - sprite.frameWidth/2, y - sprite.frameHeight/2, sprite.frameWidth, sprite.frameHeight)
        love.graphics.setColor(1, 1, 1)  -- Reset color
        return
    end

    -- Get the sprite for current direction
    local directionSprite = sprite.sprites[sprite.currentDirection]
    if not directionSprite then
        print("No sprite for direction: " .. sprite.currentDirection)
        -- Fallback to colored rectangle
        love.graphics.setColor(0.2, 0.6, 1.0)
        love.graphics.rectangle('fill', x - sprite.frameWidth/2, y - sprite.frameHeight/2, sprite.frameWidth, sprite.frameHeight)
        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Calculate the frame position in the sprite sheet
    local frameX = (sprite.currentFrame - 1) * sprite.frameWidth
    local frameY = 0

    -- Create a quad for the current frame
    local quad = love.graphics.newQuad(
        frameX, frameY,
        sprite.frameWidth, sprite.frameHeight,
        directionSprite:getWidth(), directionSprite:getHeight()
    )

    love.graphics.draw(
        directionSprite,
        quad,
        x, y,
        rotation or 0,
        scale or 1,
        scale or 1,
        sprite.frameWidth / 2,
        sprite.frameHeight / 2
    )

    -- Always reset color to white after drawing sprite
    love.graphics.setColor(1, 1, 1, 1)
end

function SpriteSystem:setDirection(name, direction)
    local sprite = self.sprites[name]
    if not sprite then return end

    -- Map direction vector to direction name using continuous values
    local directionName = "south"  -- Default

    -- Use absolute values to determine dominant direction
    local absX = math.abs(direction.x)
    local absY = math.abs(direction.y)

    if absX > absY then
        -- Horizontal movement is dominant
        if direction.x > 0 then
            directionName = "east"
        else
            directionName = "west"
        end
    else
        -- Vertical movement is dominant
        if direction.y > 0 then
            directionName = "south"
        else
            directionName = "north"
        end
    end

    sprite.currentDirection = directionName
end

function SpriteSystem:setEnemyDirection(name, direction)
    local sprite = self.sprites[name]
    if not sprite then
        return
    end

    -- Map direction vector to direction name using continuous values
    local directionName = "south"  -- Default

    -- Use absolute values to determine dominant direction
    local absX = math.abs(direction.x)
    local absY = math.abs(direction.y)

    if absX > absY then
        -- Horizontal movement is dominant
        if direction.x > 0 then
            directionName = "east"
        else
            directionName = "west"
        end
    else
        -- Vertical movement is dominant
        if direction.y > 0 then
            directionName = "south"
        else
            directionName = "north"
        end
    end

    sprite.currentDirection = directionName
end

function SpriteSystem:createFallbackSprite(name)
    -- Create a simple fallback sprite using colored rectangle
    local fallbackSprite = {
        sprites = {},
        currentDirection = "south",
        frameWidth = 64,  -- Correct size: 64x64 pixels
        frameHeight = 64,
        frameCount = 1,
        frameDuration = 0.2,
        currentFrame = 1,
        frameTime = 0,
        playing = false,
        loop = false,
        isFallback = true
    }

    self.sprites[name] = fallbackSprite
    return fallbackSprite
end

return SpriteSystem