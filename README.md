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
- Quit: Esc or close window

## Notes
- Uses colored rectangles for entities/tiles. Replace with sprites later.
- Built with Love2D for better performance and easier deployment.
