## Why

The addon's prose docs lag the current code:

- `docs/ASSET_LIBRARY.md` "Sprite sheets" section still says PNG height splits into two equal blocks (top diffuse / bottom normal). That layout was replaced by the per-pass folder layout from `sprite-sheet-layout` and `sprite-sheet-normal-pass`.
- `addons/godot-pixel-core/README.md` already explains the per-pass layout but still mentions paths and references that will become stale once `remove-stale-entity-bundles` deletes `lit_animated_entity.gd`, `player_entity_lit.tscn`, `entity/characters/character.gd`, the `shaders/` directory, and the top-level `lighting/sprite_lighting.gd` duplicate.
- Adding `contact.png` to the documented animated pass table is the natural pairing with `rebase-sprite-shadows-on-per-pass-layout`; the doc table SHALL be ready when (and only when) the foot-shadow spec lands.
- The README explains features in prose but does not show **which addon `class_name` extends which Godot base** at a glance; today a reader has to grep `extends` lines across `entity/`, `sprite_sheet/`, `tile_map/`, and `lighting/`. The doc sweep is the right moment to add a single inheritance overview so the rewritten "Migration" sections agree with a single picture of the post-cleanup class set.

This change does the doc sweep and adds a small **class inheritance overview** to the README (extending the `addon-structure` capability with one new requirement). Beyond that it leaves spec content alone; the goal is "docs match shipping reality and a new reader can see the class shape in one glance".

## What Changes

- Update `docs/ASSET_LIBRARY.md` "Sprite sheets" section to describe `{entity}/{action}/{pass}.png` and link to `addons/godot-pixel-core/README.md` for the full pass table, instead of describing the obsolete two-block PNG.
- Sweep `addons/godot-pixel-core/README.md` for prose referencing files that `remove-stale-entity-bundles` deletes; rewrite the "Migration (entity refactor)" and "Legacy pseudo-lighting" sections to reflect the final state (everything legacy lives only under `lighting/legacy/`).
- Update `addons/godot-pixel-core/README.md` "Animated sheet layout" table when `rebase-sprite-shadows-on-per-pass-layout` lands, adding a row for `contact.png` (optional, same grid as diffuse, fed to foot-shadow shader). Until then the doc sweep deliberately leaves the table at its current four-pass form.
- Add a new **"Class overview"** section near the top of `addons/godot-pixel-core/README.md` containing a Mermaid `graph TD` chart of every addon `class_name` and its immediate Godot base, split into two subgraphs (scene-node classes and `RefCounted` helper classes) with the legacy `lighting/legacy/sprite_lighting.gd` named in a callout outside the canonical tree. `docs/ASSET_LIBRARY.md` links to this section rather than duplicating it. See `design.md` for the chart source and rationale.
- Re-check `addons/godot-pixel-core/lighting/legacy/README.md` and confirm it still accurately describes that bundle as the only place the custom pseudo-lighting shader/material/script lives once `remove-stale-entity-bundles` is applied.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `addon-structure`: tighten the existing "README documents animated pass layout" requirement so that `docs/ASSET_LIBRARY.md` does not contradict the README, and so that any reference to a removed file (e.g. `LitAnimatedEntity`, `player_entity_lit.tscn`) constitutes a documentation defect. Additionally **ADD** a requirement that `addons/godot-pixel-core/README.md` contains a class inheritance overview naming every addon `class_name` and its immediate Godot base, with the legacy bundle called out as outside the canonical tree.

## Impact

- **Docs**: `docs/ASSET_LIBRARY.md`, `addons/godot-pixel-core/README.md`, possibly `addons/godot-pixel-core/lighting/legacy/README.md`.
- **Code**: none.
- **Coordination**: best landed after `remove-stale-entity-bundles` (so the sweep removes confirmed-gone references and the class overview chart names only the surviving `class_name`s) and aligned with `rebase-sprite-shadows-on-per-pass-layout` (for the optional `contact.png` documentation row, when that ships).
- **Risk**: minimal — wording changes plus one Mermaid diagram. Risk-of-drift on the chart is mitigated by an explicit verification task and an `addon-structure` scenario tying any `class_name` change to a chart update.
