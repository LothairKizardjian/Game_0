-- Configuration System for Game_0
-- Centralized game settings and constants

local Config = {}

-- Game Settings
Config.GAME = {
    TITLE = "Game_0",
    VERSION = "1.0.0",
    TARGET_FPS = 60,
    VSYNC = true,
    FULLSCREEN = false
}

-- Window Settings
Config.WINDOW = {
    WIDTH = 800,
    HEIGHT = 576,
    RESIZABLE = false,
    MIN_WIDTH = 640,
    MIN_HEIGHT = 480
}

-- Performance Settings
Config.PERFORMANCE = {
    MAX_ENEMIES = 100,
    MAX_PROJECTILES = 200,
    MAX_ANIMATIONS = 150,
    MAX_DAMAGE_NUMBERS = 50,
    CHUNK_SIZE = 32,
    RENDER_DISTANCE = 10,
    OBJECT_POOL_SIZE = 100
}

-- Gameplay Settings
Config.GAMEPLAY = {
    PLAYER_SPEED = 150,
    PLAYER_SIZE = 20,
    ENEMY_SIZE = 24,
    TILE_SIZE = 32,
    COLLISION_MARGIN = 2
}

-- Rendering Settings
Config.RENDERING = {
    SHOW_FPS = false,
    SHOW_PERFORMANCE = false,
    SHOW_DEBUG_INFO = false,
    VSYNC_ENABLED = true,
    FRAME_LIMIT = 60
}

-- Audio Settings
Config.AUDIO = {
    MASTER_VOLUME = 1.0,
    SFX_VOLUME = 0.8,
    MUSIC_VOLUME = 0.6,
    ENABLED = true
}

-- Input Settings
Config.INPUT = {
    MOUSE_SENSITIVITY = 1.0,
    KEYBOARD_REPEAT_DELAY = 0.5,
    KEYBOARD_REPEAT_RATE = 0.1
}

-- Colors
Config.COLORS = {
    BACKGROUND = {12/255, 12/255, 16/255},
    WALL = {50/255, 50/255, 70/255},
    FLOOR = {22/255, 22/255, 28/255},
    PLAYER = {80/255, 200/255, 120/255},
    ENEMY = {220/255, 80/255, 80/255},
    UI = {230/255, 230/255, 230/255},
    UI_BACKGROUND = {0, 0, 0, 0.7},
    HEALTH_BAR = {0.2, 0.8, 0.2},
    HEALTH_BAR_BG = {0.8, 0.2, 0.2}
}

-- Bonus Rarities
Config.RARITY_COLORS = {
    common = {0.7, 0.7, 0.7},
    rare = {0.2, 0.6, 1.0},
    epic = {0.6, 0.2, 1.0},
    legendary = {1.0, 0.6, 0.0},
    godly = {1.0, 1.0, 1.0}
}

-- Development Settings
Config.DEVELOPMENT = {
    DEBUG_MODE = false,
    SHOW_COLLISION_BOXES = false,
    SHOW_SPAWN_POINTS = false,
    LOG_PERFORMANCE = false,
    ENABLE_PROFILING = false
}

-- Load configuration from file (if exists)
function Config.load()
    -- This could be extended to load from a config file
    -- For now, we use the default values
    return true
end

-- Save configuration to file
function Config.save()
    -- This could be extended to save to a config file
    -- For now, we just return success
    return true
end

-- Get a configuration value with fallback
function Config.get(section, key, defaultValue)
    if Config[section] and Config[section][key] ~= nil then
        return Config[section][key]
    end
    return defaultValue
end

-- Set a configuration value
function Config.set(section, key, value)
    if not Config[section] then
        Config[section] = {}
    end
    Config[section][key] = value
end

-- Initialize configuration
function Config.init()
    Config.load()
    
    -- Set Love2D window properties
    love.window.setTitle(Config.GAME.TITLE)
    love.window.setMode(Config.WINDOW.WIDTH, Config.WINDOW.HEIGHT, {
        resizable = Config.WINDOW.RESIZABLE,
        vsync = Config.GAME.VSYNC
    })
    
    -- Set Love2D graphics properties
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    return true
end

return Config
