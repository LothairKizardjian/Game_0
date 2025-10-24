import pygame
from typing import List, Optional, Protocol


class Scene(Protocol):
    def on_enter(self):
        ...

    def on_exit(self):
        ...

    def handle_event(self, event: pygame.event.Event):
        ...

    def update(self, dt: float):
        ...

    def render(self, surface: pygame.Surface):
        ...


class Engine:
    def __init__(self, width: int, height: int, title: str = "Game", target_fps: int = 60):
        pygame.init()
        pygame.display.set_caption(title)
        self.screen = pygame.display.set_mode((width, height))
        self.clock = pygame.time.Clock()
        self.target_fps = target_fps
        self.scenes: List[Scene] = []
        self.running = True

    def push_scene(self, scene: Scene):
        self.scenes.append(scene)
        scene.on_enter()

    def pop_scene(self) -> Optional[Scene]:
        if self.scenes:
            scene = self.scenes.pop()
            scene.on_exit()
            return scene
        return None

    @property
    def current_scene(self) -> Optional[Scene]:
        return self.scenes[-1] if self.scenes else None

    def run(self):
        while self.running:
            dt_ms = self.clock.tick(self.target_fps)
            dt = dt_ms / 1000.0

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                    self.running = False
                if self.current_scene:
                    self.current_scene.handle_event(event)

            if self.current_scene:
                self.current_scene.update(dt)
                self.current_scene.render(self.screen)

            pygame.display.flip()

        pygame.quit()
