## Why

The addon exposes overlapping entity scenes and scripts (`characters/character` vs `character_entity`, `animated_entity` vs `lit_animated_entity`, separate lit player scene), which duplicates behavior and forces users to pick parallel class hierarchies for lighting and animation. Consolidating around a **small, obvious inheritance tree** and treating **lit** and **animated** as configuration (or shared components) will reduce maintenance cost and make the API easier to learn. Clarifying how **tiles** fit in avoids mistakenly modeling them as another character subclass.

**Presenter model (vocabulary):** **Presentation** (sheet lookup, frame rate, action/direction, optional pseudo-lit diffuse + normal binding) lives on a **presenter** node. The chosen shape for the addon is a `**Node2D` root script with a child `Sprite2D`** (the existing `AnimatedEntity` pattern)—**not** a custom `extends Sprite2D` type—so the same presenter can be parented under `CharacterBody2D`, `StaticBody2D`, or plain `Node2D` for spells, loot, torches, or bushes. **Physics and gameplay** (movement, collision, attributes) stay on the appropriate body; presenters stay reusable and minimal.

## What Changes

- **Minimal inheritance model** — Keep a clear split between **physics/character bodies** (e.g. `CharacterBody2D` + attributes + collision) and **sprite presentation** (presenter: `Node2D` + child `Sprite2D`), with at most one canonical path per role; document the intended tree in specs, `openspec/project.md`, and addon README.
- **Lit and animated as properties or composition** — **BREAKING**: Replace separate types such as `LitAnimatedEntity` (subclass) with behavior toggled on a single presenter (e.g. exports on `AnimatedEntity` or a small child helper like lighting/material binding), so one scene/script can be lit or unlit without swapping class hierarchy.
- **Remove or retire legacy duplicate** — **BREAKING**: Deprecate or remove `entity/characters/character.gd` and `character.tscn` (inline sprite/timer logic duplicates `AnimatedEntity`); migrate any demos or docs to `CharacterEntity` + shared presenter.
- **Unify player packaging** — Prefer one `PlayerEntity` scene (or documented pattern) where lighting is configured via property/instance rather than a separate `player_entity_lit.tscn` that only differs by child scene type.
- **Tiles vs characters** — Do **not** add tiles as a subclass of the character hierarchy. Godot tiles are authored through `TileMapLayer` / `TileSet` and are not `CharacterBody2D`. The change SHALL make **sprite-sheet lookup, frame advance, and diffuse/normal binding** reusable from **composition or shared APIs** so that:
  - **Props / free-standing cells** can use the same presenter node under `Node2D`.
  - **Tile maps** can consume the same logic via an explicit strategy documented in design (e.g. custom tile metadata + scripting, replacement sprites for lit layers, or hybrid workflows), without implying `TileMapLayer` “extends” character entity.

## Capabilities

### New Capabilities

- `entity-hierarchy`: Requirements for the minimal set of entity scripts/scenes (character body vs sprite presenter), removal of redundant legacy character scenes, and configuration-based lit/animated behavior instead of parallel subclasses/scenes.
- `sprite-presentation`: Requirements for reusable presentation behavior—texture lookup, animation timing, optional pseudo-lit material and normal map binding—so the same rules apply to character-attached presenters and to non-character uses (props; documented tile integration paths without character inheritance).

### Modified Capabilities

- `character-entity`: Update requirements if the child display node is no longer strictly a separate `AnimatedEntity` / `LitAnimatedEntity` class split—while still mandating delegation of sheet logic and no duplication of lookup/timer behavior.
- `player-entity`: Update only if the spec currently assumes a specific child scene type (`AnimatedEntity` vs lit variant); behavior (input, movement, action/direction) should remain the same.
- `animated-entity-speed`: Align with any renamed or merged presenter type if exports or property names change; preserve semantics for frame rate and movement speed unless intentionally revised in design.

## Impact

- **Code**: `addons/godot-pixel-core/entity/` — `animated_entity.gd`, `lit_animated_entity.gd`, `character_entity.tscn`, `player_entity.tscn`, `player_entity_lit.tscn`, `lit_animated_entity.tscn`, `entity/characters/`*, `lighting/sprite_lighting.gd` interactions, and possibly `README.md` / demo scenes under `test/` or `main.tscn`.
- **API**: **BREAKING** for projects that subclass `LitAnimatedEntity` or instantiate lit-only scenes; migration path = same presenter with lit enabled.
- **Specs**: New delta specs under this change for `entity-hierarchy` and `sprite-presentation`; deltas for `character-entity`, `player-entity`, and `animated-entity-speed` as needed.
- **Project docs**: Update `openspec/project.md` domain concepts (presenter vs body, shared use for props/tiles guidance).
- **Addon documentation**: Update `addons/godot-pixel-core/README.md` to describe the same architecture vocabulary and usage patterns.
- **Tiles**: No requirement that tiles become a new scene class in the character tree; design/spec will choose how consumers apply shared presentation to `TileMapLayer` workflows.

