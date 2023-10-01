extends Node2D
var current_scene = null
#var player_vars = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
#	player_vars = get_node("/root/PlayerVariables")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_game_pressed():
	current_scene.queue_free()
	GLOBAL_VARS.score=0
	var new_scene = ResourceLoader.load("res://scenes/gameplay/gameplay.tscn")
	current_scene = new_scene.instantiate()
	get_tree().get_root().add_child(current_scene)
