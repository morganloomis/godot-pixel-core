## 1. Layout constants and path configuration

- [x] 1.1 Define direction order constant (N=0, NE, E, SE, S, SW, W, NW) and name-to-index mapping in addon
- [x] 1.2 Add configurable or documented animated-sheet root and static-sheet root paths (e.g. res://sprite/animated/, res://sprite/static/)

## 2. Base sprite sheet lookup class

- [x] 2.1 Create base class that loads Texture2D from path and caches by path/key; expose method to get cached texture for a key
- [x] 2.2 Add base logic to compute Rect2 for a cell from sheet size, layout type (animated vs static), and cell/block parameters
- [x] 2.3 Add method to create AtlasTexture (or equivalent) from cached sheet texture and Rect2 region

## 3. Animated layout and subclass

- [x] 3.1 Implement animated layout math: given image size and frame count, compute block height (H/2), cell width (W/F), cell height per block ((H/2)/8)
- [x] 3.2 Implement region calculation for animated sheet: (direction_index, frame_index, diffuse_or_normal) → Rect2
- [x] 3.3 Create animated subclass: get_texture(entity, action, direction, frame, type=diffuse|normal) returning AtlasTexture; accept direction as name or 0–7 index
- [x] 3.4 Add get_frame_count(entity, action) returning number of frames from loaded sheet or metadata

## 4. Static layout and subclass

- [x] 4.1 Implement static grid layout math: given image size and cell size (or derived), compute columns and rows
- [x] 4.2 Implement region calculation for static sheet: (row, col) or linear index → Rect2 (row-major)
- [x] 4.3 Create static subclass: get_texture(sheet_id, index) and get_texture(sheet_id, row, col) returning AtlasTexture

## 5. Character integration

- [x] 5.1 Replace character preload/cache and update_sprite() to use animated lookup for (entity, action, direction, frame)
- [x] 5.2 Obtain animation frame count from lookup get_frame_count() instead of hardcoded value
