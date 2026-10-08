# Spec delta: animated-entity-speed (change: entity-refactor)

## ADDED Requirements

### Requirement: Presenter exports pseudo-lighting configuration

`AnimatedEntity` (or the renamed successor presenter type) SHALL expose an **editor-visible** configuration (e.g. `@export`) that enables **pseudo-lighting** for the child `Sprite2D`. When enabled, the presenter SHALL apply the addon’s lit material and normal-map binding behavior; when disabled, the presenter SHALL behave as an unlit sprite-sheet display without requiring a separate public subclass for lit mode.

#### Scenario: Inspector shows pseudo-lighting option

- **WHEN** the presenter node is selected in the editor
- **THEN** the inspector SHALL include an exported property (or equivalent) to enable or disable pseudo-lighting that persists on the scene

#### Scenario: Runtime toggling does not require subclass swap

- **WHEN** game code or scene configuration enables pseudo-lighting on the presenter
- **THEN** the implementation SHALL NOT require loading a different `class_name` solely to obtain lit behavior
