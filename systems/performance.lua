-- Performance Monitoring System for Game_0
-- Tracks FPS, memory usage, and performance metrics

local Performance = {}
Performance.__index = Performance

function Performance.new()
    local self = setmetatable({}, Performance)

    -- Performance metrics
    self.fps = 0
    self.frameTime = 0
    self.frameCount = 0
    self.lastFpsUpdate = 0
    self.fpsHistory = {}
    self.maxFpsHistory = 60  -- Keep last 60 frames

    -- Memory tracking
    self.memoryUsage = 0
    self.gcCount = 0
    self.lastGcCount = 0

    -- Performance warnings
    self.lowFpsThreshold = 30
    self.highFrameTimeThreshold = 0.033  -- ~30 FPS
    self.warnings = {}

    -- Delta time smoothing
    self.deltaTimeHistory = {}
    self.maxDeltaHistory = 10
    self.smoothedDeltaTime = 0

    return self
end

function Performance:update(dt)
    -- Update frame time
    self.frameTime = dt
    self.frameCount = self.frameCount + 1

    -- Calculate FPS
    self.lastFpsUpdate = self.lastFpsUpdate + dt
    if self.lastFpsUpdate >= 1.0 then
        self.fps = self.frameCount
        self.frameCount = 0
        self.lastFpsUpdate = 0

        -- Add to history
        table.insert(self.fpsHistory, self.fps)
        if #self.fpsHistory > self.maxFpsHistory then
            table.remove(self.fpsHistory, 1)
        end
    end

    -- Smooth delta time
    table.insert(self.deltaTimeHistory, dt)
    if #self.deltaTimeHistory > self.maxDeltaHistory then
        table.remove(self.deltaTimeHistory, 1)
    end

    local totalDelta = 0
    for _, delta in ipairs(self.deltaTimeHistory) do
        totalDelta = totalDelta + delta
    end
    self.smoothedDeltaTime = totalDelta / #self.deltaTimeHistory

    -- Update memory usage
    self.memoryUsage = collectgarbage("count")
    self.gcCount = collectgarbage("count")

    -- Check for performance issues
    self:checkPerformanceIssues()
end

function Performance:checkPerformanceIssues()
    self.warnings = {}

    -- Low FPS warning
    if self.fps > 0 and self.fps < self.lowFpsThreshold then
        table.insert(self.warnings, "Low FPS: " .. self.fps)
    end

    -- High frame time warning
    if self.frameTime > self.highFrameTimeThreshold then
        table.insert(self.warnings, "High frame time: " .. string.format("%.3f", self.frameTime))
    end

    -- Memory usage warning
    if self.memoryUsage > 50 * 1024 then  -- 50MB
        table.insert(self.warnings, "High memory usage: " .. string.format("%.1f", self.memoryUsage / 1024) .. "MB")
    end
end

function Performance:getSmoothedDeltaTime()
    return self.smoothedDeltaTime
end

function Performance:getAverageFps()
    if #self.fpsHistory == 0 then return 0 end

    local total = 0
    for _, fps in ipairs(self.fpsHistory) do
        total = total + fps
    end
    return total / #self.fpsHistory
end

function Performance:render(x, y)
    if not x then x, y = 10, 10 end

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("FPS: " .. self.fps, x, y)
    love.graphics.print("Frame Time: " .. string.format("%.3f", self.frameTime * 1000) .. "ms", x, y + 20)
    love.graphics.print("Memory: " .. string.format("%.1f", self.memoryUsage / 1024) .. "MB", x, y + 40)
    love.graphics.print("Avg FPS: " .. string.format("%.1f", self:getAverageFps()), x, y + 60)

    -- Show warnings
    if #self.warnings > 0 then
        love.graphics.setColor(1, 0.2, 0.2, 0.8)
        for i, warning in ipairs(self.warnings) do
            love.graphics.print("WARNING: " .. warning, x, y + 80 + (i - 1) * 20)
        end
    end
end

function Performance:forceGarbageCollection()
    collectgarbage("collect")
end

function Performance:getMetrics()
    return {
        fps = self.fps,
        frameTime = self.frameTime,
        memoryUsage = self.memoryUsage,
        averageFps = self:getAverageFps(),
        warnings = self.warnings,
        smoothedDeltaTime = self.smoothedDeltaTime
    }
end

return Performance
