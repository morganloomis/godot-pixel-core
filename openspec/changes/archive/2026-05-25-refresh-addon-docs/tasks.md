## 1. ASSET_LIBRARY.md sprite-sheet section

- [x] 1.1 Rewrite the `## Sprite sheets (Pixel Core addon)` section of `docs/ASSET_LIBRARY.md` so it describes per-pass files under `{entity}/{action}/{pass}.png`, names the four documented passes (`diffuse`, `normal`, `specular`, `occlusion`), and refers readers to `addons/godot-pixel-core/README.md` for the full table and pixel-art / lighting guidance.
- [x] 1.2 Remove the sentence that says "PNG height splits into **two equal blocks**: **top = diffuse**, **bottom = normals**"; replace it with the per-pass description.
- [x] 1.3 Keep the "Static half-diffuse / half-normal pairing is deferred" note **only if** that statement is still accurate against `sprite-sheet-normal-pass` → "Static sheets (optional same layout)"; otherwise drop or rephrase it. (Rephrased: half-diffuse / half-normal layout is explicitly not the design; static lit sprites will follow the same per-pass conventions when implemented.)

## 2. README sweep for removed-file references

- [x] 2.1 Grep `addons/godot-pixel-core/README.md` for `LitAnimatedEntity`, `player_entity_lit`, `entity/characters/character.gd`, `shaders/sprite_lit`, and top-level `lighting/sprite_lighting`. (Only matches now live in the Migration / Legacy sections in past-tense context; no `shaders/` or top-level `lighting/sprite_lighting` references remain.)
- [x] 2.2 In the "Migration (entity refactor)" and "Legacy pseudo-lighting" sections, rewrite each reference so it describes the legacy state in past tense (e.g. "previously `LitAnimatedEntity`; now configure `use_2d_normal_lighting` on `AnimatedEntity`"); SHALL NOT present any of those files as current API.
- [x] 2.3 Confirm the "Features" bullet for "Character scenes" still names `player_entity.tscn` as canonical and does not promote `player_entity_lit.tscn`.
- [x] 2.4 If `addons/godot-pixel-core/shaders/` has been deleted by `remove-stale-entity-bundles`, remove any README path references to that directory and adjust any link to the legacy shader so it points to `addons/godot-pixel-core/lighting/legacy/sprite_lit.gdshader`. (Directory deleted on disk; README already had no `shaders/` path references, and shader links already point to `lighting/legacy/sprite_lit.gdshader`.)

## 3. Legacy README sanity check

- [x] 3.1 Open `addons/godot-pixel-core/lighting/legacy/README.md` and confirm it accurately states (a) the legacy bundle is not autoloaded by default, (b) the canonical lit path is engine 2D lighting via `use_2d_normal_lighting`, and (c) the bundle's files are intended for reference and manual rollback only. (Tightened (b) to name `use_2d_normal_lighting` on `AnimatedEntity` / `LitTileMapLayer` explicitly.)

## 4. Optional contact.png row (deferred dependency)

- [ ] 4.1 When `rebase-sprite-shadows-on-per-pass-layout` lands and `sprite-shadows` is applied, add a row to the README's animated pass table for `contact.png` (optional, same grid as diffuse, consumed by the foot-shadow shader). Until then, deliberately leave the table at its four-pass form. *(Deferred — `rebase-sprite-shadows-on-per-pass-layout` is still in-progress; table left at four-pass form per task wording.)*

## 5. Class overview chart (README)

- [x] 5.1 Add a new `## Class overview` section to `addons/godot-pixel-core/README.md`, placed **above** `## Features` and **below** `## Architecture: body vs presentation`.
- [x] 5.2 Insert the Mermaid `graph TD` chart from `design.md` "Reference: the chart itself" into the new section. The two subgraphs SHALL be `scene` (scene-node classes) and `helpers` (`RefCounted` helpers).
- [x] 5.3 Under the chart, add a short prose paragraph re-stating the same relationships in text (so the section is still useful when Mermaid does not render), plus a one-line **"Composition, not inheritance"** callout noting that `CharacterEntity` (and therefore `PlayerEntity`) contains a child `AnimatedEntity` and that this is intentionally not drawn as an arrow.
- [x] 5.4 Add a **"Legacy bundle"** callout (sentence-level, not a node in the chart) naming `addons/godot-pixel-core/lighting/legacy/sprite_lighting.gd`, noting it has no `class_name`, and stating it loads only when a project manually autoloads it. Link the existing `## Legacy pseudo-lighting (lighting/legacy/)` section.
- [x] 5.5 Verify the chart's `class_name` set matches what is on disk: grep `class_name` across `addons/godot-pixel-core/**/*.gd` and confirm every match appears as a node in the chart, and that no node in the chart is missing from disk. (9 `class_name`s on disk — `AnimatedEntity`, `CharacterEntity`, `PlayerEntity`, `LitTileMapLayer`, `SpriteSheetLookupBase`, `AnimatedSpriteSheetLookup`, `StaticSpriteSheetLookup`, `TileSpriteSheetLookup`, `TileLitMaterialFactory` — all appear as chart nodes; no extra nodes.)
- [x] 5.6 In `docs/ASSET_LIBRARY.md`, add a one-line pointer to the README's "Class overview" section near the top of the addon-related material; do not duplicate the chart.

## 6. Verification

- [x] 6.1 Re-read the updated `docs/ASSET_LIBRARY.md` and `addons/godot-pixel-core/README.md` side-by-side; confirm they agree on layout, default roots, which lighting path is the default, and that ASSET_LIBRARY links to the README "Class overview" section rather than duplicating it.
- [x] 6.2 Open the rendered README (GitHub preview, or the Godot editor's Markdown viewer if available) and confirm the Mermaid chart renders as a diagram and that the raw source under it is still legible if it does not. (Rendered preview not available from this environment; verified the Mermaid source parses against the documented `graph TD` / `subgraph` grammar and that the prose paragraph immediately under it re-states the same relationships so the section remains legible without rendering.)
- [x] 6.3 Run `openspec validate refresh-addon-docs --strict`; expect pass.
