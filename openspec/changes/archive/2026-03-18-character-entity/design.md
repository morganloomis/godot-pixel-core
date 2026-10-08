# Design: Character Entity

## Context

The animated-entity base is implemented as a `Node2D` (`AnimatedEntity`) with sprite-sheet display, action/direction/frame, and timer-based advance. It is used for both environmental/prop animations (non-moving) and as the display layer for characters. Characters in the game need to **move** and have **collision**, and need **gameplay attributes** (health, speed, etc.) that we will extend over time. Because the base is `Node2D` and characters require a physics body for movement and collision, we use **composition**: the character-entity has a `CharacterBody2D` root with a child `AnimatedEntity` instance and a collision shape. The character-entity script owns the body, collision, and attributes; it does not reimplement animation logic.

## Goals / Non-Goals

**Goals:**

- Provide a character-entity type that represents a **character** in the game (moving, collidable) as distinct from an animated prop or environment sprite.
- Use the animated-entity base for all display and animation (action, direction, frame); no duplication of sprite-sheet or frame logic.
- Provide or require **collision** (physics body + collision shape) so the character can interact with the world and other colliders.
- Expose and track **character attributes** (e.g. health, speed) and structure the implementation so additional attributes can be added over development without breaking existing character types.
- Leave movement *logic* (e.g. who sets velocity, when) to subclasses or external code so that player-character, NPCs, and other character types can extend or use this entity.

**Non-Goals:**

- Changing the animated-entity API or spec.
- Implementing input handling or specific movement logic in the character-entity base (that belongs in player-character or NPC scripts).
- Implementing combat, AI, or other gameplay systems beyond owning the attributes (health, speed, etc.).

## Decisions

### 1. Composition with CharacterBody2D root

**Choice:** Character entity is a **CharacterBody2D** root node with a **child** instance of the animated-entity scene (or a node with the `AnimatedEntity` script) and a **CollisionShape2D** child. The character-entity script on the root extends `CharacterBody2D`; it holds a reference to the child `AnimatedEntity` and does not extend `AnimatedEntity`.

**Rationale:** The animated-entity base is `Node2D`; we need `CharacterBody2D` for physics, collision, and `move_and_slide()`. GDScript single inheritance prevents extending both. Composition keeps the base unchanged and lets the character-entity own the body, collision, and attributes while delegating all sprite/frame logic to the child.

**Alternatives considered:** (1) Change animated-entity to extend `CharacterBody2D` — rejected because the base must stay body-agnostic for decorative entities. (2) Use a different body type (e.g. `RigidBody2D`) — rejected for now; `CharacterBody2D` is the standard for character movement; we can revisit for specific character types later.

### 2. Scene layout and references

**Choice:** Scene root: `CharacterBody2D` with script `character_entity.gd` (or equivalent). Children: (1) An instance of `animated_entity.tscn` (e.g. named `AnimatedEntity` or `Sprite`), (2) A `CollisionShape2D` (shape and layer/mask configured in the scene or by subclass). The character script uses `@onready var animated_entity: AnimatedEntity = $AnimatedEntity` (or the actual child name) to drive action/direction. The animated-entity child stays at local position (0, 0) so it follows the body.

**Rationale:** Same pattern as player-character design: body moves, children follow. Explicit child for display and for collision keeps the contract clear. Collision shape is a sibling of the animated entity so both are under the same body.

**Alternatives considered:** Collision as a separate node tree — not needed; a single body with one shape (or more if a subclass adds them) is sufficient.

### 3. Character attributes (health, speed, extensibility)

**Choice:** Expose character attributes as **exported variables** on the character-entity script (e.g. `@export var health: float = 100.0`, `@export var max_health: float = 100.0`, `@export var speed: float = 200.0`). New attributes are added over time as additional `@export` vars or, if the set grows large, via a dedicated Resource (e.g. `CharacterStats`) assigned to the entity. For this change, start with a small set (health, max_health, speed) and document that more can be added in the same way.

**Rationale:** Exports are simple, inspector-friendly, and easy to extend. A Resource can be introduced later if we need to share stat sets or avoid script bloat. No need to over-engineer before we have more attributes.

**Alternatives considered:** (1) All attributes in a Resource from day one — rejected; YAGNI. (2) Dictionary or generic “stats” — rejected for first version; explicit vars are clearer and type-safe.

### 4. Movement responsibility

**Choice:** The character-entity base **does not** set velocity or call `move_and_slide()` by default. It provides the body and collision; subclasses (e.g. player-character, NPC) or external code are responsible for setting `velocity` and calling `move_and_slide()` in `_physics_process`. The base may expose `speed` (and other attributes) so subclasses can use them (e.g. `velocity = direction * speed`).

**Rationale:** Movement logic differs per character type (player input vs AI vs scripted). Keeping it out of the base keeps character-entity focused on “what a character is” (body, collision, attributes, display) rather than “how it moves.”

**Alternatives considered:** Default kinematic movement in base — rejected; would force overrides for almost every use case.

### 5. Placement of script and scene

**Choice:** Add the character-entity script and scene under `addons/entity/` (e.g. `character_entity.gd`, `character_entity.tscn`) alongside `animated_entity.gd` and `animated_entity.tscn`. The `addons/entity/characters/` folder continues to hold character *types* that use or extend the character entity (e.g. player-character, NPCs).

**Rationale:** Character-entity is a core entity type like animated-entity; keeping it in `addons/entity/` makes the hierarchy clear. Character *variants* (player, NPC) live under `characters/`.

**Alternatives considered:** Put character-entity under `characters/` — possible, but then “character” is mixed with “player” and other variants; separating base entity from character types is clearer.

## Risks / Trade-offs

- **Collision layers and masks:** Character-entity scenes need correct collision layer/mask for the game. **Mitigation:** Document that layers and mask are set per scene or subclass; no default that assumes a specific game layout.
- **Attribute naming and types:** Early attributes (health, speed) might need to align with future systems (e.g. damage, UI). **Mitigation:** Use common names and float where sensible; refactor into a Resource if we need a single source of truth later.
- **Player-character refactor:** Current player-character design composes CharacterBody2D + AnimatedEntity directly. After character-entity exists, player-character could extend CharacterEntity to gain health, speed, and shared collision setup. **Mitigation:** Treat that as a follow-up refactor; this change only adds character-entity; player-character can adopt it when convenient.

## Migration Plan

1. Add `character_entity.gd` under `addons/entity/` extending `CharacterBody2D`, with exports for health, max_health, speed (and any other initial attributes), and `@onready` reference to child `AnimatedEntity`.
2. Create `character_entity.tscn`: root `CharacterBody2D` with character_entity script, child `AnimatedEntity` (instance of `animated_entity.tscn`), child `CollisionShape2D` (shape to be configured; placeholder shape acceptable for first version).
3. No mandatory change to existing player-character or character scenes in this change; they can later be refactored to extend or use character_entity.
4. Rollback: remove new script and scene if needed.

## Open Questions

- Whether to add signals for attribute changes (e.g. `health_changed`) in this change or when we first need them (e.g. UI or damage). Recommendation: add when a consumer exists.
- Final class name: `CharacterEntity` vs `Character`; recommendation: `CharacterEntity` to avoid clashing with existing `character.gd` and to align with `AnimatedEntity` naming.
