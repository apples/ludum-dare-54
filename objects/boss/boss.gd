extends Node2D

signal boss_defeated

@export var raft: Node
@onready var toss_source = $TossSource
@onready var ouch_sfx = $OuchSFX
@onready var boss_music = $BossMusic

var bomb_scene = preload("res://objects/raft_objects/bomb.tscn")

var attack_delay := 5.0
var bomb_count_thrown := 1.0
var difficulty_acceleration := 50.0 # lower is faster acceleration
var is_stunned := false
var stun_length := 20

var base_health: int = (GLOBAL_VARS.difficulty + 1) * 5
var health_per_level: int = 3
var max_health := base_health

var health := max_health:
	get:
		return health
	set(v):
		if not is_stunned:
			if v < health:
				animation_tree["parameters/Normal/wince/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
				ouch_sfx.play()
			if health == 0 and v < 0:
				return
			health = v
			if health <= 0:
				health = 0
				death()
			if health_bar:
				_set_healthbar(float(health) / float(max_health))

func _set_healthbar(t: float):
	health_bar.size.y = health_bar_initial_height * t
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

var is_alive: bool:
	get:
		return not is_stunned
var is_talking := false
var mouth_shape := MOUTH_NORMAL
var eyes_shape := EYES_NORMAL
var looking_dir := LOOKING_STRAIGHT

@onready var animation_tree = $AnimationTree
@onready var blink_timer = $BlinkTimer

@onready var health_bar = $HealthBar
@onready var health_bar_initial_position = health_bar.position
@onready var health_bar_initial_height = health_bar.size.y

var music_vol: float:
	get:
		return db_to_linear(boss_music.volume_db)
	set(v):
		boss_music.volume_db = linear_to_db(v)

func _ready():
	music_vol = 0
	animation_tree.active = true
	is_stunned = true
	_set_healthbar(0)
	if !raft:
		get_node_or_null("../player_raft")
	if raft:
		$StunTimer.start(stun_length)

func _perform_attack():
	if not raft:
		return
	animation_tree["parameters/Normal/emote_raise_eyes/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	for i in range(floor(bomb_count_thrown)):
		var t = raft.get_random_empty_tile()
		if t:
			var bomb = bomb_scene.instantiate()
			raft.place_object(t.grid_pos, bomb)
			bomb.boss_toss(toss_source.global_position)
		await get_tree().create_timer(0.5).timeout
	
	attack_delay -= (attack_delay - 3) / difficulty_acceleration
	bomb_count_thrown += 6 / difficulty_acceleration

func _on_next_attack_timeout():
	if not is_stunned:
		_perform_attack()
	$NextAttack.start(attack_delay * randf_range(0.9, 1.1))

func _on_blink_timer_timeout():
	animation_tree["parameters/Normal/Blink/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
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
	
	var tween = create_tween()
	tween.tween_property(self, "music_vol", 0.0, 2.0)
	await tween.finished
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), true)


func _on_stun_timer_timeout():
	print("unstunned")
	is_stunned = false
	if health <= 0:
		GLOBAL_VARS.level += 1
		var mult: float
		match GLOBAL_VARS.difficulty:
			GLOBAL_VARS.DIFF_EASY: mult = 1
			GLOBAL_VARS.DIFF_MED: mult = 1.5
			GLOBAL_VARS.DIFF_HARD: mult = 2
		max_health += int(float(health_per_level) * mult)
	health = max_health
	_set_healthbar(float(health) / float(max_health))
	print("New boss health: ", max_health)
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), false)
	var tween = create_tween()
	music_vol = 0
	tween.tween_property(self, "music_vol", 1.0, 2.0)
