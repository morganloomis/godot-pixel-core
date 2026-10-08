# Spec Delta: test-scene

## REMOVED Requirements

### Requirement: No addon code changes

**Reason**: Coordinated feature work (e.g. lighting refactor) legitimately edits `addons/godot-pixel-core/`. The test scene must still avoid reimplementing addon responsibilities in `test/`.

**Migration**: Use **Requirement: Test harness does not fork addon core** below.

---

## ADDED Requirements

### Requirement: Test harness does not fork addon core

The test scene SHALL exercise the addon through scene structure and configuration (including root scripts that set lookup paths or exports). Code under **`test/`** SHALL NOT implement parallel sprite lookup, animation, or **lighting** systems that replace or duplicate the addon’s documented behavior.

#### Scenario: No shadow lighting stack in test scripts

- **WHEN** scripts under `test/` are reviewed alongside the lighting refactor
- **THEN** they SHALL not introduce a second, test-only lighting implementation meant to supersede the addon’s engine-lit path

---

### Requirement: Engine 2D lighting demonstrator

The test scene SHALL include at least one **`DirectionalLight2D`** or **`PointLight2D`** (or both) positioned so a **lit-mode** presenter using test assets is visibly affected by Godot’s 2D lighting. The scene SHALL enable the presenter’s lit mode on **`PlayerEntity`**’s child `AnimatedEntity` (or a documented equivalent lit subject) so diffuse and normal data from `res://test/art/sprite/girl/` participate in shading.

#### Scenario: Lit presenter responds to scene lights

- **WHEN** the test scene runs
- **THEN** at least one 2D light node SHALL be present and the lit presenter SHALL show shading attributable to engine 2D lighting (not merely flat albedo with lights ignored)

#### Scenario: Walk and idle still resolve test assets when lit

- **WHEN** the player moves or idles with lit mode enabled on the test `AnimatedEntity`
- **THEN** textures SHALL still resolve per **Requirement: Lookup configured for test assets** and normals SHALL stay aligned with diffuse for each frame
