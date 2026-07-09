class_name Player
extends CharacterBody2D

const UpgradeDef = preload("res://scripts/resources/UpgradeDef.gd")

signal died
signal health_changed(current_health: float, max_health: float)

@export var move_speed: float = 210.0
@export var max_health: float = 5000.0
@export var xp_magnet_radius: float = 72.0

var current_health: float = 5000.0
var health_regen_per_second: float = 0.0
var input_vector: Vector2 = Vector2.ZERO
var debug_keyboard_vector: Vector2 = Vector2.ZERO
var is_dead: bool = false
var animation_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    current_health = max_health
    health_changed.emit(current_health, max_health)

func set_joystick_vector(value: Vector2) -> void:
    input_vector = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
    _apply_regeneration(delta)
    debug_keyboard_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var movement_vector: Vector2 = input_vector
    if debug_keyboard_vector.length_squared() > 0.0:
        movement_vector = debug_keyboard_vector
    velocity = movement_vector.limit_length(1.0) * move_speed
    move_and_slide()
    if movement_vector.x != 0.0:
        sprite.flip_h = movement_vector.x < 0.0
    _update_motion_animation(movement_vector, delta)

func _update_motion_animation(movement_vector: Vector2, delta: float) -> void:
    if movement_vector.length_squared() > 0.01:
        animation_time += delta * 12.0
        var bob: float = sin(animation_time) * 2.4
        var squash: float = 1.0 + absf(sin(animation_time)) * 0.045
        sprite.position.y = bob
        sprite.scale = Vector2(1.0 + squash * 0.025, 1.0 - squash * 0.025)
        sprite.rotation = sin(animation_time * 0.5) * 0.045
    else:
        animation_time = 0.0
        sprite.position.y = lerpf(sprite.position.y, 0.0, minf(delta * 12.0, 1.0))
        sprite.scale = sprite.scale.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
        sprite.rotation = lerpf(sprite.rotation, 0.0, minf(delta * 12.0, 1.0))

func apply_damage(amount: float) -> void:
    if current_health <= 0.0 or is_dead:
        return
    current_health = maxf(current_health - amount, 0.0)
    health_changed.emit(current_health, max_health)
    if current_health <= 0.0:
        is_dead = true
        died.emit()

func heal(amount: float) -> void:
    if amount <= 0.0 or is_dead:
        return
    var previous_health: float = current_health
    current_health = minf(current_health + amount, max_health)
    if current_health != previous_health:
        health_changed.emit(current_health, max_health)

func _apply_regeneration(delta: float) -> void:
    if health_regen_per_second <= 0.0:
        return
    heal(health_regen_per_second * delta)

func apply_upgrade(upgrade: UpgradeDef) -> void:
    match upgrade.id:
        "move_speed":
            move_speed += upgrade.amount
        "max_hp":
            max_health += upgrade.amount
            current_health = minf(current_health + upgrade.amount, max_health)
            health_changed.emit(current_health, max_health)
        "magnet":
            xp_magnet_radius += upgrade.amount
        "regen":
            health_regen_per_second += upgrade.amount
