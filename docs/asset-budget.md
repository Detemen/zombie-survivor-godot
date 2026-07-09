# Pixel Asset Budget

Target: Godot 4 web/mobile dark arcade prototype with nearest-neighbor pixel art.

## Source Assets

| Asset | Size | Alpha | Notes |
| --- | ---: | --- | --- |
| `assets/player.png` | 32x32 | Yes | Survivor sprite, single draw call. |
| `assets/zombie_walker.png` | 32x32 | Yes | Green slow enemy, readable at 2x-4x scale. |
| `assets/zombie_runner.png` | 32x32 | Yes | Warmer infected palette for fast enemy contrast. |
| `assets/projectile.png` | 16x16 | Yes | Small cyan/yellow bolt. Keep overdraw low. |
| `assets/xp_gem.png` | 16x16 | Yes | Cyan/green pickup with high contrast. |
| `assets/ground_tile.png` | 32x32 | No | Dark asphalt tile; repeat with filtering off. |
| `assets/boss.png` | 48x48 | Yes | Miniboss silhouette, larger texture budget. |

## Runtime Budget

- Keep sprite textures at source size; scale in Godot using integer multiples where possible.
- Target one material per sprite category and avoid per-instance shader variants for web.
- Keep simultaneous transparent sprites modest on mobile: hundreds are fine, but avoid large alpha glows.
- Prefer CPU-light animation: flipbooks or simple transform motion before shader effects.
- Atlas later if the prototype grows beyond these standalone files.

## Godot Import Notes

- Import as `Texture2D`.
- Disable filtering for all pixel-art sprites and tiles.
- Disable mipmaps for character, projectile, and pickup sprites.
- Disable repeat for actors/projectiles/pickups; enable repeat only for `ground_tile.png` if used as a tiled texture.
- Use lossless PNG source and Godot's VRAM compression only after checking Web export appearance.
- Keep transparent sprites padded and snapped to whole pixels to avoid shimmer on mobile browsers.
