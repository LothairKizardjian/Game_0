# Agent Plan for Game_0

Game_0 is a lightweight, modular roguelike foundation using Python and Pygame with simple placeholder graphics. The goal is to provide a clean architecture you can grow: input, update, render loops; entities and systems; level generation; basic AI and combat.

## Objectives
- Core engine loop with scenes (state management)
- Minimal ECS-like separation (entities + systems)
- Simple tile map with walls and walkable tiles
- Player movement and collision
- Basic enemy AI (chase player) and collision/combat
- Simple HUD (HP display)

## Roadmap
- Add procedural dungeon generation (rooms + corridors)
- Ranged and melee attacks, pickups, XP/levels
- Enemy variety and behaviors (patrol, ranged, swarm)
- Particle effects, hit flashes, screenshake
- Sound and music cues
- Save/load runs; meta progression

## Run
- Install: `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
- Start: `python -m src.main`

## Structure
- `src/core/engine.py` — game loop and scene management
- `src/game/scene.py` — roguelike scene: map, entities, systems
- `src/main.py` — entrypoint
- `assets/` — sprites/sfx (placeholder for now)
