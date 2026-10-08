# Proposal: Player Entity

## Why

We have a character-entity base that provides a moving, collidable character with attributes (health, speed) and display via AnimatedEntity. We need a **player entity**: the same character type but driven by **player input** so the player can move the character in the world. This fills the playable-character role by extending CharacterEntity and adding input handling.

## What Changes

- Introduce a **player entity** that:
  - Extends the character-entity base so it inherits body, collision, attributes (health, speed), and the child AnimatedEntity for display.
  - Reads **player input** (e.g. movement axes: `ui_left`, `ui_right`, `ui_up`, `ui_down` or project-defined actions) and sets velocity, then calls `move_and_slide()` so the character moves.
  - Updates the child AnimatedEntity’s **action** (idle vs walk) and **direction** (facing) from input so the sprite reflects movement state.
- Player entity is the type used for the playable character in the game; it SHALL NOT reimplement character attributes or display logic—that remains in CharacterEntity and AnimatedEntity.

## Capabilities

### New Capabilities

- `player-entity`: A scene node (script) that extends the character-entity base and adds player input handling. It SHALL read movement input from the engine or project input map, SHALL set velocity from that input using the inherited `speed` (or equivalent), SHALL call `move_and_slide()`, and SHALL update the child AnimatedEntity’s action and direction (idle/walk, facing). It SHALL NOT reimplement sprite-sheet, frame-advance, or character-attribute logic; that remains in animated-entity and character-entity.

### Modified Capabilities

- *(None. character-entity and animated-entity are consumed as-is.)*

## Impact

- **addons/entity/characters** (or addons/entity): New player_entity script and scene extending CharacterEntity; may replace or sit alongside existing player/character scripts and scenes.
- **Input map**: Uses movement actions (e.g. `ui_left`, `ui_right`, `ui_up`, `ui_down`); no change unless new actions are added.
- **Main / test scenes**: Playable character can use the new player-entity scene.
