## Why

Tuning how fast a character moves and how fast their sprite animates is core iteration work. Today animation timing lives on `AnimatedEntity`, while movement speed lives on `CharacterEntity`, so the inspector splits related knobs across nodes. Exposing **movement speed** alongside **animation framerate** on `AnimatedEntity` lets artists and designers adjust both from the visual entity in one place.

## What Changes

- Add an **exported movement speed** on `AnimatedEntity` (same semantic units as current character motion, e.g. pixels per second).
- Ensure **animation framerate** remains an exported, editor-visible property on `AnimatedEntity` (naming aligned with project conventions—snake_case in GDScript—with clear meaning in the inspector).
- Wire **`CharacterEntity` / `PlayerEntity`** (and any similar bodies) so horizontal movement uses the speed from the child `AnimatedEntity`, avoiding two unrelated speed fields where the hierarchy is `CharacterBody2D` → `AnimatedEntity`.

## Capabilities

### New Capabilities

- `animated-entity-speed`: Exported **movement speed** and **animation framerate** on `AnimatedEntity`; contract for how parent bodies consume movement speed so motion and animation stay configurable from the sprite node.

### Modified Capabilities

<!-- None: no existing main-spec requirement files change at the delta level; new behavior is additive under a new capability. -->

## Impact

- **Addon scripts**: `animated_entity.gd`, `character_entity.gd`, `player_entity.gd` (and any entity scenes that set speed only on the body).
- **Scenes**: `character_entity.tscn`, `player_entity.tscn`, and related variants may need default speed moved or duplicated on `AnimatedEntity` for a consistent authoring path.
- **Consumers**: Projects that set `CharacterEntity.speed` only on the root may need to set speed on `AnimatedEntity` instead after migration (**BREAKING** if `CharacterEntity.speed` is removed; non-breaking if the body keeps a fallback or sync).
