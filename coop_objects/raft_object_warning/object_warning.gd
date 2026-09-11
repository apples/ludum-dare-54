class_name CoopItemWarning extends CoopItem

var spawn_item : GLOBAL_VARS.object_type
var is_good := true
var last_buoy_pos := Vector2.ZERO

@onready var alert_sprite = $AlertSprite

@export var simple_curve : Curve

func _network_process(input: Dictionary):
	pass

func _network_spawn(data: Dictionary) -> void:

	var raft : CoopRaft = get_parent().get_parent().find_child("Raft", false)
	var tile = raft.get_tile(data.grid_pos)
	
	position = tile.position
	target_pos = position
	start_pos = position
	
	tile.tile_object = self
	
	spawn_item = data.item
	last_buoy_pos = data.buoy_pos
	
	is_good = data.good
	if is_good:
		alert_sprite.play("good")
	else:
		alert_sprite.play("bad")
