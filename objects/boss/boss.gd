extends Sprite2D

signal boss_defeated

@export var raft: Node
@onready var toss_source = $TossSource
@onready var ouch_sfx = $OuchSFX

var bomb_scene = preload("res://objects/raft_objects/bomb.tscn")

var attack_delay := 5.0
var bomb_count_thrown := 1.0
var difficulty_acceleration := 50 # lower is faster acceleration
var is_stunned := false
var stun_length := 10

var max_health := 2

var health := max_health:
	get:
		return health
	set(v):
		if not is_stunned:
			if v < health:
				animation_tree["parameters/wince/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
				ouch_sfx.play()
			health = v
			if health <= 0:
				health = 0
				death()
			if health_bar:
				var percent := float(health) / float(max_health)
				health_bar.size.y = health_bar_initial_height * percent
				health_bar.position.y = health_bar_initial_position.y + (health_bar_initial_height - health_bar.size.y) * health_bar.scale.y


enum {
	LOOKING_STRAIGHT,
	LOOKING_RIGHT,
	LOOKING_DOWN,
}

enum {
	MOUTH_NORMAL,
	MOUTH_SMUG,
	MOUTH_POUT,
}

enum {
	EYES_NORMAL,
	EYES_ANGRY,
}

var is_talking := false
var mouth_shape := MOUTH_NORMAL
var eyes_shape := EYES_NORMAL
var looking_dir := LOOKING_STRAIGHT

@onready var animation_tree = $AnimationTree
@onready var blink_timer = $BlinkTimer

@onready var health_bar = $HealthBar
@onready var health_bar_initial_position = health_bar.position
@onready var health_bar_initial_height = health_bar.size.y

func _ready():
	animation_tree.active = true
	is_stunned = true
	$StunTimer.start(5)

func _perform_attack():
	if not raft:
		return
	animation_tree["parameters/emote_raise_eyes/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	for i in range(floor(bomb_count_thrown)):
		var t = raft.get_random_empty_tile()
		if t:
			var bomb = bomb_scene.instantiate()
			t.add_child(bomb)
			t.tile_object = bomb
			bomb.raft = raft
			bomb.grid_pos = t.grid_pos
			bomb.boss_toss(toss_source.global_position)
		await get_tree().create_timer(0.5).timeout
	
	attack_delay -= (attack_delay - 3) / difficulty_acceleration
	bomb_count_thrown += 6 / difficulty_acceleration

func _on_next_attack_timeout():
	if not is_stunned:
		_perform_attack()
	$NextAttack.start(attack_delay * randf_range(0.9, 1.1))

func _on_blink_timer_timeout():
	animation_tree["parameters/Blink/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	blink_timer.start(randf_range(0.5, 5.0))

func death():
	is_stunned = true
	$StunTimer.start(stun_length)
	$CPUParticles2D.emitting = true
	$CPUParticles2D/ExplosionTimer.start()
	$AudioStreamPlayer.play()
	
	attack_delay -= (attack_delay - 3) * 5 / difficulty_acceleration
	bomb_count_thrown += 6 * 5 / difficulty_acceleration
	
	boss_defeated.emit()


func _on_stun_timer_timeout():
	print("unstunned")
	is_stunned = false
	if health <= 0:
		GLOBAL_VARS.level += 1
		max_health += 3
		health = max_health
		health_bar.size.y = health_bar_initial_height
		health_bar.position.y = health_bar_initial_position.y + (health_bar_initial_height - health_bar.size.y) * health_bar.scale.y
	
