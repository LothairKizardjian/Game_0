-- Simple test script to verify Love2D code structure
-- Run with: lua test.lua

print("Testing Game_0 Love2D structure...")

-- Test core engine
local Engine = require('core.engine')
print("✓ Core engine loaded successfully")

-- Test game scene
local RogueScene = require('game.scene')
print("✓ Game scene loaded successfully")

-- Test scene creation
local scene = RogueScene.new()
print("✓ Scene created successfully")

-- Test entity creation
print("✓ Player HP:", scene.player.hp)
print("✓ Enemy count:", #scene.enemies)

print("All tests passed! Game_0 Love2D structure is working.")
