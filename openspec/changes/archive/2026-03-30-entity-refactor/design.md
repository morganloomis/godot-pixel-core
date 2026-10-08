## Context

The addon today mixes several overlapping patterns:

- **`AnimatedEntity`** (`Node2D` + child `Sprite2D` + `Timer`) owns sheet lookup, frame rate, action/direction, and frame advance.
- **`LitAnimatedEntity`** subclasses `AnimatedEntity` and only adds duplicated lit material + normal binding in `update_sprite()`.
- **`CharacterEntity`** (`CharacterBody2D`) references a child presenter; **`PlayerEntity`** subclasses it.
- **Legacy** `entity/characters/character.gd` duplicates animation/lookup on `CharacterBody2D` without `AnimatedEntity`.
- **Lit player** uses `player_entity_lit.tscn`, which differs from `player_entity.tscn` mainly by instancing `lit_animated_entity.tscn` instead of `animated_entity.tscn`.

Conversation clarified product intent: **one shared presenter** for characters, moving effects (spells, loot), and static animated props (torches, impassible bushes); **minimal class count**; **lit** and **frame rate** are presenter concerns, not parallel class trees. **Tiles** (`TileMapLayer` / `TileSet`) are not part of the character inheritance chain; they may still reuse the same lookup/material **rules** via composition or documented patterns.

**Constraint:** Presenter implementation stays **`Node2D` script + child `Sprite2D`** (not `extends Sprite2D`) for flexibility and alignment with the current scene layout.

## Goals / Non-Goals

**Goals:**

- Single configurable presenter type (or one script + scene) where **pseudo-lit** is toggled via export/flag (or tiny composable helper), eliminating `LitAnimatedEntity` as a separate subclass for normal use.
- **One player scene** (or one documented pattern) where lit vs unlit is configuration, not a forked `.tscn`.
- Remove or retire **legacy** `characters/character.*` in favor of `CharacterEntity` + presenter.
- Document **body vs presenter**: `CharacterBody2D` / `StaticBody2D` / `Node2D` roots for world role; presenter child for all sheet + lighting presentation shared across those roots.
- Document **tile vs scene prop** tradeoffs and how to reuse presentation logic without implying tiles subclass `CharacterEntity`.

**Non-Goals:**

- Replacing Godot’s `TileMapLayer` with a custom tile engine.
- Guaranteeing per-cell TileMap pseudo-lit normals with the same ergonomics as `Sprite2D` instances (may remain a documented limitation or hybrid approach).
- Adding network multiplayer or save-format design.
- `extends Sprite2D` presenter (explicitly out of scope for this refactor).

## Decisions

### 1. Presenter shape: `Node2D` + child `Sprite2D`

**Choice:** Keep the presenter as a **`Node2D`-rooted** node with an owned **`Sprite2D`** (and `Timer` or `_process`-driven tick), matching `AnimatedEntity`.

**Rationale:** Avoids subclassing engine draw nodes; keeps room for extra children (future effects); matches existing scenes and tests.

**Alternatives considered:** `extends Sprite2D` — fewer nodes, but weaker for multi-layer sprites and diverges from current addon; rejected for this change.

### 2. Lit behavior: property or composition on the presenter

**Choice:** Implement pseudo-lit by **branching inside the presenter** (e.g. `@export var use_pseudo_lighting: bool` or `lit: bool`) that, when enabled, duplicates `sprite_lit_material.tres`, assigns it to the child `Sprite2D`, sets nearest filter, and binds `normal_map` each `update_sprite()`. When disabled, behavior matches current unlit path (no material or default).

**Rationale:** One scene (`animated_entity.tscn` or renamed equivalent), one script class for the common case; removes `LitAnimatedEntity` and `lit_animated_entity.tscn` from the public surface.

**Alternatives considered:** Separate `Node` child “lighting binder” — more composable but more scene wiring for every user; keep as optional follow-up if scripts get too large.

### 3. Class hierarchy for “things in the world”

**Choice:**

- **Presenter** — one primary class (evolution of `AnimatedEntity`) for sheet display + optional lit.
- **Character stack** — `CharacterEntity` → `CharacterBody2D` + child presenter; `PlayerEntity` extends `CharacterEntity` for input.
- **Non-characters** — game code uses **`StaticBody2D` + presenter** (static impassible prop), **`Area2D`/`RigidBody2D` + presenter** (loot, spells), or plain **`Node2D` + presenter** when no physics body is needed; these are **not** new addon classes unless we add thin optional scenes later.

**Rationale:** Minimizes addon surface area; game chooses body type.

### 4. Legacy character scene

**Choice:** **Remove** `entity/characters/character.gd` and `character.tscn` from the addon (or deprecate with removal in same change), and point demos/docs to `CharacterEntity` + presenter.

**Rationale:** Eliminates duplicated animation logic; single path for “character with sheet animation.”

### 5. Player packaging

**Choice:** **Single** `player_entity.tscn` with presenter child using lit flag as configured; remove `player_entity_lit.tscn` or keep as deprecated alias that instances the same scene with a preset.

**Rationale:** Same script `player_entity.gd`; no duplicate scene for lighting variant.

### 6. Tiles and map props

**Choice:** **Do not** introduce a “tile entity” class under `CharacterEntity`. Document that:

- **Scene-based props** (bush, torch) should use **body + presenter** for per-instance materials and normals.
- **TileMap** remains the right tool for mass grid content; reuse of lookup/lighting may use **shared static helpers** (e.g. resolving `AtlasTexture` pairs) or **custom tile scripts / hybrid layers**, spelled out in `sprite-presentation` spec and README.

**Rationale:** Matches Godot’s architecture; avoids false inheritance.

## Risks / Trade-offs

- **[Risk] Breaking API** — External projects subclass `LitAnimatedEntity` or load removed scenes. → **Mitigation:** Changelog + README migration: use presenter with `lit` enabled; rename notes if class renamed.
- **[Risk] Scene upgrade churn** — Existing scenes reference old sub-scenes. → **Mitigation:** Godot may remap UIDs if files removed carefully; provide one release note with before/after tree.
- **[Risk] TileMap lit parity** — Full per-tile pseudo-lit may stay harder than `Sprite2D`. → **Mitigation:** Document recommended patterns (prop scenes for hero bushes; tile layer for ground).
- **[Risk] Script size** — Presenter gains branches for lit/unlit. → **Mitigation:** Keep lit path in focused private methods; consider extraction to a `RefCounted` helper only if needed.

## Migration Plan

1. Implement presenter `lit` (or equivalent) and make unlit default match current `AnimatedEntity`.
2. Update `character_entity.tscn` / `player_entity.tscn` to use unified presenter; delete or alias lit-only scenes.
3. Remove `LitAnimatedEntity` script/scene after grep confirms no internal references.
4. Remove legacy `characters/character.*`; update `test/` and `main.tscn` if they referenced them.
5. Update README and `openspec/project.md` (already aligned with this design).
6. Ship delta specs + tasks completion before archive.

**Rollback:** Revert branch; restore deleted scenes from git history.

## Open Questions

- Whether to **rename** `AnimatedEntity` to a clearer name (e.g. `SpriteSheetPresenter`) — **BREAKING** for `class_name`; decide during implementation vs follow-up.
- Whether to add a **small optional** `static_prop.tscn` example (`StaticBody2D` + presenter) in `test/` only for documentation-by-example.
- Exact **helper API** for tile-adjacent use (static functions on lookup vs small `SpritePresentation` utility class) — finalize when writing `sprite-presentation` spec.
