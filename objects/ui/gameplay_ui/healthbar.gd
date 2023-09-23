extends Control

@export var texture_full: Texture2D = preload("res://Assets/heardt_.png")
@export var texture_empty: Texture2D = preload("res://Assets/_______.png")

func _ready():
	GameState.player_node_changed.connect(_on_player_node_changed)
	_on_player_node_changed()

func _on_player_node_changed():
	if GameState.player_node != null:
		GameState.player_node.health_changed.connect(_update)
	_update()

func _update():
	for i in range(get_child_count()):
		get_child(-1).queue_free()
		remove_child(get_child(-1))
	
	if GameState.player_node == null:
		return
	
	for i in range(GameState.player_node.health_max):
		var tr := TextureRect.new()
		if GameState.player_node.health > i:
			tr.texture = texture_full
		else:
			tr.texture = texture_empty
		add_child(tr)
