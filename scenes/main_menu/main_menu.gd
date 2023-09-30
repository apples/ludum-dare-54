extends Node
var current_scene = null
# Called when the node enters the scene tree for the first time.
func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_game_pressed():
	current_scene.queue_free()
	var new_scene = ResourceLoader.load("res://scenes/gameplay/gameplay.tscn")
	current_scene = new_scene.instantiate()
	get_tree().get_root().add_child(current_scene)


func _on_options_pressed():
	current_scene.queue_free()
	var new_scene = ResourceLoader.load("res://scenes/options_menu/options_menu.tscn")
	current_scene = new_scene.instantiate()
	get_tree().get_root().add_child(current_scene)

