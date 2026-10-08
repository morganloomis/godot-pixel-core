# Spec delta: character-entity (change: entity-refactor)

## MODIFIED Requirements

### Requirement: Display via animated-entity

The character entity SHALL use the addon’s **animated sprite presenter** (`AnimatedEntity` or renamed successor with the same responsibility) for sprite-sheet display, action, and direction. It SHALL NOT reimplement sprite-sheet resolution or frame-advance logic; that SHALL remain in the presenter. The character entity SHALL hold a reference to a presenter instance (e.g. as a child node) and SHALL drive or allow driving of that instance’s action and direction so the correct frames are displayed. **Pseudo-lighting** SHALL be configured on that presenter (e.g. via export) rather than by requiring a separate lit-only presenter subclass in packaged default scenes.

#### Scenario: Display is delegated to presenter

- **WHEN** the character entity is composed with a child (or referenced) presenter instance (`AnimatedEntity` or documented successor)
- **THEN** the visible sprite and frame advance SHALL be determined by that presenter; the character entity SHALL NOT duplicate texture lookup, timer-based frame advance, or playback mode logic

#### Scenario: Action and direction can be driven for the character

- **WHEN** the character entity or a caller sets the presenter child’s action or direction (e.g. idle vs walk, facing direction)
- **THEN** the displayed texture SHALL update according to the presenter’s lookup and current frame; the character entity SHALL expose or forward a way to set action and direction (e.g. by exposing the child reference or providing set_action/set_direction helpers)

#### Scenario: Lit mode without alternate presenter class

- **WHEN** a game author enables pseudo-lighting on the child presenter
- **THEN** the character entity SHALL NOT require swapping to a different presenter script class solely to obtain lit behavior in the addon’s standard packaged layout
