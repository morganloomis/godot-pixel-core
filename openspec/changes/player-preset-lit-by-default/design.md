## Context

`AnimatedEntity.use_2d_normal_lighting` is the single switch controlling whether the presenter's child `Sprite2D` gets a `CanvasItemMaterial(LIGHT_MODE_NORMAL)` and a `CanvasTexture` bundling diffuse + normal cells (see `_apply_2d_normal_lighting_setup()` and `update_sprite()` in `addons/godot-pixel-core/entity/animated_entity.gd`). Today the flag is set nowhere in the addon's player chain:

- `animated_entity.tscn` ships `use_2d_normal_lighting = false`.
- `player_entity.tscn` adds `entity_name = "player"` but does not touch the flag.
- `addons/godot-pixel-core/entity/characters/player.tscn` (after `fix-main-tscn-player-preset`) tunes the root and the collider but not the presenter.

`main.tscn` instances the addon preset under `DirectionalLight2D` + `CanvasModulate` and expects a normal-mapped sprite. Without an explicit opt-in somewhere on the chain, the player renders unlit (flat-tinted by `CanvasModulate` only).

## Goals / Non-Goals

**Goals:**

- Provide a "lit by default" player out of the box for the dev harness and any consumer using the addon's tuned preset.
- Keep `player_entity.tscn` and `character_entity.tscn` lighting-neutral so consumers retain choice (e.g., overhead-view games that don't use 2D normal lighting).
- Establish a single convention — *the tuned character preset under `addons/godot-pixel-core/entity/characters/` is the lit-opt-in point* — that future presets (NPCs, enemies) can follow.

**Non-Goals:**

- Changing the runtime behavior of `AnimatedEntity` or the lit-mode code paths.
- Forcing every player instance in every consumer project to be lit.
- Editing `main.tscn` (it benefits transitively).
- Re-introducing the legacy "lit" variant scene (e.g., a separate `player_entity_lit.tscn`) — the flag is the single source of truth.

## Decisions

### Decision 1: Lit-mode opt-in lives on the tuned preset, not on `player_entity.tscn`

The override `use_2d_normal_lighting = true` will be set on the inherited `AnimatedEntity` inside `addons/godot-pixel-core/entity/characters/player.tscn` — not inside `player_entity.tscn` itself.

**Rationale:**

- `player_entity.tscn` is a body-shaped building block (CharacterBody2D + presenter + collider). Lighting is a *presentation* choice; keeping it neutral matches the existing spec rule "Non-character reuse" (same presenter usable under various body types) and the "Engine-lit presenter behavior" requirement which treats lit mode as a per-instance authoring decision.
- The tuned preset is already where collider geometry and root tuning live; lighting fits the same "tuned defaults" mental model.
- Consumers who want an unlit player can either instance `player_entity.tscn` directly, or override `use_2d_normal_lighting = false` on their `Player` instance.

**Alternatives considered:**

- *Set the flag on `player_entity.tscn`*: would force lit mode on every direct consumer of the body scene and on `character_entity.tscn`-derived flows. Rejected — too opinionated for a base body scene; couples body geometry to a rendering choice.
- *Set the flag on `main.tscn`'s `Player` instance*: would fix the dev harness but leave every other consumer of the preset still unlit, defeating the "tuned preset" purpose. Rejected — leaks lighting opt-in into every consumer.
- *Reintroduce a separate `player_entity_lit.tscn`*: duplicates scenes and complicates inheritance. Rejected — `use_2d_normal_lighting` already exists as the single switch; an extra scene file is redundant.

### Decision 2: The override is a property override on the inherited child, not a re-instance

The override is added as a property edit on the inherited `AnimatedEntity` child (same node name, no `instance=`, no `type=`), per the rule established in `fix-main-tscn-player-preset`:

```
[node name="AnimatedEntity" parent="."]
use_2d_normal_lighting = true
```

**Rationale:** matches the new `sprite-presentation` requirement "Preset scenes do not re-instance the inherited presenter" (added by `fix-main-tscn-player-preset`). Re-instancing would re-introduce the exact bug that change just removed.

## Risks / Trade-offs

- **[Risk]** A consumer currently instancing `addons/godot-pixel-core/entity/characters/player.tscn` expecting unlit rendering will suddenly get lit rendering after this change. → Mitigation: document the change clearly; consumers can override the flag back to `false` on their instance. The preset is documented as a "tuned" demo preset, so a behavior shift on it is within tolerance for a pre-release addon. No production consumers are known.
- **[Trade-off]** "Lit by default" only applies to the *tuned* preset. Consumers who instance `player_entity.tscn` directly still need to opt in themselves. → Accepted: this is the intentional separation between "neutral body" and "tuned preset."
- **[Risk]** The lit path requires `normal.png` to exist (or it falls back to a flat normal via `_ensure_flat_normal_map_texture()`). For the player's `idle` and `walk` actions both `diffuse.png` and `normal.png` already exist under `test/art/sprite/player/{idle,walk}/`, so the dev harness will render correctly. → No mitigation needed for the current art set; documented for future actions added to the player.
