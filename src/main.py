from core.engine import Engine
from game.scene import RogueScene, SCREEN_W, SCREEN_H


def main():
    engine = Engine(width=SCREEN_W, height=SCREEN_H, title="Game_0", target_fps=60)
    engine.push_scene(RogueScene())
    engine.run()


if __name__ == "__main__":
    main()
