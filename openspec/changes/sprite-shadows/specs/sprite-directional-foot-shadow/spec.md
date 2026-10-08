# Spec Delta: sprite-directional-foot-shadow

## ADDED Requirements

### Requirement: Directional smear from contact mask

The addon SHALL provide a **runtime foot contact shadow** that samples the **contact atlas** and computes a **soft shadow intensity** by integrating samples along a **2D smear direction** in UV space. The smear direction SHALL correspond to **incoming light projected onto the ground plane**, then expressed as a **unit `Vector2` in canvas space** (`smear_dir`) supplied to the shader or material. The implementation SHALL use a **fixed maximum tap count** of **16 or fewer** along the smear (exact count documented in addon usage).

#### Scenario: Smear follows smear_dir uniform

- **WHEN** `smear_dir` is updated at runtime (e.g. rotating the logical sun)
- **THEN** the elongated shadow on the ground SHALL reorient to match the new direction without requiring a scene reload

#### Scenario: Tap count is bounded

- **WHEN** the foot shadow shader executes
- **THEN** the number of texture samples along the smear axis SHALL NOT exceed **16** per fragment for the default path

---

### Requirement: Visual intent and exclusions

The foot shadow SHALL emphasize **contact-accurate** intensity **near planted feet** and **soft falloff** along the smear. It SHALL **NOT** be required to reproduce a **crisp full-body silhouette** or **occlusion-accurate** cast shadows from the entire character mesh.

#### Scenario: Soft appearance is acceptable

- **WHEN** a character’s limbs move away from the feet
- **THEN** the shadow MAY omit or fade detail outside the contact mask **AND** SHALL remain visually soft rather than a hard body outline

---

### Requirement: Drawing order and ground composite

The shadow SHALL be rendered using a **dedicated CanvasItem** (e.g. `Sprite2D` or agreed equivalent) that draws **behind** the character sprite in scene order (or an equivalent documented layering mechanism such as z-index or canvas layer). The output SHALL **darken** the visible ground using **multiplicative** or **alpha-blended darkening** against what is behind the shadow quad, with **tunable** strength via shader parameters or material properties.

#### Scenario: Character draws on top of its foot shadow

- **WHEN** the player character and foot shadow are visible
- **THEN** the character’s diffuse sprite SHALL occlude the shadow quad where they overlap **AND** the ground SHALL appear darker only where the shadow quad covers it

---

### Requirement: Primary directional light policy

For **version 1** of this capability, **one** primary directional **smear direction** and **one** primary **shadow strength** (or color/scalar) SHALL drive the foot shadow. **Additional** directional or point lights SHALL **NOT** spawn separate independent smears in the same pass. (Games MAY approximate multiple lights by updating the primary vector/strength each frame.)

#### Scenario: Single smear vector at a time

- **WHEN** the scene contains more than one conceptual light
- **THEN** the foot shadow implementation SHALL still use **at most one** `smear_dir` and one primary strength input for the smear pass

---

### Requirement: Performance expectations

The **default** implementation SHALL **not** require an intermediate **render target** or **viewport** for foot shadows. Optional future paths MAY add a blur pass; if present, they SHALL be documented separately and SHALL remain **optional**.

#### Scenario: Default path is shader-only

- **WHEN** foot shadows are enabled with default settings
- **THEN** rendering SHALL complete without allocating a per-character `SubViewport` **unless** explicitly documented as an optional mode

---

### Requirement: Light-to-ground mapping documentation

The addon SHALL document how consumers obtain `smear_dir` from their **world light direction** and **ground plane normal** (e.g. projection onto the plane, then mapping to canvas axes). The documented convention SHALL name whether `smear_dir` points **toward** or **away from** the projected light azimuth so sampling direction is unambiguous.

#### Scenario: Developer can configure isometric sun

- **WHEN** a game author reads the addon documentation for foot shadows
- **THEN** they SHALL be able to set `smear_dir` consistently with their isometric floor and chosen sun direction
