class_name VirtualJoystick
extends Control

signal direction_changed(direction: Vector2)

@export var radius: float = 88.0
@export var knob_radius: float = 28.0

var active_pointer: int = -1
var direction: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
    set_process_input(true)
    custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        _handle_touch(touch.index, touch.position, touch.pressed)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if drag.index == active_pointer:
            _update_direction(drag.position)
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event as InputEventMouseButton
        if mouse.button_index == MOUSE_BUTTON_LEFT:
            _handle_touch(0, mouse.position, mouse.pressed)
    elif event is InputEventMouseMotion and active_pointer == 0:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        _update_direction(motion.position)

func _handle_touch(pointer_id: int, position: Vector2, pressed: bool) -> void:
    if pressed and active_pointer == -1 and get_global_rect().has_point(position):
        active_pointer = pointer_id
        _update_direction(position)
    elif not pressed and pointer_id == active_pointer:
        active_pointer = -1
        direction = Vector2.ZERO
        knob_offset = Vector2.ZERO
        direction_changed.emit(direction)
        queue_redraw()

func _update_direction(position: Vector2) -> void:
    var center: Vector2 = global_position + size * 0.5
    knob_offset = (position - center).limit_length(radius)
    direction = knob_offset / radius
    direction_changed.emit(direction)
    queue_redraw()

func _draw() -> void:
    var center: Vector2 = size * 0.5
    draw_circle(center, radius, Color(0.05, 0.06, 0.07, 0.55))
    draw_arc(center, radius, 0.0, TAU, 48, Color(0.25, 0.95, 0.68, 0.65), 3.0)
    draw_circle(center + knob_offset, knob_radius, Color(0.30, 0.95, 0.80, 0.86))
