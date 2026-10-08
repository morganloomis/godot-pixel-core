# Proposal: Character Entity

## Why

The animated-entity base covers sprite-sheet display, animation state, and direction for any animated thing—including environmental sprites and props. We need a distinct type for **characters in the game**: entities that are characters (player, NPCs, etc.) rather than decorative or environmental animations. Characters move about the scene and need **collision** to interact with the world; they also need **gameplay attributes** (e.g. health, speed) that we will extend over time. Introducing a character-entity layer gives a single place to own movement/collision and those attributes, and keeps the animated-entity base focused on display and animation only.

## What Changes

- Introduce a **character entity** that:
  - Extends the animated-entity base so it keeps sprite-sheet–driven display, action, and direction without duplicating that logic.
  - Represents a **character** in the game (as opposed to an animated environment sprite or prop).
  - **Moves about the scene** and **provides or requires collision** (e.g. physics body and collision shape) so the character can interact with the world and other colliders.
  - Exposes and tracks **character attributes** such as health, speed, and any others we add later. The design SHALL support adding new attributes over the course of development without breaking existing character types.
- animated-entity can be updated in situations where it makes sense for functionality to live in the parent class, rather than this one.

## Capabilities

### New Capabilities

- `character-entity`: A scene node (script) that extends the animated-entity base and represents a character in the game. It SHALL move about the scene and SHALL provide or require collision (e.g. physics body and collision shape) so the character can interact with the world. It SHALL expose and track character-specific attributes (e.g. health, speed) and SHALL be structured so additional attributes can be added over development. It SHALL NOT reimplement sprite-sheet or frame-advance logic; that remains in the animated-entity base. It SHALL distinguish “character” (moving, collidable entity with attributes) from “animated prop/env” (animated-entity used directly, non-moving).

### Modified Capabilities

- *(None. animated-entity is consumed as-is; no requirement changes.)*

## Impact

- **addons/entity**: New character-entity script (and optional scene) extending `animated_entity.gd`; lives alongside animated_entity and any existing character/player code. Future refactors (e.g. player-character extending character-entity to gain health/speed) may touch `addons/entity/characters` and related scenes.
- **animated-entity**: Consumed only; no API or spec changes.
- **Game design**: Central place for character attributes (health, speed, etc.) as we add more over development.
