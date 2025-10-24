# Development Plan for Game_0

Game_0 is a lightweight, modular roguelike foundation using Love2D (Lua) with simple placeholder graphics. The goal is to provide a clean architecture you can grow: input, update, render loops; entities and systems; level generation; basic AI and combat.

## Objectives ✅
- Core engine loop with scenes (state management) ✅
- Minimal ECS-like separation (entities + systems) ✅
- Simple tile map with walls and walkable tiles ✅
- Player movement and collision ✅
- Basic enemy AI (chase player) and collision/combat ✅
- Simple HUD (HP display) ✅
- **NEW**: Camera system with zoom and smooth following ✅
- **NEW**: Camera boundaries at map edges ✅

## Roadmap
- Add procedural dungeon generation (rooms + corridors)
- Ranged and melee attacks, pickups, XP/levels
- Enemy variety and behaviors (patrol, ranged, swarm)
- Particle effects, hit flashes, screenshake
- Sound and music cues
- Save/load runs; meta progression

## Run
- Install: [Love2D](https://love2d.org/) (version 11.0+)
- Start: `love .` or drag folder onto Love2D executable

## Structure
- `main.lua` — Love2D entry point
- `core/engine.lua` — game loop and scene management
- `game/scene.lua` — roguelike scene: map, entities, systems
- `assets/` — sprites/sfx (placeholder for now)

## Recent Updates
- **Large World**: Increased map size from 25x18 to 50x35 tiles
- **Room Generation**: Implemented procedural room-based map generation
- **Corridor System**: Rooms connected with horizontal and vertical corridors
- **Improved Movement**: Smaller player size for easier navigation
- **Enhanced Enemies**: 8-15 enemies for larger world
- **Better HUD**: Shows map size, enemy count, and zoom level
- **Camera System**: Smooth following with zoom controls (0.5x to 4.0x)
- **Camera Boundaries**: Prevents viewing outside map area

## Migration Notes
- Migrated from Python/Pygame to Love2D for better performance
- Lua provides 2-5x faster execution than Python
- Single executable deployment vs Python environment setup
- Better 2D graphics optimization for roguelike games
