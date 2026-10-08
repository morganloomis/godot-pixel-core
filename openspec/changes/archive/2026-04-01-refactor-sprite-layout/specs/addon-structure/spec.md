## ADDED Requirements

### Requirement: README documents animated pass layout

`addons/godot-pixel-core/README.md` SHALL describe the animated sprite directory layout: `{animated_root}/{entity}/{action}/` with optional pass files `diffuse.png` (required for an action), `normal.png`, `specular.png`, and `occlusion.png`; SHALL reference optional passes and engine-lit behavior (diffuse + normal in `CanvasTexture`, fallback normal when normal is absent); and SHALL note that `specular`/`occlusion` are loaded when present for forward-compatible use.

#### Scenario: Consumer reads animated layout from README

- **WHEN** a consumer opens `addons/godot-pixel-core/README.md` to author art
- **THEN** they find the pass filenames, directory nesting, and which passes affect stock engine 2D lighting
