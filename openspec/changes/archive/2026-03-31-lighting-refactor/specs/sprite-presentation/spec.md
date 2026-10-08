# Spec Delta: Sprite presentation

## MODIFIED Requirements

### Requirement: Shared presentation properties

The presenter SHALL expose **animation framerate** and **movement speed** (when used by character motion) in a single place consistent with `animated-entity-speed`. It SHALL expose an exported **lit mode** flag (or equivalent export name) so consumers enable **engine 2D normal-mapped lighting** vs unlit without changing presenter class.

#### Scenario: Inspector exposes framerate and lit mode

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include exported properties for animation framerate and for enabling lit mode (names MAY match implementation but behavior SHALL match this spec)

---

### Requirement: Tile map integration is non-hierarchical

`TileMapLayer` authoring SHALL remain independent of the presenter scene tree: games are NOT required to attach the presenter script to individual tile cells to use the same **sprite sheet layout and lookup types** for tiles. Addon documentation SHALL describe recommended patterns for per-instance **engine-lit** animated props (body + presenter) versus bulk tiled map content.

#### Scenario: Tile versus scene prop guidance exists

- **WHEN** a consumer reads addon documentation for map content
- **THEN** it SHALL describe that per-instance lit animated props are typically scene instances (body + presenter), while bulk grid content uses `TileMapLayer`, and that both MAY share lookup conventions

---

## REMOVED Requirements

### Requirement: Pseudo-lit material behavior

**Reason**: Replaced by engine 2D lighting on `Sprite2D` plus `sprite-engine-2d-lighting` requirements; the duplicated `sprite_lit` material and shader parameter `normal_map` path are no longer the contract.

**Migration**: Implementations SHALL follow **Requirement: Engine-lit presenter behavior** below and the `sprite-engine-2d-lighting` spec.

---

## ADDED Requirements

### Requirement: Engine-lit presenter behavior

When lit mode is enabled, the presenter SHALL configure the child **`Sprite2D`** for **Godot 2D lighting**: assign **`texture`** from the lookup diffuse pass, assign the sprite’s **normal map** from the lookup normal pass for the same entity, action, direction, and frame, and apply the **material and filter** rules from `sprite-engine-2d-lighting`. The presenter SHALL **not** register materials with a legacy autoload for uniform fan-out on the default path.

#### Scenario: Normal follows diffuse under engine lighting

- **WHEN** the presenter advances frame or changes action or direction while lit mode is enabled
- **THEN** the normal map assigned to the child `Sprite2D` SHALL stay aligned with the diffuse **`Sprite2D.texture`** for that frame
