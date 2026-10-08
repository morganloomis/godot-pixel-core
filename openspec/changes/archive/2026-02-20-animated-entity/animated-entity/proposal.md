# Proposal: Animated Entity

## Why

We need a single, reusable base for any in-world animated sprite that is driven by our sprite-sheet system and can be placed and moved in a scene. Right now animation and sprite lookup are embedded in a player-specific `Character` (CharacterBody2D + input + move_and_slide). Enemies, NPCs, and environmental animations (e.g. fire) would duplicate the same sprite-sheet animation logic. A shared base class lets us implement that once and specialize only movement and behavior in subclasses (player, enemy, NPC, decorative).

## What Changes

- Introduce an **animated-entity base class** that:
  - Uses the existing sprite-sheet addon (e.g. `AnimatedSpriteSheetLookup` / `SpriteSheetLookupBase`) to resolve and display frames.
  - Exposes animation state (e.g. action/state, direction, frame) and drives a visible sprite (e.g. `Sprite2D`) from the sheet.
  - Supports different animation clip behaviors: **looping** (e.g. walk—runs until interrupted), **play once** (e.g. attack—runs to end then notifies), and **hold last frame** (e.g. death—runs to end then stays on the final frame).
  - Can be placed in a scene and moved (position/velocity) by the game or by the node itself, without assuming player input or a specific body type.
- Subclasses or sibling nodes will add:
  - **Player character**: input, `CharacterBody2D`, `move_and_slide`, etc.
  - **Enemies / NPCs**: AI, pathfinding, or scripted movement; possibly `CharacterBody2D` or `RigidBody2D`.
  - **Environmental / decorative** (e.g. fire): no movement or simple local motion; may use the same or a simplified lookup.
- Refactor the current player **Character** to inherit or compose from this base so it no longer owns the core animation/sprite-sheet logic.

## Capabilities

### New Capabilities

- `animated-entity`: A scene node (base class) that uses sprite sheets to display an animated sprite and supports being positioned and moved in the scene. Defines the contract for entity id, action/state, direction, and frame; delegates texture resolution to the sprite-sheet lookup. Supports configurable playback per action (loop, play once, hold last frame). Does not mandate body type (CharacterBody2D vs Node2D vs other); that is left to subclasses or composition.

### Modified Capabilities

- *(None — no existing specs yet.)*

## Impact

- **addons/entity**: New base script (and optionally scene) for the animated entity; existing `characters/character.gd` (and its scene) refactored to use this base.
- **Sprite-sheet addon**: Consumed as-is (`AnimatedSpriteSheetLookup`, `SpriteSheetLookupBase`); no API changes required.
- **Scenes**: Main and test scenes may reference the new base or subclasses; player character becomes a subclass or user of the base.
- **Future**: Enemies, NPCs, and environmental sprites can be implemented by adding new scripts/scenes that extend or compose this base.
