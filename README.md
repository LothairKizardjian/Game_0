# Game_0

A small, modular roguelike foundation using Python + Pygame and simple placeholder graphics. Start small, grow features iteratively.

## Quickstart
```bash
python -m venv .venv
source .venv/bin/activate  # on Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
python -m src.main
```

## Project Structure
- `src/core/engine.py` — engine loop + scenes
- `src/game/scene.py` — main roguelike scene (map, entities, systems)
- `src/main.py` — entrypoint
- `assets/` — placeholder for future art/audio

## Controls
- Move: WASD or Arrow Keys
- Quit: Esc or close window

## Notes
- Uses colored rectangles for entities/tiles. Replace with sprites later.
