class_name Game
extends Node2D

signal return_to_menu_requested

const EnemyDef = preload("res://scripts/resources/EnemyDef.gd")
const HUD = preload("res://scripts/HUD.gd")
const LevelUpPanel = preload("res://scripts/LevelUpPanel.gd")
const PickupXP = preload("res://scripts/PickupXP.gd")
const Player = preload("res://scripts/Player.gd")
const Projectile = preload("res://scripts/Projectile.gd")
const UpgradeDef = preload("res://scripts/resources/UpgradeDef.gd")
const VirtualJoystick = preload("res://scripts/VirtualJoystick.gd")
const WeaponDef = preload("res://scripts/resources/WeaponDef.gd")
const Zombie = preload("res://scripts/Zombie.gd")
const RUN_DURATION_SECONDS: float = 300.0
const RUNNER_UNLOCK_TIME: float = 120.0
const FINAL_WAVE_TIME: float = 285.0
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/Zombie.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")
const PICKUP_XP_SCENE: PackedScene = preload("res://scenes/PickupXP.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/HUD.tscn")
const LEVEL_UP_SCENE: PackedScene = preload("res://scenes/LevelUpPanel.tscn")
const JOYSTICK_SCENE: PackedScene = preload("res://scenes/VirtualJoystick.tscn")
const WEAPON_PISTOL: String = "pistol"
const WEAPON_SHOTGUN: String = "shotgun"
const WEAPON_RIFLE: String = "rifle"
const WEAPON_SHIELD: String = "shield"
const SHIELD_RADIUS: float = 118.0

var player: Player
var hud: HUD
var level_up_panel: LevelUpPanel
var joystick: VirtualJoystick
var shield_ring: Line2D
var weapon_def: WeaponDef = WeaponDef.new()
var walker_def: EnemyDef = EnemyDef.new()
var runner_def: EnemyDef = EnemyDef.new()
var boss_def: EnemyDef = EnemyDef.new()
var upgrade_pool: Array[UpgradeDef] = []
var enemies: Array[Zombie] = []
var active_weapon_ids: Array[String] = [WEAPON_PISTOL]
var weapon_timers: Dictionary = {}
var weapon_levels: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var elapsed_time: float = 0.0
var spawn_timer: float = 0.0
var shield_visual_time: float = 0.0
var player_xp: int = 0
var player_level: int = 1
var required_xp: int = 5
var kill_count: int = 0
var cooldown_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var projectile_bonus: int = 0
var final_wave_started: bool = false
var run_finished: bool = false
var game_mode: String = "timed"
var endless_boss_marker: int = 0
var ground_tile_texture: Texture2D = preload("res://assets/ground_tile.png")

func configure_mode(mode: String) -> void:
    game_mode = "endless" if mode == "endless" else "timed"

func _ready() -> void:
    rng.randomize()
    _configure_enemy_defs()
    _build_upgrade_pool()
    _activate_or_level_weapon(WEAPON_PISTOL)
    _spawn_player()
    _spawn_ui()
    EventBus.run_started.emit()
    queue_redraw()

func _process(delta: float) -> void:
    if hud != null:
        if game_mode == "endless":
            hud.update_timer_elapsed(elapsed_time)
        else:
            hud.update_timer_remaining(RUN_DURATION_SECONDS - elapsed_time)
    _update_shield_visual(delta)

func _physics_process(delta: float) -> void:
    if run_finished:
        return
    elapsed_time += delta
    spawn_timer = maxf(spawn_timer - delta, 0.0)
    _update_weapon_timers(delta)
    _update_spawning()
    _update_active_weapons()
    if game_mode == "timed" and elapsed_time >= RUN_DURATION_SECONDS:
        _finish_run(true)

func _draw() -> void:
    _draw_arena_background()
    _draw_road_markings()
    _draw_cracks()
    _draw_debris()

