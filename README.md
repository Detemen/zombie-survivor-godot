# Zombie Survivor Prototype

Browser-playable Godot 4.x prototype for a short pixel-art zombie survivor run inspired by the auto-attack, one-hand, roguelite upgrade loop of mobile survivor games.

**[▶ Play in browser](https://detemen.github.io/zombie-survivor-godot/)**

## Requirements

- Godot 4.x
- Matching Godot Web export templates
- Python 3 for local static checks and the web server helper

Godot is not bundled in this repository. Install the editor and export templates first, then open this folder as a Godot project.

## Play In Editor

1. Open this folder in Godot 4.x.
2. Run `scenes/Main.tscn`.
3. Use the on-screen joystick, touch/mouse drag, or WASD/arrow keys for debug movement.

## Web Export

1. In Godot, open **Project > Export**.
2. Select the `Web` preset from `export_presets.cfg`.
3. Export to `build/web/index.html`.
4. Serve the folder:

```bash
python3 tools/serve_web.py
```

Then open `http://127.0.0.1:8060`.

Headless export also works after Godot and matching templates are installed:

```bash
godot --headless --path . --export-release Web build/web/index.html
```

Do not open build/web/index.html directly. Godot Web exports must be served over HTTP. The local helper sends the headers Godot Web builds commonly need:

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

## Prototype Scope

- 5-minute arena run
- Auto-targeting pistol weapon
- Walker and runner zombies
- Final wave with miniboss
- XP pickups and 3-choice level-up cards
- HUD for timer, HP, XP, level, kills, win/lose state

Out of scope for v1: equipment, shop, pets, clans, monetization, saves, ads, auth, and copied external assets.
