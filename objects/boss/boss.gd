extends Sprite2D

@export var raft: Node
@onready var toss_source = $TossSource

var bomb_scene = preload("res://objects/raft_objects/bomb.tscn")

var attack_delay := 5.0

func _ready():
	assert(raft != null)

func _perform_attack():
	for i in range(3):
		var t = raft.get_random_empty_tile()
		var bomb = bomb_scene.instantiate()
		t.add_child(bomb)
		t.tile_object = bomb
		bomb.raft = raft
		bomb.grid_pos = t.grid_pos
		bomb.boss_toss(toss_source.global_position)
		await get_tree().create_timer(0.5).timeout
	$NextAttack.start(attack_delay)


func _on_next_attack_timeout():
	_perform_attack()


