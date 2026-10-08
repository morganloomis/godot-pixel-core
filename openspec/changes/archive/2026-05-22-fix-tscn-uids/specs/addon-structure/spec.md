# Spec Delta: addon-structure

## ADDED Requirements

### Requirement: ext_resource UIDs match referenced resources

Every `ext_resource` declaration in addon and in-repo test `.tscn` files SHALL specify a `uid://...` value that exactly matches the current UID of the referenced resource (the `uid://` written at the top of the target `.tscn` file, or the contents of the target's `.gd.uid` / `.gdshader.uid` sidecar). When an `ext_resource` references a resource whose UID has since changed, the referencing scene SHALL be updated so Godot does not emit a "UID does not match resource_path" warning on load.

#### Scenario: Addon scene references current UIDs

- **WHEN** any `.tscn` in `addons/godot-pixel-core/` is loaded in Godot 4.6
- **THEN** every `ext_resource uid="..."` in that scene SHALL resolve to the same file as its `path="..."` without a UID-mismatch warning

#### Scenario: Test scene references current UIDs

- **WHEN** any `.tscn` in `test/` is loaded in Godot 4.6
- **THEN** every `ext_resource uid="..."` in that scene SHALL resolve to the same file as its `path="..."` without a UID-mismatch warning

#### Scenario: Resource UID changes flow to references

- **WHEN** the canonical UID of a referenced resource (e.g. `addons/godot-pixel-core/entity/animated_entity.tscn`) changes
- **THEN** every `.tscn` in this repository that references that resource SHALL be updated in the same change so its `ext_resource` UID stays in sync; relying on Godot's path-based fallback SHALL NOT be considered an acceptable steady state
