# Tasks: lighting-refactor

## 1. Legacy bundle

- [x] 1.1 Create `addons/godot-pixel-core/lighting/legacy/` and add a short `README.md` describing that the bundle is optional reference/rollback, not part of the default lit path.
- [x] 1.2 Move `sprite_lighting.gd` (and `.uid`), `sprite_lit.gdshader` (and `.uid`), and `sprite_lit_material.tres` into `lighting/legacy/`; fix any internal paths or preload strings that break after the move.
- [x] 1.3 Update comments in legacy shader/scripts so they point at the `legacy/` location and no longer claim to be the active autoload path.

## 2. Engine-lit presenter (`AnimatedEntity`)

- [x] 2.1 Replace the duplicated `sprite_lit` material path: when lit mode is on, assign the child `Sprite2D`’s **diffuse** and **normal map** from lookup each `update_sprite`, using a `CanvasItemMaterial` (or documented default) that **receives** Godot **2D lights**; set **nearest** texture filter on the sprite for lit mode.
- [x] 2.2 Remove all `SpriteLighting.register_lit_material` / `unregister_lit_material` usage from the presenter lifecycle.
- [x] 2.3 Rename the exported **lit** flag away from `use_pseudo_lighting` to a name that matches engine behavior (e.g. `use_2d_normal_lighting`); update `animated_entity.tscn`, `test/static_lit_prop.tscn`, and any other scenes that set the old property.
- [x] 2.4 Rename private methods and comments that still say “pseudo_lighting” where they refer to the new behavior.

## 3. Project wiring and cleanup

- [x] 3.1 Remove the `SpriteLighting` entry from `[autoload]` in `project.godot`.
- [x] 3.2 Delete or relocate any remaining non-legacy references under `addons/godot-pixel-core/` that preload the old material from the pre-legacy path (ensure only `lighting/legacy/` holds the old shader trio unless a deliberate re-export exists).

## 4. Test harness

- [x] 4.1 Update `test/test_scene.gd`: remove `SpriteLighting` usage and exported “default directional” knobs tied to it; set ambient tone with `CanvasModulate` and/or documented defaults instead if needed.
- [x] 4.2 Edit `test/test_scene.tscn`: add at least one **`DirectionalLight2D`** or **`PointLight2D`** (or both) so the lit presenter is visibly shaded; enable the presenter’s new lit export on the `PlayerEntity`’s `AnimatedEntity`.
- [x] 4.3 Update `test/static_lit_prop.tscn` (and any other test scenes) to use the new lit export and rely on scene lights rather than `SpriteLighting`.

## 5. Documentation

- [x] 5.1 Rewrite `addons/godot-pixel-core/README.md`: document **engine 2D lighting** setup (`DirectionalLight2D` / `PointLight2D`, `CanvasModulate`, lit export on `AnimatedEntity`); move or shrink old pseudo-lighting API docs to a **Legacy** subsection pointing at `lighting/legacy/`.

## 6. Verification

- [x] 6.1 Run the project (**GL Compatibility**): confirm walk/idle still resolve test assets, lit mode shows normal-aligned shading, and unlit mode still behaves.
- [x] 6.2 Confirm no `test/` script reimplements lighting or lookup (per delta spec); addon scripts pass warnings check for shipped code.
