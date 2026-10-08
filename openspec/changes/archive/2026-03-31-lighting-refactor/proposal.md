## Why

The addon’s current pseudo-lighting path (custom shader parameters, manual normal assignment) has become hard to reason about and debug, and it diverges from Godot’s native 2D lighting model. Refactoring toward **standard Godot 2D lighting** (`Light2D`, `CanvasTexture`, and related canvas/lighting workflows) should improve maintainability, match engine documentation and community patterns, and still support **runtime-built spritesheets** (diffuse + normal regions from existing layout rules). Doing this behind a clear spec lets us adjust sheet or atlas strategy only if the engine path requires it.

## What Changes

- Replace (or supersede) the custom pseudo-lighting implementation with a **documented integration** that uses Godot’s **built-in 2D lighting** stack where feasible, including appropriate use of **`Light2D`** and **`CanvasTexture`** (or equivalent officially supported combinations for Godot 4.6 / GL Compatibility) so normals and diffuse stay correct for pixel-perfect art.
- Keep **normal maps aligned with diffuse** whenever the frame, action, or direction changes—the same user-visible guarantee as today, implemented through the new stack.
- **Preserve the current lighting implementation** in the tree under an explicit **legacy / archived** location (and/or recoverable via version control) so the project can **roll back** or compare behavior if the new path fails in practice. Legacy code SHOULD remain buildable or clearly marked read-only reference per `design.md`.
- Update **test scene** expectations so lit behavior is still demonstrable and regressions are visible.
- **Spritesheet layout** (combined diffuse/normal regions, animated layout) MAY stay as-is; if the engine-native path requires a different texture packaging (e.g. separate `CanvasTexture` slots, different atlas steps), that becomes an explicit decision in `design.md` and any affected specs.

## Capabilities

### New Capabilities

- `sprite-engine-2d-lighting`: How the addon wires **runtime spritesheet textures** (diffuse + normal from lookup/layout) into **Godot’s 2D lighting** workflow—layers, masks, `Light2D` usage, `CanvasTexture` (or documented alternatives), pixel-perfect constraints (nearest filtering, GL Compatibility), and how authors set up lit `AnimatedEntity` (or successor) in scenes.

### Modified Capabilities

- `sprite-presentation`: Update requirements for the **lit** path so they describe **engine-native 2D lighting** behavior (e.g. how the child `Sprite2D` / canvas item receives diffuse and normal for lighting) instead of (or in addition to) the current “shader `normal_map` parameter on a duplicated material” wording, while preserving presenter shape, exports intent (lit vs unlit), and normal-diffuse sync scenarios.
- `test-scene`: Extend or adjust requirements so the test scene **exercises the new lighting setup** in a way that stays easy to verify (lights, at least one lit prop or entity), without dropping coverage of existing player / lookup behavior.

## Impact

- **Addon**: `addons/godot-pixel-core/` — `lighting/`, `entity/` (e.g. `AnimatedEntity` / presenter), materials or scenes touched by lit mode; new or moved files under a **legacy** subtree for the previous approach.
- **Specs**: New delta under this change for `sprite-engine-2d-lighting`; deltas for `sprite-presentation` and `test-scene` as above. If layout or lookup **requirements** change (not only implementation), follow-on deltas for `sprite-sheet-layout` and/or `sprite-sheet-lookup` may be added during the specs phase.
- **Test harness**: `test/` scenes and scripts that demonstrate lighting.
- **Consumers**: The addon is still early / boilerplate; **backward compatibility is not a requirement**. Exports, autoloads, and lit setup may change freely; no obligation to preserve the old shader API or scene wiring beyond keeping a **legacy copy** for optional rollback or reference.
