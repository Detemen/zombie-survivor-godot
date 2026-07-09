class_name WelcomeScreen
extends CanvasLayer

signal start_requested(mode: String)

@onready var timed_button: Button = $Root/Panel/VBox/TimedButton
@onready var endless_button: Button = $Root/Panel/VBox/EndlessButton

func _ready() -> void:
    timed_button.pressed.connect(_on_timed_pressed)
    endless_button.pressed.connect(_on_endless_pressed)

func _on_timed_pressed() -> void:
    start_requested.emit("timed")

func _on_endless_pressed() -> void:
    start_requested.emit("endless")
