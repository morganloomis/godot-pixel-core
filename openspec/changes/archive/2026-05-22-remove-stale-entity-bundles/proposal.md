## Why

`addons/godot-pixel-core/README.md` and the active specs say several files have been removed in favour of the unified presenter + `use_2d_normal_lighting` model, but they are all still on disk and ship with the addon:

- `entity/lit_animated_entity.gd` / `.tscn` — a `class_name LitAnimatedEntity` subclass whose only job is lit behavior. This directly violates `entity-hierarchy` → "Single presenter type for lit and unlit" and `animated-entity-speed` → "Presenter exports pseudo-lighting configuration".
- `entity/player_entity_lit.tscn` — a second packaged player scene whose only difference is instancing the lit subclass. This violates `entity-hierarchy` → "Packaged player uses one scene pattern".
- `entity/characters/character.gd` / `character.tscn` — a `CharacterBody2D` that reimplements timer-driven sprite-sheet logic in parallel to `AnimatedEntity`. This violates `entity-hierarchy` → "Legacy inline character removed".
- `shaders/sprite_lit.gdshader` + `sprite_lit_material.tres` (and `.uid` siblings) — duplicates of the legacy custom shader/material that already live correctly under `lighting/legacy/`. Their sole runtime consumer is `lit_animated_entity.gd`.
- `lighting/sprite_lighting.gd` (and `.gd.uid`) — byte-equivalent to `lighting/legacy/sprite_lighting.gd`. Not autoloaded; not referenced by any default path.

Beyond the spec violations, the duplicated `.gd.uid` and `.gdshader.uid` files share UIDs with their legacy counterparts (see `fix-tscn-uids` change), so Godot logs warnings on every project open.

## What Changes

- **BREAKING (for consumers still referencing removed symbols)**: delete the stale files listed above so the addon directory matches the spec narrative and the README's stated removals.
- Confirm `lit_animated_entity.gd` and `character.gd` have no remaining references in the addon, test, or dev harness; remove the `entity/characters/` directory entirely if `character.gd` was its only resident. `entity/characters/player.tscn` is addressed by the sibling change `fix-main-tscn-player-preset`; this change is allowed to leave that file in place pending that proposal.
- No spec deltas: every file removed here is already forbidden by an existing requirement, so this change is conformance-only.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

(none — pure code conformance to existing `entity-hierarchy` and `animated-entity-speed` requirements)

## Impact

- **Addon files removed**:
  - `addons/godot-pixel-core/entity/lit_animated_entity.gd`
  - `addons/godot-pixel-core/entity/lit_animated_entity.gd.uid`
  - `addons/godot-pixel-core/entity/lit_animated_entity.tscn`
  - `addons/godot-pixel-core/entity/player_entity_lit.tscn`
  - `addons/godot-pixel-core/entity/characters/character.gd`
  - `addons/godot-pixel-core/entity/characters/character.gd.uid`
  - `addons/godot-pixel-core/entity/characters/character.tscn`
  - `addons/godot-pixel-core/shaders/sprite_lit.gdshader`
  - `addons/godot-pixel-core/shaders/sprite_lit.gdshader.uid`
  - `addons/godot-pixel-core/shaders/sprite_lit_material.tres`
  - `addons/godot-pixel-core/lighting/sprite_lighting.gd`
  - `addons/godot-pixel-core/lighting/sprite_lighting.gd.uid`
- **Side effect**: the duplicate-UID warnings for `sprite_lighting.gd.uid` and `sprite_lit.gdshader.uid` disappear, partially overlapping with `fix-tscn-uids`.
- **Docs**: `README.md` already documents these as "removed"; the `refresh-addon-docs` change covers any stray prose that still mentions them.
- **Risk**: low. `lit_animated_entity.gd` references `shaders/sprite_lit_material.tres`; both go together. `lighting/sprite_lighting.gd` has no autoload entry in `project.godot`. The `shaders/` directory becomes empty and SHALL be removed if Godot does not auto-clean it.
