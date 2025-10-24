-- Game State Manager for Game_0
-- Handles game state transitions and management

local GameState = {}
GameState.__index = GameState

-- Game states
local STATES = {
    PLAYING = "playing",
    BONUS_SELECTION = "bonus_selection",
    GAME_OVER = "game_over",
    PAUSED = "paused"
}

function GameState.new()
    local self = setmetatable({}, GameState)
    
    self.currentState = STATES.PLAYING
    self.previousState = nil
    self.stateData = {}
    self.transitions = {}
    
    return self
end

function GameState:setState(newState, data)
    if self.currentState == newState then return end
    
    self.previousState = self.currentState
    self.currentState = newState
    self.stateData = data or {}
    
    -- Call transition callbacks
    if self.transitions[newState] then
        self.transitions[newState](self.previousState, newState, self.stateData)
    end
end

function GameState:getState()
    return self.currentState
end

function GameState:getPreviousState()
    return self.previousState
end

function GameState:getStateData()
    return self.stateData
end

function GameState:isPlaying()
    return self.currentState == STATES.PLAYING
end

function GameState:isBonusSelection()
    return self.currentState == STATES.BONUS_SELECTION
end

function GameState:isGameOver()
    return self.currentState == STATES.GAME_OVER
end

function GameState:isPaused()
    return self.currentState == STATES.PAUSED
end

function GameState:setTransition(state, callback)
    self.transitions[state] = callback
end

function GameState:goToBonusSelection(bonusData)
    self:setState(STATES.BONUS_SELECTION, bonusData)
end

function GameState:goToGameOver(gameOverData)
    self:setState(STATES.GAME_OVER, gameOverData)
end

function GameState:resumePlaying()
    self:setState(STATES.PLAYING)
end

function GameState:pause()
    self:setState(STATES.PAUSED)
end

function GameState:unpause()
    if self.previousState then
        self:setState(self.previousState)
    else
        self:setState(STATES.PLAYING)
    end
end

-- Export states for external use
GameState.STATES = STATES

return GameState