func _draw_arena_background() -> void:
    var tile_size: float = 32.0
    var area_size: float = 3200.0
    var start: float = -area_size * 0.5
    var tile_color_a: Color = Color(0.045, 0.050, 0.055)
    var tile_color_b: Color = Color(0.060, 0.065, 0.070)
    for x_index: int in range(int(area_size / tile_size)):
        for y_index: int in range(int(area_size / tile_size)):
            var tile_position: Vector2 = Vector2(start + x_index * tile_size, start + y_index * tile_size)
            var color: Color = tile_color_a if (x_index + y_index) % 2 == 0 else tile_color_b
            draw_rect(Rect2(tile_position, Vector2(tile_size, tile_size)), color)
            if ground_tile_texture != null and (x_index + y_index) % 5 == 0:
                draw_texture(ground_tile_texture, tile_position, Color(0.58, 0.60, 0.62, 0.22))

func _draw_road_markings() -> void:
    var area_size: float = 3200.0
    var start: float = -area_size * 0.5
    var line_color: Color = Color(0.12, 0.14, 0.15, 0.45)
    draw_rect(Rect2(Vector2(start, -92.0), Vector2(area_size, 184.0)), Color(0.025, 0.030, 0.032, 0.52))
    for line_index: int in range(int(area_size / 160.0)):
        var line_position: float = start + line_index * 160.0
        draw_line(Vector2(start, line_position), Vector2(area_size * 0.5, line_position + 44.0), line_color, 2.0)
    for dash_index: int in range(int(area_size / 220.0)):
        var dash_x: float = start + dash_index * 220.0
        draw_rect(Rect2(Vector2(dash_x, -6.0), Vector2(92.0, 12.0)), Color(0.48, 0.52, 0.46, 0.28))

func _draw_cracks() -> void:
    var crack_color: Color = Color(0.0, 0.0, 0.0, 0.42)
    var crack_starts: Array[Vector2] = [
        Vector2(-1180.0, -680.0),
        Vector2(-620.0, 340.0),
        Vector2(180.0, -420.0),
        Vector2(760.0, 520.0),
        Vector2(1120.0, -180.0),
    ]
    for start_position: Vector2 in crack_starts:
        var p0: Vector2 = start_position
        var p1: Vector2 = p0 + Vector2(58.0, 18.0)
        var p2: Vector2 = p1 + Vector2(34.0, -42.0)
        var p3: Vector2 = p2 + Vector2(72.0, 26.0)
        draw_polyline(PackedVector2Array([p0, p1, p2, p3]), crack_color, 3.0)
        draw_line(p1, p1 + Vector2(-24.0, 36.0), crack_color, 2.0)

func _draw_debris() -> void:
    var debris_color: Color = Color(0.18, 0.20, 0.19, 0.58)
    var debris_positions: Array[Vector2] = [
        Vector2(-1340.0, 740.0),
        Vector2(-860.0, -220.0),
        Vector2(-120.0, 700.0),
        Vector2(460.0, -760.0),
        Vector2(980.0, 260.0),
        Vector2(1320.0, -560.0),
    ]
    for debris_position: Vector2 in debris_positions:
        draw_rect(Rect2(debris_position, Vector2(20.0, 10.0)), debris_color)
        draw_rect(Rect2(debris_position + Vector2(28.0, 14.0), Vector2(10.0, 18.0)), debris_color.darkened(0.2))

func _configure_enemy_defs() -> void:
    walker_def.id = "walker"
    walker_def.display_name = "Walker"
    walker_def.max_health = 42.0
    walker_def.move_speed = 92.0
    walker_def.touch_damage = 9.0
    walker_def.xp_reward = 10
    walker_def.texture = _load_texture("res://assets/zombie_walker.png")
    walker_def.radius = 15.0

    runner_def.id = "runner"
    runner_def.display_name = "Runner"
    runner_def.max_health = 34.0
    runner_def.move_speed = 138.0
    runner_def.touch_damage = 8.0
    runner_def.xp_reward = 10
    runner_def.texture = _load_texture("res://assets/zombie_runner.png")
    runner_def.radius = 14.0

    boss_def.id = "boss"
    boss_def.display_name = "Brute"
    boss_def.max_health = 680.0
    boss_def.move_speed = 76.0
    boss_def.touch_damage = 18.0
    boss_def.xp_reward = 10
    boss_def.texture = _load_texture("res://assets/boss.png")
    boss_def.radius = 24.0

