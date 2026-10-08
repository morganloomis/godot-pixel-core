# Spec Delta: sprite-pseudo-lighting

## ADDED Requirements

### Requirement: Ambient term ignores normals

The pseudo-lighting model SHALL apply an **ambient** term that scales the diffuse albedo by a configurable color and/or scalar intensity. The ambient term SHALL NOT sample or depend on the normal map.

#### Scenario: Ambient boosts flat areas

- **WHEN** ambient intensity is increased while directional and point contributions are zero
- **THEN** the lit sprite SHALL brighten uniformly across pixels regardless of normal variation

---

### Requirement: Global directional scene light uses normals

The model SHALL apply a **global directional / scene light** term proportional to a Lambert-style shading factor (e.g. `max(0, N·L)` or project-defined equivalent) using the normal map and a normalized light direction in the project’s fixed 2D lighting basis. The directional term SHALL be scaled by a configurable intensity (and optional color) that MAY change at runtime.

#### Scenario: Directional darkens opposing normals

- **WHEN** the global light direction is fixed and directional intensity is positive
- **THEN** pixels whose normals face away from that direction SHALL receive less directional contribution than those facing toward it

---

### Requirement: Runtime updates for global and ambient parameters

The ambient parameters and the global directional parameters (direction and intensity, and color if exposed) SHALL be readable and writable at runtime from game code (e.g. autoload, resource, or documented API). Updates SHALL take effect without requiring editor rebake or scene reload.

#### Scenario: Time-of-day style tweak

- **WHEN** game logic changes directional intensity or direction each frame
- **THEN** lit sprites SHALL reflect the updated values on subsequent draws

---

### Requirement: Point lights with capped count and dynamic transforms

The model SHALL support zero or more **point lights** up to a **documented maximum** count enforced by the implementation. Each active light SHALL have at least: position in the project’s agreed 2D space (see design), radius or falloff distance, color, and intensity. Positions and intensities (and other exposed fields) SHALL be updatable at runtime. Contributions SHALL use the normal map in a Lambert-style term and SHALL attenuate with distance. Lights beyond the maximum SHALL be ignored or clamped as documented.

#### Scenario: Moving point light

- **WHEN** a point light’s position is changed during gameplay
- **THEN** shading on lit sprites SHALL respond on subsequent draws without reloading the scene

#### Scenario: Cap enforced

- **WHEN** more than the maximum supported point lights are provided
- **THEN** the implementation SHALL document and apply a deterministic rule (reject extras, clamp, or priority) that keeps shader arrays within limits

---

### Requirement: No correctness requirement for sprite node rotation

Correct pseudo-lighting behavior (normal basis vs light directions) SHALL NOT be required when `Sprite2D` or ancestors apply non-identity **rotation** for presentation. Character facing SHALL remain expressible via sheet direction rows; lighting basis is fixed per project conventions.

#### Scenario: Identity rotation is the supported case

- **WHEN** lit pseudo-lighting is used as documented for pixel entities without rotating the sprite node for facing
- **THEN** directional and point lighting SHALL behave per spec; rotated nodes are outside the guarantee unless explicitly documented later

---

### Requirement: Pixel-perfect 2D presentation

Lit rendering SHALL remain appropriate for **pixel-perfect 2D**: sampling and filtering SHALL default to or support **nearest-neighbor** where the addon controls it, and the shading model SHALL avoid physically based multi-lobe material features (specular/roughness stacks, HDR expectations). Visual goal is readable, stylized 2D—not a 3D PBR look.

#### Scenario: Nearest sampling available for lit sprites

- **WHEN** a consumer enables the addon’s lit sprite path for pixel art textures
- **THEN** the implementation SHALL document how to keep diffuse and normal sampling consistent with integer-scaled pixel rendering

---

### Requirement: Documented runtime API for lighting

Game code SHALL configure pseudo-lighting through a **documented** addon surface (e.g. autoload singleton, resource, or node API) that exposes ambient, global directional, and the bounded point-light list or parameters. Consumers SHALL not need to edit shader source to set typical gameplay values.

#### Scenario: External script drives lights

- **WHEN** a game script sets ambient color, sun direction, and a point light position using the documented API
- **THEN** those values SHALL affect lit sprites without modifying `.gdshader` files
