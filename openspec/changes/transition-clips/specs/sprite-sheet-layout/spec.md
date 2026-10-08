## ADDED Requirements

### Requirement: Transition action folders use from-to naming

Animated entities MAY include optional **transition action** folders named `{from}-{to}` under `{animated_root}/{entity}/`, where `{from}` and `{to}` are logical action names (e.g. `idle`, `walk`). A transition folder SHALL use the same per-action pass layout as any other animated action (`diffuse.png` required; optional `normal.png`, `specular.png`, `occlusion.png`). Transition folders are discovered by the presenter for automatic bridge playback; gameplay code SHALL NOT assign `{from}-{to}` names via `set_action` under normal use.

#### Scenario: Transition folder path resolves like any action

- **WHEN** the system needs diffuse for entity `player`, action `idle-walk`
- **THEN** the path SHALL be `{animated_root}/player/idle-walk/diffuse.png` and frame count SHALL be derived from that diffuse grid like other animated actions

#### Scenario: Reverse transition is a separate folder

- **WHEN** both `idle-walk` and `walk-idle` folders exist for an entity
- **THEN** each SHALL be independent action directories with their own pass files; the presenter SHALL NOT infer one from the other

#### Scenario: Transition folder optional

- **WHEN** `{animated_root}/{entity}/idle-walk/` does not exist or has no valid `diffuse.png`
- **THEN** the layout SHALL NOT treat that as an error; the presenter SHALL fall back to an immediate switch to `walk` per `animated-action-transition`