func _build_upgrade_pool() -> void:
    upgrade_pool = [
        _make_upgrade("fire_rate", "Rapid Fire", "Shoot 18% faster", 0.18),
        _make_upgrade("projectile_count", "Twin Shot", "+1 projectile", 1.0),
        _make_upgrade("damage", "Hollow Point", "+25% damage", 0.25),
        _make_upgrade("unlock_shotgun", "Scrap Shotgun", "Add a stacking cone blast", 1.0),
        _make_upgrade("unlock_rifle", "Auto Rifle", "Add a stacking rapid gun", 1.0),
        _make_upgrade("unlock_shield", "Guardian Shield", "Add a pulsing AoE weapon", 1.0),
        _make_upgrade("move_speed", "Running Shoes", "+22 move speed", 22.0),
        _make_upgrade("max_hp", "Field Medkit", "+22 max HP and heal", 22.0),
        _make_upgrade("regen", "Regeneration", "+8 HP per second", 8.0),
        _make_upgrade("magnet", "Signal Magnet", "+42 XP magnet range", 42.0),
    ]

func _make_upgrade(id: String, title: String, description: String, amount: float) -> UpgradeDef:
    var upgrade: UpgradeDef = UpgradeDef.new()
    upgrade.id = id
    upgrade.title = title
    upgrade.description = description
    upgrade.amount = amount
    return upgrade

func _spawn_player() -> void:
    player = PLAYER_SCENE.instantiate() as Player
    add_child(player)
    player.global_position = Vector2.ZERO
    player.health_changed.connect(_on_player_health_changed)
    player.died.connect(_on_player_died)

    var camera: Camera2D = Camera2D.new()
    camera.zoom = Vector2(1.45, 1.45)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    player.add_child(camera)
    camera.make_current()

func _spawn_ui() -> void:
    hud = HUD_SCENE.instantiate() as HUD
    add_child(hud)
    hud.update_health(player.current_health, player.max_health)
    hud.update_xp(player_xp, required_xp)
    hud.update_level(player_level)
    hud.update_kills(kill_count)
    hud.mode_label.text = "ENDLESS" if game_mode == "endless" else "SURVIVE"
    hud.restart_button.pressed.connect(_restart_run)

    level_up_panel = LEVEL_UP_SCENE.instantiate() as LevelUpPanel
    add_child(level_up_panel)
    level_up_panel.upgrade_selected.connect(_on_upgrade_selected)

    joystick = JOYSTICK_SCENE.instantiate() as VirtualJoystick
    hud.add_child(joystick)
    joystick.anchor_left = 0.0
    joystick.anchor_top = 1.0
    joystick.anchor_right = 0.0
    joystick.anchor_bottom = 1.0
    joystick.offset_left = 34.0
    joystick.offset_top = -250.0
    joystick.offset_right = 210.0
    joystick.offset_bottom = -74.0
    joystick.direction_changed.connect(player.set_joystick_vector)

func _update_spawning() -> void:
    if spawn_timer > 0.0:
        return
    var pressure: float = 1.0 + elapsed_time / 80.0
    var spawn_count: int = clampi(int(2.0 + pressure), 3, 10)
    if game_mode == "endless" and elapsed_time >= FINAL_WAVE_TIME:
        var boss_marker: int = int(floor((elapsed_time - FINAL_WAVE_TIME) / 60.0))
        if boss_marker > endless_boss_marker:
            endless_boss_marker = boss_marker
            _spawn_enemy(boss_def)
    if elapsed_time >= FINAL_WAVE_TIME and not final_wave_started:
        final_wave_started = true
        _spawn_enemy(boss_def)
        spawn_count = 18
    for index: int in range(spawn_count):
        var definition: EnemyDef = runner_def if elapsed_time >= RUNNER_UNLOCK_TIME and rng.randf() < 0.35 else walker_def
        _spawn_enemy(definition)
    spawn_timer = maxf(1.15 - elapsed_time / 420.0, 0.34)

