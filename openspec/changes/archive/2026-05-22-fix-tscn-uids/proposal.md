## Why

Two classes of UID problems exist in the addon today:

1. **Stale `ext_resource` UIDs** — `addons/godot-pixel-core/entity/character_entity.tscn` and `test/static_lit_prop.tscn` reference `animated_entity.tscn` by `uid://bqx7animentity`, but the actual UID of `animated_entity.tscn` is `uid://pvxyrn4b64y1`. Godot logs "UID does not match" and falls back to the path; the scenes still load, but the warnings are noisy and brittle.
2. **Duplicate UIDs across files** — `lighting/sprite_lighting.gd.uid` and `lighting/legacy/sprite_lighting.gd.uid` both contain `uid://c3s8sf1c5q75h`; `shaders/sprite_lit.gdshader.uid` and `lighting/legacy/sprite_lit.gdshader.uid` both contain `uid://bysck8xg6w7sg`. UIDs are supposed to be unique per resource, so Godot prints a "duplicate UID" warning on every project open and the editor's UID-to-path resolution is non-deterministic.

`remove-stale-entity-bundles` will eliminate the duplicate UID issue as a side effect by deleting the non-legacy `sprite_lighting.gd` and `shaders/sprite_lit.gdshader`. This change focuses on the **stale `ext_resource` UIDs** that survive the cleanup. The two changes can ship in either order; if `remove-stale-entity-bundles` lands first, only tasks 1.x of this change are needed.

## What Changes

- Update the `ext_resource` block in `addons/godot-pixel-core/entity/character_entity.tscn` so the `animated_entity.tscn` reference uses `uid://pvxyrn4b64y1`.
- Update the matching `ext_resource` block in `test/static_lit_prop.tscn`.
- Codify "no stale `ext_resource` UIDs" as a small `addon-structure` requirement so future scenes are checked against this.

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `addon-structure`: add a requirement that `ext_resource` UIDs in addon and test `.tscn` files match the current UID of the referenced resource so Godot does not log UID-mismatch warnings on load.

## Impact

- **Code**: two `.tscn` files updated.
- **Risk**: very low. Godot resolves by path when UID does not match, so behavior was correct already; this change removes warnings and makes the references canonical.
- **Coordination**: independent of, but complementary to, `remove-stale-entity-bundles` (which separately fixes the duplicate-UID warnings by deleting the duplicate `.uid` files).
