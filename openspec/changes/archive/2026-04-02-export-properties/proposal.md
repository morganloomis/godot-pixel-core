## Why

Authors tune movement and animation together with other character fields (health, `entity_name`) on the character root. Today **movement speed** and **animation frame rate** live only on the child `AnimatedEntity`, so the inspector forces drilling into the child for common tweaks. Surfacing the same values on `CharacterEntity` and `PlayerEntity` keeps one logical place for “character tuning” at the root.

## What Changes

- Add **editor-visible forwarded exports** on `CharacterEntity` for **movement speed** and **animation frame rate** that read and write the child `AnimatedEntity`’s `movement_speed` and `frame_rate` (same semantics and defaults as today on the presenter).
- `PlayerEntity` **inherits** those exports from `CharacterEntity` (no duplicate script properties).
- Keep **standalone** `AnimatedEntity` (props, tests) **unchanged**: it retains its own exports when not under a character root.
- The existing read-only **`speed`** property on `CharacterEntity` MAY remain as a convenience getter aligned with forwarded movement speed, or be folded into the new export; implementation detail in design.
- Update specs so **animated-entity-speed** and **character-entity** no longer forbid root-level authoring for packaged character layouts; they SHALL describe forwarding instead of “only on child.”

## Capabilities

### New Capabilities

- (none)

### Modified Capabilities

- `animated-entity-speed`: Replace the requirement that `CharacterEntity` must not duplicate movement speed with a requirement that the character root **forwards** movement speed and frame rate to the child presenter (single stored values on `AnimatedEntity`, edited from root or child).
- `character-entity`: Require inspector-visible **movement speed** and **animation frame rate** on the character root (forwarded to child presenter), alongside existing `entity_name` and health exports.
- `player-entity`: Clarify that the player root **inherits** the same forwarded movement and framerate exports from `CharacterEntity` for authoring.

## Impact

- **Code**: `addons/godot-pixel-core/entity/character_entity.gd`, possibly `player_entity.gd` (docs only if inheritance suffices), packaged `.tscn` files if default values should live on root instead of child.
- **API**: New or expanded `@export` properties on `CharacterEntity`; behavior of `speed` getter documented to match forwarded movement speed.
- **Specs**: Delta files under `openspec/changes/export-properties/specs/` for the three capabilities above.
