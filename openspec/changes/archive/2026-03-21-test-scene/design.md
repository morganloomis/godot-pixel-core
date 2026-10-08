## Context

The addon provides a `PlayerEntity` → `CharacterEntity` → `AnimatedEntity` hierarchy and an `AnimatedSpriteSheetLookup` that resolves sprite regions by `{animated_sheet_root}/{entity}/{action}.png`. Currently nothing in the repo exercises this pipeline end-to-end. The only available animated sprite is `test/art/sprite/girl/girl_walk.png` (a 12-column, 16-row sheet with 8-direction diffuse block + 8-direction normal block).

`AnimatedEntity._ready()` creates a default `AnimatedSpriteSheetLookup` with `animated_sheet_root = "res://sprite/animated/"`. Test assets live under `res://test/art/sprite/`, so the root must be overridden at runtime.

## Goals / Non-Goals

**Goals:**

- A launchable test scene that renders the girl entity with walk animation driven by player input.
- Demonstrate correct addon wiring: `PlayerEntity` drives `AnimatedEntity` via `set_action()` / `direction`, lookup resolves the sheet and returns atlas regions.
- Keep test code minimal and separate from addon code (no changes to `addons/godot-pixel-core/`).

**Non-Goals:**

- ~~No idle sprite sheet~~ — an idle sheet (`idle.png`) will be provided alongside `walk.png`, same layout (diffuse/normal blocks, 8 directions).
- No normal-map lighting — the sheet has a normal block but the test scene won't set up a light to use it. Can be added in a future change.
- No tile map — use a simple `ColorRect` ground plane rather than setting up tile sources. Keeps the scene file minimal.
- No collision geometry beyond the player capsule — no walls or boundaries.

## Decisions

### 1. Scene root script for lookup configuration

**Choice:** A small `test_scene.gd` script on the scene root node configures the lookup path after the tree is ready.

```
TestScene (Node2D) — test_scene.gd
└── PlayerEntity (instance of player_entity.tscn)
    ├── AnimatedEntity
    └── CollisionShape2D
└── Ground (ColorRect)
└── Camera2D
```

In `_ready()`, the root script accesses `$PlayerEntity/AnimatedEntity.sprite_lookup.animated_sheet_root` and sets it to `"res://test/art/sprite/"`. This works because Godot calls child `_ready()` before parent `_ready()` — by the time the root's `_ready()` fires, AnimatedEntity has already created its lookup instance.

**Why not a test-specific PlayerEntity subclass?** Overriding the entity script would diverge from how consumers actually use the addon. A scene-root configuration script is closer to real usage: instantiate the addon scene, configure exported properties and lookup paths from the outside.

### 2. Asset rename to match convention

**Choice:** Rename `girl_walk.png` → `walk.png` so the path becomes `test/art/sprite/girl/walk.png`, matching `{root}/girl/walk.png`.

**Alternative considered:** Adding a path-template override to the lookup to support arbitrary file naming. Rejected — overengineering for a test asset; the convention exists for a reason.

### 3. Entity ID via export property

**Choice:** Set `entity_id = "girl"` on the AnimatedEntity child node in the scene file (it's an `@export var`). No code needed for this.

### 4. Camera as child of scene root

**Choice:** A `Camera2D` as a child of the scene root, positioned at the player's start location (or centered on the viewport). Not parented to the player — the player should stay roughly centered in a small test area, and a fixed camera keeps things simple.

**Alternative considered:** Camera2D as a child of PlayerEntity to follow the player. Would work but adds movement to the viewport which isn't needed for a basic walk-animation test.

### 5. Idle sprite sheet

An `idle.png` sheet will be provided at `test/art/sprite/girl/idle.png`, following the same animated layout convention (diffuse/normal blocks, 8 directions, N columns of frames). When the player stops moving, `PlayerEntity` sets `action = "idle"` and the lookup resolves `{root}/girl/idle.png` — no special handling needed.

### 6. Ground plane with ColorRect

A `ColorRect` sized to fill the visible area provides a simple neutral ground. No tile setup, no TileSet resource, no tile-source configuration. The paver tile exists in `test/art/tile/` but isn't worth the scene complexity for this change.

## Risks / Trade-offs

- **First-frame flicker** → AnimatedEntity calls `update_sprite()` in its own `_ready()` before the root script can configure the path. The sprite will be blank for one frame. Mitigation: negligible visual impact; the timer fires at 12fps so the correct frame appears within ~83ms.
- **Idle sheet dependency** → The test scene requires both `walk.png` and `idle.png` to be present. If `idle.png` is missing, the sprite holds the last walk frame (graceful degradation via the `tex.atlas != null` check in `update_sprite`).
- **Fixed camera** → If the player walks far enough, they leave the viewport. Mitigation: acceptable for a test scene; the player starts centered and the test is about verifying animation, not exploring a world.
