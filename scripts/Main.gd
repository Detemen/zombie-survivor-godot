extends Node

const Game = preload("res://scripts/Game.gd")
const WelcomeScreen = preload("res://scripts/WelcomeScreen.gd")
const WELCOME_SCENE: PackedScene = preload("res://scenes/WelcomeScreen.tscn")
const GAME_SCENE: PackedScene = preload("res://scenes/Game.tscn")

var active_screen: Node

func _ready() -> void:
    show_welcome_screen()

func show_welcome_screen() -> void:
    _clear_active_screen()
    var welcome: WelcomeScreen = WELCOME_SCENE.instantiate() as WelcomeScreen
    active_screen = welcome
    add_child(welcome)
    welcome.start_requested.connect(start_game)

func start_game(mode: String) -> void:
    _clear_active_screen()
    var game: Game = GAME_SCENE.instantiate() as Game
    game.configure_mode(mode)
    active_screen = game
    add_child(game)
    game.return_to_menu_requested.connect(show_welcome_screen)

func _clear_active_screen() -> void:
    if active_screen != null and is_instance_valid(active_screen):
        active_screen.queue_free()
    active_screen = null