func _spawn_enemy(definition: EnemyDef) -> void:
    var zombie: Zombie = ZOMBIE_SCENE.instantiate() as Zombie
    add_child(zombie)
    zombie.global_position = _random_spawn_position()
    zombie.configure(definition, player)
    zombie.died.connect(_on_enemy_died)
    zombie.touched_player.connect(player.apply_damage)
    enemies.append(zombie)

func _random_spawn_position() -> Vector2:
    var angle: float = rng.randf_range(0.0, TAU)
    var distance: float = rng.randf_range(470.0, 620.0)
    return player.global_position + Vector2.RIGHT.rotated(angle) * distance

func _update_weapon_timers(delta: float) -> void:
    for weapon_id: String in active_weapon_ids:
        var current_timer: float = float(weapon_timers.get(weapon_id, 0.0))
        weapon_timers[weapon_id] = maxf(current_timer - delta, 0.0)

func _update_active_weapons() -> void:
    for weapon_id: String in active_weapon_ids:
        match weapon_id:
            WEAPON_PISTOL:
                _update_pistol_weapon()
            WEAPON_SHOTGUN:
                _update_shotgun_weapon()
            WEAPON_RIFLE:
                _update_rifle_weapon()
            WEAPON_SHIELD:
                _update_shield_weapon()

func _update_pistol_weapon() -> void:
    if not _weapon_ready(WEAPON_PISTOL):
        return
    var target: Zombie = _find_nearest_enemy(weapon_def.base_range)
    if target == null:
        return
    var projectile_count: int = weapon_def.projectile_count + projectile_bonus + _weapon_level_bonus(WEAPON_PISTOL)
    var base_direction: Vector2 = player.global_position.direction_to(target.global_position)
    for index: int in range(projectile_count):
        var spread_offset: float = 0.0
        if projectile_count > 1:
            spread_offset = deg_to_rad(float(index - (projectile_count - 1) / 2.0) * 11.0)
        _shoot_projectile(
            base_direction.rotated(spread_offset),
            weapon_def.base_damage * _weapon_damage_multiplier(WEAPON_PISTOL),
            weapon_def.projectile_speed,
            weapon_def.base_range
        )
    _set_weapon_cooldown(WEAPON_PISTOL, weapon_def.base_cooldown)

func _update_shotgun_weapon() -> void:
    if not _weapon_ready(WEAPON_SHOTGUN):
        return
    var target: Zombie = _find_nearest_enemy(240.0)
    if target == null:
        return
    var pellet_count: int = 5 + projectile_bonus + _weapon_level_bonus(WEAPON_SHOTGUN)
    var base_direction: Vector2 = player.global_position.direction_to(target.global_position)
    var spread_degrees: float = 48.0
    var spread_step: float = spread_degrees / maxf(float(pellet_count - 1), 1.0)
    for index: int in range(pellet_count):
        var pellet_degrees: float = -spread_degrees * 0.5 + spread_step * float(index)
        _shoot_projectile(
            base_direction.rotated(deg_to_rad(pellet_degrees)),
            12.0 * _weapon_damage_multiplier(WEAPON_SHOTGUN),
            520.0,
            225.0
        )
    _set_weapon_cooldown(WEAPON_SHOTGUN, 1.35)

