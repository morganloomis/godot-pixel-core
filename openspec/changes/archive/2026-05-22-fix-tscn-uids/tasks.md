## 1. Sync stale ext_resource UIDs

- [x] 1.1 Read the canonical UID at the top of `addons/godot-pixel-core/entity/animated_entity.tscn` (currently `uid://pvxyrn4b64y1`); record it in this task's review notes for future verification.
- [x] 1.2 In `addons/godot-pixel-core/entity/character_entity.tscn`, replace `uid="uid://bqx7animentity"` on the `animated_entity.tscn` `ext_resource` line with the canonical UID from 1.1.
- [x] 1.3 In `test/static_lit_prop.tscn`, apply the same replacement on its `animated_entity.tscn` `ext_resource` line.
- [x] 1.4 Grep `addons/`, `test/`, and `main.tscn` for any remaining `uid://bqx7animentity` and replace each with the canonical UID.

## 2. Audit other potentially stale UIDs

- [x] 2.1 For every `ext_resource` line in `addons/godot-pixel-core/**/*.tscn` and `test/**/*.tscn`, confirm the `uid="..."` matches the target file's actual UID; fix any other mismatches found.
- [x] 2.2 Spot-check `main.tscn` for the same property. (Found and fixed: `test/art/tile/paver/diffuse.png` was declared as `uid://cqpaverdiffus1` but actual UID per `.import` is `uid://djpl0k17j6hvy`.)

## 3. Verify in Godot

- [x] 3.1 Open the project in Godot 4.6 with the debugger console visible and confirm no "UID does not match resource_path" warnings appear during initial scan or on scene load.
- [x] 3.2 Confirm `character_entity.tscn`, `player_entity.tscn`, and `test/static_lit_prop.tscn` still open and behave as before.

## 4. Spec sync

- [x] 4.1 Run `openspec validate fix-tscn-uids --strict`; expect pass.
