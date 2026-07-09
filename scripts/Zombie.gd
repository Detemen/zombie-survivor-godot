class_name Zombie
extends CharacterBody2D

const EnemyDef = preload("res://scripts/resources/EnemyDef.gd")
const Player = preload("res://scripts/Player.gd")

signal died(zombie: Zombie, xp_amount: int)
signal touched_player(damage: float)

@export var enemy_def: EnemyDef

var current_health: float = 42.0
var target: Player
var touch_cooldown: float = 0.0
var animation_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func configure(definition: EnemyDef, player: Player) -> void:
    enemy_def = definition
    target = player
    current_health = enemy_def.max_health
    if sprite != null and enemy_def.texture != null:
        sprite.texture = enemy_def.texture

func _physics_process(delta: float) -> void:
    if target == null or enemy_def == null:
        return
    touch_cooldown = maxf(touch_cooldown - delta, 0.0)
    var chase_direction: Vector2 = global_position.direction_to(target.global_position)
    velocity = chase_direction * enemy_def.move_speed
    move_and_slide()
    _update_motion_animation(chase_direction, delta)
    if global_position.distance_to(target.global_position) <= enemy_def.radius + 14.0 and touch_cooldown <= 0.0:
        touch_cooldown = 0.65
        touched_player.emit(enemy_def.touch_damage)

func _update_motion_animation(movement_vector: Vector2, delta: float) -> void:
    animation_time += delta * 9.0
    var bob: float = sin(animation_time) * 1.8
    var lean: float = sin(animation_time * 0.55) * 0.06
    sprite.position.y = bob
    sprite.scale = Vector2(1.0 + absf(bob) * 0.012, 1.0 - absf(bob) * 0.010)
    sprite.rotation = lean
    if movement_vector.x != 0.0:
        sprite.flip_h = movement_vector.x < 0.0

func apply_damage(amount: float) -> void:
    current_health = maxf(current_health - amount, 0.0)
    modulate = Color(1.0, 0.55, 0.55)
    var tween: Tween = create_tween()
    tween.tween_property(self, "modulate", Color.WHITE, 0.08)
    if current_health <= 0.0:
        died.emit(self, enemy_def.xp_reward)
        call_deferred("queue_free")
