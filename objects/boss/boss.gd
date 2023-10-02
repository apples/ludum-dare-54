extends Sprite2D

signal boss_defeated

@export var raft: Node
@onready var toss_source = $TossSource

var bomb_scene = preload("res://objects/raft_objects/bomb.tscn")

var attack_delay := 500.0

var max_health := 30

var health := max_health:
	get:
		return health
	set(v):
		health = v
		if health <= 0:
			health = 0
			boss_defeated.emit()
		if health_bar:
			var percent := float(health) / float(max_health)
			health_bar.size.y = health_bar_initial_height * percent
			health_bar.position.y = health_bar_initial_position.y + (health_bar_initial_height - health_bar.size.y) * health_bar.scale.y


enum {
	LOOKING_STRAIGHT,
	LOOKING_RIGHT,
	LOOKING_DOWN,
}

var is_talking := false
var is_smug := true
var looking_dir := LOOKING_STRAIGHT

@onready var animation_tree = $AnimationTree
@onready var blink_timer = $BlinkTimer

@onready var health_bar = $HealthBar
@onready var health_bar_initial_position = health_bar.position
@onready var health_bar_initial_height = health_bar.size.y

func _ready():
	animation_tree.active = true

func _perform_attack():
	if not raft:
		return
	for i in range(3):
		var t = raft.get_random_empty_tile()
		if t:
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


func _on_blink_timer_timeout():
	print("blink")
	animation_tree["parameters/Blink/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	blink_timer.start(randf_range(0.5, 5.0))

