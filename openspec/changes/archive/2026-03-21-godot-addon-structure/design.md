# Design: Godot addon structure

## Context

**Current state:** This repo contains addon code under `addons/entity/` and `addons/sprite_sheet/`, a `test/` directory for in-repo testing, and standard Godot project files at the root (`project.godot`, `main.tscn`, etc.). The addon is consumed by other projects via git submodule. The Asset Library checklist and `.gitattributes` with `export-ignore` are already in place.

**Key constraint — path consistency:** Godot `.tscn` files use absolute `res://` paths for `ext_resource`. Addon scripts and scenes must use the same `res://` paths in both this dev project and consumer projects. This means the addon must live at the same relative path (`addons/godot-pixel-core/`) in both contexts.

**Stakeholders:** Developers working in this repo; consumers who add the addon to their games.

## Goals / Non-Goals

**Goals:**
- Establish `addons/godot-pixel-core/` as the single addon folder, with consistent `res://addons/godot-pixel-core/...` paths in dev and consumer projects.
- Move `addons/entity/` and `addons/sprite_sheet/` under `addons/godot-pixel-core/`.
- Document the submodule consumption pattern for consumers.
- Keep `test/` and root project files for in-repo development.

**Non-Goals:**
- Changing addon functionality or public API.
- Adding `plugin.cfg` or `EditorPlugin` (not needed for script-only addons using `class_name`).
- Asset Library publishing (submodule is primary distribution; Asset Library can be addressed later).

## Decisions

### 1. Addon at `addons/godot-pixel-core/` in the repo

**Choice:** Keep addon content at `addons/godot-pixel-core/` within this repo. All addon scripts, scenes, and resources live there. The development `project.godot` at the repo root sees the addon at `res://addons/godot-pixel-core/...` — the exact same path consumers will use.

**Rationale:** Godot `.tscn` files embed absolute `res://` paths. If addon content were at the repo root instead, the dev project would use `res://entity/...` while consumers would use `res://addons/godot-pixel-core/entity/...` — a mismatch that breaks scenes in one context or the other. Keeping the addon inside `addons/godot-pixel-core/` ensures paths match everywhere.

**Alternatives considered:**
- Addon content at repo root — rejected because of `res://` path mismatch between dev and consumer contexts. Scenes would need different paths depending on where they're loaded.

---

### 2. Submodule consumption pattern

**Choice:** Consumers submodule this repo into a staging location (e.g. `.addons-src/godot-pixel-core` or any non-`addons/` path), then symlink or copy `addons/godot-pixel-core/` into their own `addons/` folder.

**Rationale:** Git submodules target a whole repo, not a subfolder. If the consumer submoduled the repo directly at `addons/godot-pixel-core`, they'd get double-nesting (`addons/godot-pixel-core/addons/godot-pixel-core/...`). The staging + symlink pattern avoids this and is the established community approach (used by `gd-submodules` and similar tools).

**Consumer workflow:**
```bash
git submodule add <repo-url> .addons-src/godot-pixel-core
# Then either symlink:
#   Linux/Mac: ln -s ../../.addons-src/godot-pixel-core/addons/godot-pixel-core addons/godot-pixel-core
#   Windows:   mklink /D addons\godot-pixel-core .addons-src\godot-pixel-core\addons\godot-pixel-core
# Or just copy the folder.
```

**Alternatives considered:**
- Submodule directly at `addons/godot-pixel-core` — rejected because it double-nests the addon path.
- Addon content at repo root to enable direct submodule at `addons/godot-pixel-core` — rejected because it creates `res://` path mismatches (see Decision 1).

---

### 3. Internal layout under addon root

**Choice:** Move `addons/entity/` → `addons/godot-pixel-core/entity/` and `addons/sprite_sheet/` → `addons/godot-pixel-core/sprite_sheet/`. Preserve existing subfolder structure (e.g. `entity/characters/`, `sprite_sheet/*.gd`).

**Rationale:** Minimal churn; reflects current logical modules; consumers and this project already reference these concepts.

**Alternatives considered:** Flattening into a single folder — rejected because it would obscure module boundaries.

---

### 4. No `plugin.cfg` (script-only addon)

**Choice:** Do not add `plugin.cfg`. This addon provides script classes (via `class_name`) and scenes, not editor tools.

**Rationale:** Godot's `plugin.cfg` requires a `@tool` script extending `EditorPlugin`. This addon has no editor functionality — it provides runtime classes like `CharacterEntity`, `PlayerEntity`, and sprite-sheet lookups. Scripts using `class_name` are automatically available in any project that contains them; no plugin registration needed. A `plugin.cfg` can be added later if editor tools are introduced.

**Alternatives considered:** Adding a minimal `plugin.cfg` with a stub `EditorPlugin` — rejected because Godot requires the script to be `@tool` and extend `EditorPlugin`, and a stub provides no value for a script library.

---

### 5. Path updates in scenes and scripts

**Choice:** Update all `res://addons/entity/` references to `res://addons/godot-pixel-core/entity/` and `res://addons/sprite_sheet/` to `res://addons/godot-pixel-core/sprite_sheet/` in `.tscn` and `.gd` files.

**Rationale:** Scenes and scripts use hardcoded `res://` paths; moving files without updating references would break loading.

---

### 6. Test layout and root project files

**Choice:** Keep `test/` and root project files (`project.godot`, `main.tscn`, `icon.svg`, etc.) as-is. They stay in this repo for development and are excluded from distribution via `.gitattributes` `export-ignore`. The `test/` directory has a `.gdignore` so it won't be imported if visible in a consumer context.

**Rationale:** No change to how testing works. Test scenes reference `res://addons/godot-pixel-core/...` — the same paths consumers use.

---

### 7. License and README in addon folder

**Choice:** Place `LICENSE` and `README.md` in `addons/godot-pixel-core/` so the addon folder is self-contained.

**Rationale:** Consumers who copy or symlink only that folder have license and usage info.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-------------|
| **Path updates missed** in `.tscn` or script | Grep for old `addons/entity` and `addons/sprite_sheet` paths after migration; run project and load test scenes to verify. |
| **UID resolution** after path changes | Godot UIDs are content-based; moving files may require re-saving scenes. |
| **Submodule consumers need symlink step** | Document the pattern clearly. Provide example commands for Linux/Mac/Windows. This is the standard community approach. |
| **Symlink platform differences** | Windows requires developer mode for `mklink /D`; document this. Alternatively, consumers can just copy the folder. |

## Migration Plan

1. Create `addons/godot-pixel-core/` directory.
2. Move `addons/entity/` → `addons/godot-pixel-core/entity/` (preserve structure).
3. Move `addons/sprite_sheet/` → `addons/godot-pixel-core/sprite_sheet/` (preserve structure).
4. Add `addons/godot-pixel-core/LICENSE` (copy from root) and `addons/godot-pixel-core/README.md`.
5. Update all `res://addons/entity/` and `res://addons/sprite_sheet/` references in `.tscn` and `.gd` files to `res://addons/godot-pixel-core/entity/` and `res://addons/godot-pixel-core/sprite_sheet/`.
6. Update `main.tscn` and any `test/` scenes to use the new paths.
7. Verify: open project in Godot, run main scene, ensure all scripts and scenes load.
8. Document submodule consumption pattern for consumers.
9. Update project.md and ASSET_LIBRARY checklist to reflect the final structure.

**Rollback:** Revert the migration commits; restore `addons/entity/` and `addons/sprite_sheet/` from git history.

## Open Questions

- None.
