class_name LevelUpPanel
extends CanvasLayer

const UpgradeDef = preload("res://scripts/resources/UpgradeDef.gd")

signal upgrade_selected(upgrade: UpgradeDef)

const CHOICE_COUNT: int = 3

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Panel/VBox/TitleLabel
@onready var choice_buttons: Array[Button] = [
    $Root/Panel/VBox/Choice1,
    $Root/Panel/VBox/Choice2,
    $Root/Panel/VBox/Choice3,
]

var active_choices: Array[UpgradeDef] = []

func _ready() -> void:
    hide_choices()
    for index: int in range(choice_buttons.size()):
        choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))

func show_choices(choices: Array[UpgradeDef]) -> void:
    active_choices = choices
    root.visible = true
    title_label.text = "LEVEL UP"
    for index: int in range(choice_buttons.size()):
        var button: Button = choice_buttons[index]
        var upgrade: UpgradeDef = active_choices[index]
        button.text = "%s\n%s" % [upgrade.title, upgrade.description]
        button.visible = true

func hide_choices() -> void:
    root.visible = false

func _on_choice_pressed(index: int) -> void:
    if index < 0 or index >= active_choices.size():
        return
    upgrade_selected.emit(active_choices[index])
    hide_choices()