func _update_rifle_weapon() -> void:
    if not _weapon_ready(WEAPON_RIFLE):
        return
    var target: Zombie = _find_nearest_enemy(340.0)
    if target == null:
        return
    var burst_count: int = 1 + projectile_bonus + _weapon_level_bonus(WEAPON_RIFLE)
    var base_direction: Vector2 = player.global_position.direction_to(target.global_position)
    for index: int in range(burst_count):
        var spread_offset: float = deg_to_rad(float(index - (burst_count - 1) / 2.0) * 4.0)
        _shoot_projectile(
            base_direction.rotated(spread_offset),
            9.0 * _weapon_damage_multiplier(WEAPON_RIFLE),
            760.0,
            340.0
        )
    _set_weapon_cooldown(WEAPON_RIFLE, 0.32)

func _update_shield_weapon() -> void:
    if not _weapon_ready(WEAPON_SHIELD):
        return
    var enemy_snapshot: Array[Zombie] = []
    enemy_snapshot.assign(enemies.duplicate())
    for enemy: Zombie in enemy_snapshot:
        if not is_instance_valid(enemy):
            continue
        if player.global_position.distance_to(enemy.global_position) <= SHIELD_RADIUS:
            enemy.apply_damage(16.0 * _weapon_damage_multiplier(WEAPON_SHIELD))
    _set_weapon_cooldown(WEAPON_SHIELD, 0.72)

func _shoot_projectile(direction: Vector2, damage: float, speed: float, shot_range: float) -> void:
    var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
    add_child(projectile)
    projectile.launch(
        player.global_position,
        direction,
        damage,
        speed,
        shot_range
    )

func _find_nearest_enemy(max_distance: float) -> Zombie:
    var best_enemy: Zombie
    var best_distance: float = max_distance
    for enemy: Zombie in enemies:
        if not is_instance_valid(enemy):
            continue
        var distance_to_enemy: float = player.global_position.distance_to(enemy.global_position)
        if distance_to_enemy < best_distance:
            best_distance = distance_to_enemy
            best_enemy = enemy
    return best_enemy

func _weapon_ready(weapon_id: String) -> bool:
    return float(weapon_timers.get(weapon_id, 0.0)) <= 0.0

func _set_weapon_cooldown(weapon_id: String, base_cooldown: float) -> void:
    weapon_timers[weapon_id] = _weapon_cooldown(weapon_id, base_cooldown)

func _weapon_cooldown(weapon_id: String, base_cooldown: float) -> float:
    var level_reduction: float = minf(float(_weapon_level_bonus(weapon_id)) * 0.08, 0.42)
    return base_cooldown * cooldown_multiplier * (1.0 - level_reduction)

func _weapon_damage_multiplier(weapon_id: String) -> float:
    return damage_multiplier * (1.0 + float(_weapon_level_bonus(weapon_id)) * 0.18)

func _weapon_level(weapon_id: String) -> int:
    return int(weapon_levels.get(weapon_id, 1))

func _weapon_level_bonus(weapon_id: String) -> int:
    return max(_weapon_level(weapon_id) - 1, 0)

func _has_weapon(weapon_id: String) -> bool:
    return active_weapon_ids.has(weapon_id)

func _activate_or_level_weapon(weapon_id: String) -> void:
    if not _has_weapon(weapon_id):
        active_weapon_ids.append(weapon_id)
        weapon_timers[weapon_id] = 0.0
        weapon_levels[weapon_id] = 1
    else:
        var current_level: int = int(weapon_levels.get(weapon_id, 0))
        weapon_levels[weapon_id] = max(current_level + 1, 1)
    if weapon_id == WEAPON_SHIELD:
        _ensure_shield_ring()

func _on_enemy_died(zombie: Zombie, xp_amount: int) -> void:
    enemies.erase(zombie)
    kill_count += 1
    hud.update_kills(kill_count)
    EventBus.kill_count_changed.emit(kill_count)
    call_deferred("_spawn_xp_pickup", zombie.global_position, xp_amount)

