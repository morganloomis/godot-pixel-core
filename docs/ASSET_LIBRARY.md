# Publishing to the Godot Asset Library

Checklist to make Pixel Core an official addon on the [Godot Asset Library](https://godotengine.org/asset-library/asset).

## Requirements (must have)

- [ ] **Addon works** in the Godot version you declare (e.g. 4.6).
- [ ] **`.gitignore`** – Keep redundant data out of the repo. (You already have one; ensure it’s adequate.)
- [ ] **No required submodules** – Asset Library downloads don’t include submodules. (This repo is used as a submodule by others; that’s fine. Don’t add submodules that the addon depends on.)
- [ ] **License** – Asset Library license must match the repo. Repo must have `LICENSE` or `LICENSE.md` with full text and copyright (year + holder). (You have MIT in `LICENSE`.)
- [ ] **Name and description** – Proper English, capitalization, full sentences.
- [ ] **Icon URL** – Direct link to image (e.g. for GitHub use `raw.githubusercontent.com`). Image must be square, min 128×128 px (PNG or JPG).

## Recommended

- [x] **Single addon folder** – Use `addons/godot-pixel-core/` for all addon content (matches your proposal). Move `addons/entity/` and `addons/sprite_sheet/` under `addons/godot-pixel-core/` so installs don’t clash with other assets.
- [ ] **Fix or suppress script warnings** in addon scripts.
- [ ] **Follow [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).**
- [ ] **Screenshots** – If you add screenshots in the repo, put them in a subfolder with an empty `.gdignore` so Godot doesn’t import them.
- [ ] **`.gitattributes`** – Use `export-ignore` so the Asset Library download ZIP excludes `test/`, `openspec/`, `.cursor/`, and other non-addon files. (See repo root `.gitattributes`.)
- [x] **License + README in addon folder** – `LICENSE` and `README.md` are in `addons/godot-pixel-core/` so users who only keep that folder still have them.

## Sprite sheets (Pixel Core addon)

For an at-a-glance picture of the addon's `class_name` set, see the **"Class overview"** section of `addons/godot-pixel-core/README.md` (Mermaid chart + prose).

For **animated** character sheets consumed by `AnimatedSpriteSheetLookup`:

- Per-pass files live under `{animated_sheet_root}/{entity}/{action}/{pass}.png`, where `{pass}` is one of `diffuse`, `normal`, `specular`, or `occlusion`.
- `diffuse.png` is required for a valid action; `normal.png`, `specular.png`, and `occlusion.png` are optional and SHALL share the diffuse grid (**8 direction rows** S, SE, E, NE, N, NW, W, SW × **N frame columns**).
- See `addons/godot-pixel-core/README.md` for the full pass table, the normal RGB convention, and engine 2D lighting guidance.

**Static** lit sprites with per-pass files are **not implemented yet**. There is deliberately no half-diffuse / half-normal single-PNG layout; when static lit sprites land they will follow the same per-pass conventions as animated sheets.

## Repo structure for Asset Library

- **Download** = archive of the repo at the chosen commit. With `.gitattributes` `export-ignore`, the ZIP will exclude development-only paths.
- **Addon path** = `addons/godot-pixel-core/`. Godot and users expect the addon to live under one `addons/<name>/` folder.
- **plugin.cfg** = Not required. This is a script-only addon using `class_name`; no EditorPlugin. Add `plugin.cfg` only if you later introduce editor tools.

## Submission form (when you submit)

You’ll need:

| Field | Example / note |
|-------|------------------|
| **Asset name** | e.g. “Pixel Core” |
| **Category** | Addons → pick best fit (e.g. 2D Tools, Scripts) |
| **Godot version** | e.g. 4.6 |
| **Version** | e.g. 0.1.0 (SemVer recommended) |
| **Repository host** | GitHub / GitLab / etc. |
| **Repository URL** | Your repo URL |
| **Issues URL** | e.g. `https://github.com/.../issues` (optional if same repo) |
| **Download commit** | Full commit hash to ship (e.g. from `git rev-parse HEAD`) |
| **Icon URL** | Direct link to square icon, min 128×128 (use `raw.githubusercontent.com` if on GitHub) |
| **License** | MIT (must match `LICENSE` file) |
| **Description** | Plain text overview, features, how to use |

You can also add up to 3 image/video previews.

## After submitting

- Review is manual; can take a few days.
- You’ll be notified of accept/reject; if rejected, you can fix and resubmit.
