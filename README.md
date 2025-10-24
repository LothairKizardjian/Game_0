# Game_0

A small, modular roguelike foundation using Love2D (Lua) with simple placeholder graphics. Start small, grow features iteratively.

## Quickstart
1. Install [Love2D](https://love2d.org/) (version 11.0+)
2. Run the game:
   ```bash
   love .
   ```
   Or drag the Game_0 folder onto the Love2D executable

## Project Structure
- `main.lua` — Love2D entry point
- `core/engine.lua` — engine loop + scene management
- `game/scene.lua` — main roguelike scene (map, entities, systems)
- `assets/` — placeholder for future art/audio

## Controls
- **Movement**: WASD or Arrow Keys
- **Auto-Attack**: SPACEBAR (cone-shaped damage in front of player)
- **Zoom**: +/= to zoom in, - to zoom out, 0 to reset
- **Bonus Selection**: Click bonuses or press 1, 2, or 3
- **Game Over**: Click buttons or use ENTER/SPACE
- **Quit**: Esc or close window

## Bonus System
- **5 Rarity Tiers**: Common (gray) → Rare (blue) → Epic (purple) → Legendary (gold) → Godly (red)
- **20+ Unique Effects**: From simple stat boosts to game-changing abilities
- **Selection**: Choose 1 of 3 random bonuses at game start and each level up
- **Creative Effects**: Health regen, XP rain, god mode, time slow, teleportation, and more!

## Features
- **🎮 Complete Roguelike Experience**: Game over screen, restart functionality, and progression
- **⚔️ Auto-Attack System**: SPACEBAR cone-shaped attack with visual feedback and cooldown
- **📈 Leveling System**: Player levels up with XP from enemy kills, exponential progression
- **🎁 Bonus System**: 20+ unique bonuses across 5 rarity tiers (Common to Godly)
- **💎 XP Shards**: Visual experience drops that move toward player with collect radius
- **🖱️ Mouse Controls**: Click to select bonuses and game over buttons
- **⚔️ Enhanced Combat**: Damage reduction, thorns, life steal, explosive death effects
- **🌟 Creative Bonuses**: Health regen, XP rain, god mode, time slow, teleportation
- **🎯 Visual Polish**: Glowing XP shards, attack cones, collect radius, bonus tracking
- **🏗️ Large Procedural World**: 50x35 tile map with room-based generation
- **📷 Camera System**: Smooth following with zoom (0.5x to 4.0x) and boundaries
- **🎨 Dynamic HUD**: Level, XP, attack cooldown, bonuses, health, and comprehensive stats

## Notes
- Uses colored rectangles for entities/tiles. Replace with sprites later.
- Built with Love2D for better performance and easier deployment.
- Camera boundaries prevent viewing outside the map area.