func _spawn_xp_pickup(drop_position: Vector2, xp_amount: int) -> void:
    var pickup: PickupXP = PICKUP_XP_SCENE.instantiate() as PickupXP
    add_child(pickup)
    pickup.global_position = drop_position
    pickup.amount = xp_amount
    pickup.set_target(player)
    pickup.collected.connect(_on_xp_collected)

func _on_xp_collected(amount: int) -> void:
    player_xp += amount
    while player_xp >= required_xp:
        player_xp -= required_xp
        player_level += 1
        required_xp = int(ceil(float(required_xp) * 1.28 + 3.0))
        hud.update_level(player_level)
        EventBus.player_level_changed.emit(player_level)
        _present_level_up()
    hud.update_xp(player_xp, required_xp)
    EventBus.player_xp_changed.emit(player_xp, required_xp)

func _present_level_up() -> void:
    var choices: Array[UpgradeDef] = _pick_upgrade_choices()
    get_tree().paused = true
    level_up_panel.show_choices(choices)

func _pick_upgrade_choices() -> Array[UpgradeDef]:
    var shuffled: Array[UpgradeDef] = []
    shuffled.assign(upgrade_pool.duplicate())
    shuffled.shuffle()
    var choices: Array[UpgradeDef] = []
    for index: int in range(LevelUpPanel.CHOICE_COUNT):
        choices.append(shuffled[index])
    return choices

func _on_upgrade_selected(upgrade: UpgradeDef) -> void:
    match upgrade.id:
        "fire_rate":
            cooldown_multiplier = maxf(cooldown_multiplier - upgrade.amount, 0.22)
        "projectile_count":
            projectile_bonus += int(upgrade.amount)
        "damage":
            damage_multiplier += upgrade.amount
        "unlock_shotgun":
            _activate_or_level_weapon(WEAPON_SHOTGUN)
        "unlock_rifle":
            _activate_or_level_weapon(WEAPON_RIFLE)
        "unlock_shield":
            _activate_or_level_weapon(WEAPON_SHIELD)
        _:
            player.apply_upgrade(upgrade)
    get_tree().paused = false

func _ensure_shield_ring() -> void:
    if shield_ring != null and is_instance_valid(shield_ring):
        shield_ring.visible = true
        return
    shield_ring = Line2D.new()
    shield_ring.width = 3.0
    shield_ring.default_color = Color(0.40, 0.95, 0.78, 0.68)
    shield_ring.z_index = 20
    shield_ring.points = _make_circle_points(SHIELD_RADIUS, 48)
    player.add_child(shield_ring)

func _make_circle_points(radius: float, segments: int) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array()
    for index: int in range(segments + 1):
        var angle: float = TAU * float(index) / float(segments)
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    return points

func _update_shield_visual(delta: float) -> void:
    if not _has_weapon(WEAPON_SHIELD):
        if shield_ring != null and is_instance_valid(shield_ring):
            shield_ring.visible = false
        return
    if player == null:
        return
    _ensure_shield_ring()
    shield_visual_time += delta * 4.0
    var pulse: float = 1.0 + sin(shield_visual_time) * 0.045
    shield_ring.scale = Vector2(pulse, pulse)
    shield_ring.rotation += delta * 0.45
    shield_ring.default_color = Color(0.40, 0.95, 0.78, 0.48 + absf(sin(shield_visual_time)) * 0.22)

func _on_player_health_changed(current_health: float, max_health: float) -> void:
    if hud != null:
        hud.update_health(current_health, max_health)
    EventBus.player_health_changed.emit(current_health, max_health)

func _on_player_died() -> void:
    _finish_run(false)

func _finish_run(victory: bool) -> void:
    if run_finished:
        return
    run_finished = true
    get_tree().paused = false
    if hud != null:
        hud.show_result(victory)
    EventBus.run_finished.emit(victory)

func _restart_run() -> void:
    return_to_menu_requested.emit()

func _load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        return load(path) as Texture2D
    return null
