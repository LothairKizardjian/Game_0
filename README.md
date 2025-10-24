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
- Move: WASD or Arrow Keys
- Zoom In: + or = key
- Zoom Out: - key
- Reset Zoom: 0 key
- Quit: Esc or close window

## Features
- **Large Procedural World**: 50x35 tile map with room-based generation
- **Camera System**: Smooth camera following with zoom (0.5x to 4.0x)
- **Player Movement**: WASD/Arrow key controls with collision detection
- **Combat System**: Enemies deal damage with cooldown system (1s player, 0.5s enemies)
- **Health System**: Player (10 HP) and enemies (3 HP) with visual health bars
- **Dynamic HUD**: Health display, zoom level, map size, and enemy count
- **Room Generation**: Procedural rooms connected by corridors
- **Visual Feedback**: Color-coded health bars (green/yellow/red)
- **Improved Movement**: Smaller player for easier navigation

## Notes
- Uses colored rectangles for entities/tiles. Replace with sprites later.
- Built with Love2D for better performance and easier deployment.
- Camera boundaries prevent viewing outside the map area.
