# Design: Animated Entity

## Context

The project has a sprite-sheet addon (`SpriteSheetLookupBase`, `AnimatedSpriteSheetLookup`) that loads sheet textures, computes atlas regions by entity/action/direction/frame, and returns `AtlasTexture`. There is a prototype player script (`character.gd`) that we can use as reference for how lookup, timer, and sprite update work—but we are not designing to keep that script working as-is. The player character will be rewritten in a follow-up change after this base exists. This change defines a reusable base that owns only sprite-sheet–driven animation and scene placement, so enemies, NPCs, and environmental sprites (e.g. fire) can share the same animation logic while subclasses choose body type and movement.

## Goals / Non-Goals

**Goals:**

- Provide one base class that uses the sprite-sheet addon to display an animated sprite and advance frames over time.
- Expose animation state (entity id, action/state, direction, frame) and frame rate so subclasses and the engine can drive or read them.
- Default to 12 fps but there should be an option to override.
- Be placeable and movable in the scene (position; movement/velocity is the responsibility of the node or parent, not mandated by the base).
- Allow subclasses to choose node type (e.g. `Node2D`, `CharacterBody2D`, `RigidBody2D`) and add input, AI, or no movement.

**Non-Goals:**

- Changing the sprite-sheet addon API or file layout.
- Implementing enemies, NPCs, or environmental objects; only the base. Rewriting the player character to use this base is a separate, follow-up change.

## Decisions

### 1. Base node type: Node2D

**Choice:** The animated-entity base is implemented as a script on `Node2D` (or a node that does not require physics).

**Rationale:** Not every user is a character with collision: fire and other environmental sprites may be pure visuals. Forcing `CharacterBody2D` would require dummy physics for those. Subclasses that need physics (player, enemies) extend `CharacterBody2D` and attach or inherit the animation logic (e.g. via a shared script or composition).

**Alternatives considered:** Base as `CharacterBody2D` — rejected to avoid requiring collision/shapes for decorative entities.

### 2. Sprite and lookup ownership

**Choice:** Base class has a child `Sprite2D` (or equivalent) and holds a sprite-sheet lookup instance (default `AnimatedSpriteSheetLookup`). It applies the lookup result to the sprite’s `texture` each time state/direction/frame changes.

**Rationale:** Keeps rendering in one place. Lookup is created in `_ready()` or injected so tests or subclasses can substitute a different lookup (e.g. `StaticSpriteSheetLookup` for single-frame entities) without changing the base API.

**Alternatives considered:** Lookup as a global/singleton — rejected to keep per-entity overrides (e.g. `frame_count_override`) and testing simple.

### 3. Entity id and animation state

**Choice:** Entity id is configurable (e.g. `@export var entity_id: String`); default can be node `name` as a convenience or empty string (and require explicit set). Action/state and direction are properties (e.g. `action: String`, `direction: String` or index); current frame is internal but readable. Frame rate is configurable (e.g. `@export var frame_rate: float`), defaulting to 12 fps with option to override.

**Rationale:** Export allows one script to represent different entities (e.g. multiple fire nodes with different ids). Defaulting to `name` is a convenience when one node = one entity; no requirement to preserve any existing prototype behavior.

**Alternatives considered:** Entity id from name only — rejected to avoid silent breakage when renaming nodes in the editor.

### 4. Frame advance: Timer

**Choice:** Use a `Timer` node (or equivalent) for frame stepping. When the timer fires, the base SHALL advance the frame according to the current action’s playback mode (see Decision 6): Loop — increment and wrap to 0 at end; Play once / Hold last frame — increment until last frame, then stop (and for Play once, emit a finished signal). Refresh the sprite texture after any frame change.

**Rationale:** Keeps animation FPS explicit and independent of `_process` delta; easy to tune per entity type. The prototype used the same approach for reference. Playback modes determine whether we wrap or stop.

### 5. Optional base scene

**Choice:** Provide an optional `.tscn` that has the base script, a child `Sprite2D`, and a `Timer`. Subclasses can inherit this scene or build their own scene and attach the base script to a `Node2D`.

**Rationale:** Scene inheritance in Godot makes it easy to add collision, extra nodes, or scripts for player/enemy/NPC while reusing the same sprite + timer layout.

### 6. Animation clip playback modes

**Choice:** Support three playback modes per action: **Loop**, **Play once**, and **Hold last frame**. The mode SHALL be configurable per action (e.g. dictionary or override: action name → mode). Default SHALL be Loop so existing use (idle, walk) needs no config. When the timer would advance past the last frame: **Loop** — wrap to frame 0 and continue; **Play once** — stop advancing, stay on last frame, and emit a signal (e.g. `animation_finished(action)`) so subclasses can switch action or state; **Hold last frame** — stop advancing and remain on the last frame without emitting (or emit once so caller knows the clip ended). The base SHALL not advance the frame when already on the last frame and the mode is Play once or Hold last frame (timer can be stopped or no-op on fire).

**Rationale:** Walking and idle loop until the player changes state; attacks and other one-shots must run to completion and then hand control back (signal); death must play once and then stay on the final frame. Per-action config keeps one entity from hard-coding modes in script and allows different actions to have different behaviors. Emitting when Play once completes lets state machines react without polling.

**Alternatives considered:** (1) Only loop vs non-loop — rejected because “hold last frame” is a distinct UX need (death pose). (2) Mode passed each time action is set (e.g. `set_action("attack", PLAY_ONCE)`) — acceptable; we still need a default (Loop) and a way to know when a one-shot finished (signal). (3) No signal, subclass polls — rejected; signal is simpler for state machines.

## Risks / Trade-offs

- **Entity id default:** If entity id defaults to node `name`, renaming in the editor can point animation at the wrong asset. **Mitigation:** Document that `entity_id` should be set explicitly when the node name is not the entity id; optional placeholder in inspector.
- **Single sprite child:** Base assumes one primary sprite. Multi-part or layered characters would need a different design (e.g. multiple sprites or a subclass). **Mitigation:** Keep the base minimal; extend in subclasses for complex cases.
- **No built-in “flip” for 4-direction:** Current sheet uses 8 directions. If we later add 4-dir or flip-by-scale, that could be a subclass or a small helper. **Mitigation:** Not in scope for this base; document as future extension.

## Migration Plan

1. Add the new base script (e.g. `animated_entity.gd`) under `addons/entity/` and, if desired, a base scene (e.g. `animated_entity.tscn`) with `Sprite2D` and `Timer`.
2. Do not modify `addons/entity/characters/character.gd` in this change. The player character will be rewritten in a follow-up to use this base.
3. No separate rollback strategy: changes are in-tree; revert the commit if needed.

## Open Questions

- Final script and scene paths/names (e.g. `animated_entity.gd` vs `animated_entity_base.gd`; under `addons/entity/` root vs `addons/entity/nodes/`).
- Whether environmental sprites will use the same 8-direction animated layout or a simpler lookup (e.g. single row); if simpler, we may add an optional `StaticSpriteSheetLookup` or “direction count” later without changing the base contract.
