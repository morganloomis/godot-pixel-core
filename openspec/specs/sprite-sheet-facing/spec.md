# Spec: Sprite sheet facing

## Purpose

Define the canonical compass order for animated sprite sheet rows and align player-facing direction strings with that order.

## Requirements

### Requirement: Animated sheet row order matches compass directions

The addon SHALL interpret rows of an animated sprite sheet (within each 8-row block: diffuse and normal) as eight facings in this exact top-to-bottom order: **S**, **SE**, **E**, **NE**, **N**, **NW**, **W**, **SW**. Row index 0 SHALL correspond to **S**; index 7 SHALL correspond to **SW**. This order SHALL be described as starting at south and proceeding counter-clockwise around the compass.

#### Scenario: Direction name maps to row index

- **WHEN** a direction string `S`, `SE`, `E`, `NE`, `N`, `NW`, `W`, or `SW` is passed to animated sheet lookup
- **THEN** the selected atlas region SHALL be taken from the row matching that direction’s position in the canonical order above (within the correct diffuse or normal block)

#### Scenario: Integer direction index maps to the same row

- **WHEN** an integer direction index 0–7 is passed to animated sheet lookup
- **THEN** index `i` SHALL select the same row as the `i`th entry in the canonical order **S** through **SW**

### Requirement: Player movement facing uses the same direction names

Code that derives an entity facing from player input (e.g. `PlayerEntity`) SHALL assign direction strings only from the canonical set **S**, **SE**, **E**, **NE**, **N**, **NW**, **W**, **SW**, and those strings SHALL match the animated sheet row semantics in this change.

#### Scenario: Cardinal and diagonal input selects consistent facings

- **WHEN** the player provides a non-zero movement vector along each of the eight compass directions (cardinals and diagonals)
- **THEN** the entity direction string SHALL match that compass direction’s label in the canonical set and SHALL display the row defined for that label
