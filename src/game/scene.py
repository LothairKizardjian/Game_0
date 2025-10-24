import random
from dataclasses import dataclass
from typing import List, Tuple

import pygame
from core.engine import Scene

TILE = 32
GRID_W, GRID_H = 25, 18
SCREEN_W, SCREEN_H = GRID_W * TILE, GRID_H * TILE

# Colors
COLOR_BG = (12, 12, 16)
COLOR_WALL = (50, 50, 70)
COLOR_FLOOR = (22, 22, 28)
COLOR_PLAYER = (80, 200, 120)
COLOR_ENEMY = (220, 80, 80)
COLOR_UI = (230, 230, 230)

# Map: 0 floor, 1 wall
def generate_map(w: int, h: int) -> List[List[int]]:
    m = [[0 for _ in range(w)] for _ in range(h)]
    # Borders
    for x in range(w):
        m[0][x] = 1
        m[h - 1][x] = 1
    for y in range(h):
        m[y][0] = 1
        m[y][w - 1] = 1
    # Random obstacles
    for _ in range(40):
        rx, ry = random.randint(1, w - 2), random.randint(1, h - 2)
        m[ry][rx] = 1
    return m


def rect_collides_walls(rect: pygame.Rect, tilemap: List[List[int]]) -> bool:
    # Check the tiles overlapped by rect
    tiles_to_check = set()
    for px, py in [rect.topleft, rect.topright, rect.bottomleft, rect.bottomright]:
        tx, ty = px // TILE, py // TILE
        tiles_to_check.add((tx, ty))
    for tx, ty in tiles_to_check:
        if tilemap[ty][tx] == 1:
            return True
    return False


@dataclass
class Entity:
    rect: pygame.Rect
    color: Tuple[int, int, int]
    speed: float
    hp: int
    is_player: bool = False


class RogueScene(Scene):
    def __init__(self):
        self.tilemap = generate_map(GRID_W, GRID_H)
        self.player = Entity(
            rect=pygame.Rect(2 * TILE, 2 * TILE, TILE - 6, TILE - 6),
            color=COLOR_PLAYER,
            speed=150.0,
            hp=5,
            is_player=True,
        )
        self.enemies: List[Entity] = []
        for _ in range(5):
            ex, ey = self._random_floor_tile()
            self.enemies.append(
                Entity(rect=pygame.Rect(ex * TILE + 3, ey * TILE + 3, TILE - 6, TILE - 6), color=COLOR_ENEMY, speed=90.0, hp=1)
            )
        self.move_dir = pygame.Vector2(0, 0)
        self.font = None

    def on_enter(self):
        self.font = pygame.font.SysFont(None, 22)

    def on_exit(self):
        pass

    def handle_event(self, event: pygame.event.Event):
        if event.type == pygame.KEYDOWN or event.type == pygame.KEYUP:
            keys = pygame.key.get_pressed()
            x = (1 if keys[pygame.K_d] or keys[pygame.K_RIGHT] else 0) - (1 if keys[pygame.K_a] or keys[pygame.K_LEFT] else 0)
            y = (1 if keys[pygame.K_s] or keys[pygame.K_DOWN] else 0) - (1 if keys[pygame.K_w] or keys[pygame.K_UP] else 0)
            self.move_dir.update(x, y)
            if self.move_dir.length_squared() > 0:
                self.move_dir = self.move_dir.normalize()

    def update(self, dt: float):
        # Player movement with wall collision
        if self.move_dir.length_squared() > 0:
            self._move_entity(self.player, self.move_dir * self.player.speed * dt)

        # Enemies chase
        for e in self.enemies:
            to_player = pygame.Vector2(self.player.rect.center) - pygame.Vector2(e.rect.center)
            if to_player.length_squared() > 0:
                dir_vec = to_player.normalize()
                self._move_entity(e, dir_vec * e.speed * dt)

        # Combat: on overlap, damage player (simple cooldown-less for now)
        for e in self.enemies:
            if e.rect.colliderect(self.player.rect):
                self.player.hp = max(0, self.player.hp - 1)

        # Remove dead enemies if needed (not used yet)
        self.enemies = [e for e in self.enemies if e.hp > 0]

    def render(self, surface: pygame.Surface):
        surface.fill(COLOR_BG)
        # Draw tiles
        for y in range(GRID_H):
            for x in range(GRID_W):
                tile = self.tilemap[y][x]
                color = COLOR_WALL if tile == 1 else COLOR_FLOOR
                pygame.draw.rect(surface, color, pygame.Rect(x * TILE, y * TILE, TILE, TILE))

        # Draw entities
        pygame.draw.rect(surface, self.player.color, self.player.rect)
        for e in self.enemies:
            pygame.draw.rect(surface, e.color, e.rect)

        # HUD
        if self.font:
            hp_text = self.font.render(f"HP: {self.player.hp}", True, COLOR_UI)
            surface.blit(hp_text, (8, 6))
            tip = self.font.render("Move: WASD/Arrows — ESC to quit", True, COLOR_UI)
            surface.blit(tip, (8, 28))

    # Helpers
    def _move_entity(self, ent: Entity, delta: pygame.Vector2):
        # Move X then Y with collision resolution
        ent.rect.x += int(delta.x)
        if rect_collides_walls(ent.rect, self.tilemap):
            ent.rect.x -= int(delta.x)
        ent.rect.y += int(delta.y)
        if rect_collides_walls(ent.rect, self.tilemap):
            ent.rect.y -= int(delta.y)

    def _random_floor_tile(self) -> Tuple[int, int]:
        while True:
            x, y = random.randint(1, GRID_W - 2), random.randint(1, GRID_H - 2)
            if self.tilemap[y][x] == 0:
                return x, y
