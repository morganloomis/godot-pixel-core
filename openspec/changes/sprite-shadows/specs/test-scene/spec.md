# Spec Delta: test-scene

## ADDED Requirements

### Requirement: Directional foot contact shadow in the test scene

The test scene SHALL **configure** the addon’s **directional foot contact shadow** for the player character (via instanced addon scene, subclass, export toggles, or documented API—exact wiring in implementation). Existing requirements for `PlayerEntity` movement, idle/walk behavior, and lookup path configuration SHALL remain satisfied. If optional `*_contact.png` assets are absent for test actions, the scene SHALL still run **without errors** and MAY show no foot shadow.

#### Scenario: Test scene runs with shadow wiring

- **WHEN** the project is run with `test/test_scene.tscn` as the main scene
- **THEN** the `PlayerEntity` SHALL remain visible and controllable **AND** foot shadow nodes or materials SHALL be present and configured per addon documentation

#### Scenario: Shadow responds when contact art exists

- **WHEN** `walk_contact.png` and `idle_contact.png` exist under `test/art/sprite/player/` with the correct layout relative to `walk.png` / `idle.png`
- **THEN** a human observer SHALL see a **soft, directional** foot contact shadow on the ground that updates with animation and with runtime changes to the documented shadow direction or strength parameters

#### Scenario: Optional contact assets

- **WHEN** `*_contact.png` files are missing for test actions
- **THEN** the test scene SHALL still load and play **AND** SHALL NOT fail on missing contact files

---

### Requirement: Test scene defers to addon for foot shadows

The test scene SHALL NOT reimplement contact rect computation, smear sampling, or light projection math; it SHALL only **wire** parameters and assets that the addon owns.

#### Scenario: Foot shadow math lives in the addon

- **WHEN** the test scene implementation is reviewed for foot shadows
- **THEN** sampling and smear logic SHALL reside under `addons/godot-pixel-core/` **AND** `test/` SHALL contain only configuration and demo inputs

---

## REMOVED Requirements

### Requirement: No addon code changes

**Reason**: Implementing directional foot contact shadows requires code, shaders, and possibly new scenes under `addons/godot-pixel-core/`. The test scene must demonstrate those addon features.

**Migration**: Use **Requirement: Test scene defers to addon for foot shadows** for constraints on how the test scene interacts with the addon.
