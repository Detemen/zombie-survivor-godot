class_name Projectile
extends Area2D

const Zombie = preload("res://scripts/Zombie.gd")

signal expired(projectile: Projectile)

@export var damage: float = 18.0
@export var speed: float = 620.0
@export var max_distance: float = 260.0

var direction: Vector2 = Vector2.RIGHT
var traveled: float = 0.0
var is_expiring: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func launch(start_position: Vector2, target_direction: Vector2, shot_damage: float, shot_speed: float, shot_range: float) -> void:
    global_position = start_position
    direction = target_direction.normalized()
    damage = shot_damage
    speed = shot_speed
    max_distance = shot_range
    traveled = 0.0
    is_expiring = false
    rotation = direction.angle()
    set_physics_process(true)

func _physics_process(delta: float) -> void:
    if is_expiring:
        return
    var movement: Vector2 = direction * speed * delta
    global_position += movement
    traveled += movement.length()
    if traveled >= max_distance:
        expired.emit(self)
        _deactivate_and_free()

func _on_body_entered(body: Node2D) -> void:
    if is_expiring:
        return
    if body is Zombie:
        var zombie: Zombie = body as Zombie
        zombie.apply_damage(damage)
        expired.emit(self)
        _deactivate_and_free()

func _deactivate_and_free() -> void:
    if is_expiring:
        return
    is_expiring = true
    hide()
    set_physics_process(false)
    set_deferred("monitoring", false)
    set_deferred("monitorable", false)
    collision_shape.set_deferred("disabled", true)
    call_deferred("queue_free")
