from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class ProjectContractTests(unittest.TestCase):
    def test_godot_project_and_web_export_are_declared(self) -> None:
        project = read("project.godot")
        exports = read("export_presets.cfg")

        self.assertIn('config/name="Zombie Survivor Prototype"', project)
        self.assertIn('run/main_scene="res://scenes/Main.tscn"', project)
        self.assertIn('config/features=PackedStringArray("4.3", "Forward Plus")', project)
        self.assertIn("gdscript/warnings/enable_all_warnings=true", project)
        self.assertIn('platform="Web"', exports)
        self.assertIn('export_path="build/web/index.html"', exports)

    def test_required_scene_and_script_files_exist(self) -> None:
        required_paths = [
            "scenes/Main.tscn",
            "scenes/WelcomeScreen.tscn",
            "scenes/Game.tscn",
            "scenes/Player.tscn",
            "scenes/Zombie.tscn",
            "scenes/Projectile.tscn",
            "scenes/PickupXP.tscn",
            "scripts/WelcomeScreen.gd",
            "scripts/Game.gd",
            "scripts/Player.gd",
            "scripts/Zombie.gd",
            "scripts/Projectile.gd",
            "scripts/PickupXP.gd",
            "scripts/VirtualJoystick.gd",
            "scripts/HUD.gd",
            "scripts/LevelUpPanel.gd",
            "scripts/resources/WeaponDef.gd",
            "scripts/resources/EnemyDef.gd",
            "scripts/resources/UpgradeDef.gd",
        ]

        for path in required_paths:
            self.assertTrue((ROOT / path).is_file(), f"Missing {path}")

    def test_core_gameplay_defaults_are_encoded(self) -> None:
        game = read("scripts/Game.gd")
        player = read("scripts/Player.gd")
        weapon = read("scripts/resources/WeaponDef.gd")

        self.assertIn("RUN_DURATION_SECONDS: float = 300.0", game)
        self.assertIn("RUNNER_UNLOCK_TIME: float = 120.0", game)
        self.assertIn("FINAL_WAVE_TIME: float = 285.0", game)
        self.assertIn("base_cooldown: float = 0.7", weapon)
        self.assertIn("base_range: float = 260.0", weapon)
        self.assertIn("projectile_count: int = 1", weapon)
        self.assertIn("xp_magnet_radius: float = 72.0", player)
        self.assertIn("debug_keyboard_vector", player)
        self.assertIn("max_health: float = 5000.0", player)
        self.assertIn("current_health: float = 5000.0", player)

    def test_xp_spheres_award_ten_experience(self) -> None:
        game = read("scripts/Game.gd")
        pickup = read("scripts/PickupXP.gd")
        enemy_def = read("scripts/resources/EnemyDef.gd")

        self.assertIn("@export var amount: int = 10", pickup)
        self.assertIn("@export var xp_reward: int = 10", enemy_def)
        self.assertIn("walker_def.xp_reward = 10", game)
        self.assertIn("runner_def.xp_reward = 10", game)
        self.assertIn("boss_def.xp_reward = 10", game)

    def test_stacking_weapons_and_global_buffs_are_supported(self) -> None:
        game = read("scripts/Game.gd")

        for weapon_id in [
            "WEAPON_PISTOL",
            "WEAPON_SHOTGUN",
            "WEAPON_RIFLE",
            "WEAPON_SHIELD",
        ]:
            self.assertIn(weapon_id, game)

        for upgrade_id in ["unlock_shotgun", "unlock_rifle", "unlock_shield", "regen"]:
            self.assertIn(f'"{upgrade_id}"', game)

        self.assertIn('active_weapon_ids: Array[String] = [WEAPON_PISTOL]', game)
        self.assertIn("weapon_timers: Dictionary = {}", game)
        self.assertIn("weapon_levels: Dictionary = {}", game)
        self.assertIn("_update_active_weapons", game)
        self.assertIn("_update_pistol_weapon", game)
        self.assertIn("_update_shotgun_weapon", game)
        self.assertIn("_update_rifle_weapon", game)
        self.assertIn("_update_shield_weapon", game)
        self.assertIn("_activate_or_level_weapon", game)
        self.assertIn("_weapon_cooldown", game)
        self.assertIn("cooldown_multiplier", game)
        self.assertIn("damage_multiplier", game)
        self.assertIn("projectile_bonus", game)
        self.assertIn("damage_multiplier", game[game.index("func _update_shield_weapon"):])

    def test_player_has_regeneration_upgrade(self) -> None:
        player = read("scripts/Player.gd")

        self.assertIn("health_regen_per_second: float", player)
        self.assertIn("_apply_regeneration", player)
        self.assertIn("func heal(amount: float) -> void:", player)
        self.assertIn('"regen"', player)

    def test_level_up_pool_has_six_expected_upgrades_and_three_choices(self) -> None:
        game = read("scripts/Game.gd")
        panel = read("scripts/LevelUpPanel.gd")

        for upgrade_id in [
            "fire_rate",
            "projectile_count",
            "damage",
            "move_speed",
            "max_hp",
            "magnet",
        ]:
            self.assertIn(f'"{upgrade_id}"', game)

        self.assertIn("CHOICE_COUNT: int = 3", panel)
        self.assertIn("upgrade_selected", panel)
        self.assertIn("get_tree().paused = true", game)
        self.assertIn("get_tree().paused = false", game)

    def test_scripts_use_typed_gdscript_and_snake_case_signals(self) -> None:
        scripts = list((ROOT / "scripts").rglob("*.gd"))
        self.assertTrue(scripts, "No GDScript files found")

        signal_pattern = re.compile(r"^signal\s+([A-Za-z0-9_]+)", re.MULTILINE)
        untyped_var_pattern = re.compile(r"^\s*var\s+\w+\s*(?:=|$)", re.MULTILINE)

        for script_path in scripts:
            text = script_path.read_text(encoding="utf-8")
            self.assertIn("extends ", text, f"{script_path} does not declare an extends type")
            self.assertFalse(
                untyped_var_pattern.search(text),
                f"{script_path} contains untyped var declarations",
            )
            for signal_name in signal_pattern.findall(text):
                self.assertEqual(
                    signal_name,
                    signal_name.lower(),
                    f"{script_path} signal {signal_name} is not snake_case",
                )

    def test_readme_documents_local_web_serving_and_godot_prerequisite(self) -> None:
        readme = read("README.md")

        self.assertIn("Godot 4.x", readme)
        self.assertIn("Web export templates", readme)
        self.assertIn("python3 tools/serve_web.py", readme)
        self.assertIn("Do not open build/web/index.html directly", readme)
        self.assertIn("Cross-Origin-Opener-Policy", readme)
        self.assertIn("Cross-Origin-Embedder-Policy", readme)

    def test_hud_script_node_paths_match_scene_tree(self) -> None:
        hud = read("scripts/HUD.gd")
        scene = read("scenes/HUD.tscn")

        self.assertIn('parent="Root/Center/VBox"', scene)
        self.assertIn("$Root/Center/VBox/ResultLabel", hud)
        self.assertIn("$Root/Center/VBox/RestartButton", hud)

    def test_reviewer_regressions_are_guarded(self) -> None:
        player = read("scripts/Player.gd")
        game = read("scripts/Game.gd")
        server = read("tools/serve_web.py")

        self.assertIn("is_dead: bool = false", player)
        self.assertIn("if current_health <= 0.0 or is_dead:", player)
        self.assertIn("is_dead = true", player)
        self.assertNotIn("Vector2(34.0, 1030.0)", game)
        self.assertIn("anchor_bottom = 1.0", game)
        self.assertIn('WEB_ROOT / "index.html"', server)
        self.assertIn("raise SystemExit", server)
        self.assertIn("partial(GodotWebHandler", server)
        self.assertNotIn("os.chdir", server)

    def test_physics_callbacks_use_deferred_free(self) -> None:
        for script_path in ["scripts/Projectile.gd", "scripts/PickupXP.gd", "scripts/Zombie.gd"]:
            script = read(script_path)
            self.assertIn('call_deferred("queue_free")', script, script_path)
            self.assertNotIn("\n        queue_free()", script, script_path)

    def test_welcome_screen_exposes_mode_selection(self) -> None:
        main = read("scripts/Main.gd")
        welcome_script = read("scripts/WelcomeScreen.gd")
        welcome_scene = read("scenes/WelcomeScreen.tscn")

        self.assertIn('WELCOME_SCENE: PackedScene = preload("res://scenes/WelcomeScreen.tscn")', main)
        self.assertIn("show_welcome_screen", main)
        self.assertIn("start_requested(mode: String)", welcome_script)
        self.assertIn('"timed"', welcome_script)
        self.assertIn('"endless"', welcome_script)
        self.assertIn('text = "5:00 Run"', welcome_scene)
        self.assertIn('text = "Endless"', welcome_scene)
        self.assertIn("mode_label", read("scripts/Game.gd"))

    def test_endless_mode_has_count_up_timer_and_no_time_victory(self) -> None:
        game = read("scripts/Game.gd")
        hud = read("scripts/HUD.gd")

        self.assertIn('game_mode: String = "timed"', game)
        self.assertIn('func configure_mode(mode: String) -> void:', game)
        self.assertIn('game_mode == "endless"', game)
        self.assertIn("update_timer_elapsed", hud)
        self.assertIn("update_timer_remaining", hud)
        self.assertIn("ENDLESS", game)
        self.assertIn("SURVIVE", game)
        self.assertIn('if game_mode == "timed" and elapsed_time >= RUN_DURATION_SECONDS:', game)

    def test_arena_background_uses_ruined_street_details(self) -> None:
        game = read("scripts/Game.gd")

        self.assertIn("_draw_arena_background", game)
        self.assertIn("_draw_road_markings", game)
        self.assertIn("_draw_cracks", game)
        self.assertIn("_draw_debris", game)
        self.assertIn("ground_tile_texture", game)
        self.assertIn('res://assets/ground_tile.png', game)

    def test_player_and_zombie_have_code_driven_movement_animation(self) -> None:
        player = read("scripts/Player.gd")
        zombie = read("scripts/Zombie.gd")

        for text in [player, zombie]:
            self.assertIn("animation_time: float", text)
            self.assertIn("_update_motion_animation", text)
            self.assertIn("sprite.position.y", text)
            self.assertIn("sprite.scale", text)
            self.assertIn("sprite.rotation", text)


if __name__ == "__main__":
    unittest.main()
