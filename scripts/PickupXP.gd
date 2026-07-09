class_name PickupXP
extends Area2D

const Player = preload("res://scripts/Player.gd")

signal collected(amount: int)

@export var amount: int = 10
@export var magnet_speed: float = 360.0

var target: Player
var is_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func set_target(player: Player) -> void:
    target = player

func _physics_process(delta: float) -> void:
    if target == null or is_collected:
        return
    var distance_to_player: float = global_position.distance_to(target.global_position)
    if distance_to_player <= target.xp_magnet_radius:
        var direction_to_player: Vector2 = global_position.direction_to(target.global_position)
        global_position += direction_to_player * magnet_speed * delta

func _on_body_entered(body: Node2D) -> void:
    if is_collected:
        return
    if body is Player:
        is_collected = true
        hide()
        set_physics_process(false)
        set_deferred("monitoring", false)
        set_deferred("monitorable", false)
        collision_shape.set_deferred("disabled", true)
        collected.emit(amount)
        call_deferred("queue_free")
