class_name HUD
extends CanvasLayer

@onready var timer_label: Label = $Root/TopBar/TimerLabel
@onready var mode_label: Label = $Root/TopBar/ModeLabel
@onready var hp_bar: ProgressBar = $Root/TopBar/HPBar
@onready var xp_bar: ProgressBar = $Root/TopBar/XPBar
@onready var level_label: Label = $Root/TopBar/LevelLabel
@onready var kills_label: Label = $Root/TopBar/KillsLabel
@onready var result_label: Label = $Root/Center/VBox/ResultLabel
@onready var restart_button: Button = $Root/Center/VBox/RestartButton

func _ready() -> void:
    result_label.visible = false
    restart_button.visible = false

func update_timer_remaining(seconds_remaining: float) -> void:
    mode_label.text = "SURVIVE"
    timer_label.text = _format_seconds(seconds_remaining)

func update_timer_elapsed(elapsed_seconds: float) -> void:
    mode_label.text = "ENDLESS"
    timer_label.text = _format_seconds(elapsed_seconds)

func update_timer(seconds_remaining: float) -> void:
    update_timer_remaining(seconds_remaining)

func _format_seconds(value: float) -> String:
    var total_seconds: int = int(maxf(ceilf(value), 0.0))
    var minutes: int = floori(float(total_seconds) / 60.0)
    var seconds: int = total_seconds % 60
    return "%02d:%02d" % [minutes, seconds]

func update_health(current_health: float, max_health: float) -> void:
    hp_bar.max_value = max_health
    hp_bar.value = current_health

func update_xp(current_xp: int, required_xp: int) -> void:
    xp_bar.max_value = required_xp
    xp_bar.value = current_xp

func update_level(level: int) -> void:
    level_label.text = "LV %d" % level

func update_kills(kill_count: int) -> void:
    kills_label.text = "KILLS %d" % kill_count

func show_result(victory: bool) -> void:
    result_label.text = "EXTRACTED" if victory else "OVERRUN"
    result_label.add_theme_color_override("font_color", Color(0.42, 1.0, 0.75) if victory else Color(1.0, 0.4, 0.4))
    result_label.visible = true
    restart_button.visible = true
