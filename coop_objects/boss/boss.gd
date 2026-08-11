extends Node2D

signal boss_defeated

@export var raft: Node

@onready var toss_source = $TossSource
@onready var ouch_sfx = $Hit
@onready var death_sfx = $Death
@onready var boss_music = $BossMusic
@onready var animation_tree = $AnimationTree
@onready var blink_timer = $BlinkTimer
@onready var stun_timer = $StunTimer
@onready var explosions = $CPUParticles2D
@onready var explosion_timer = $CPUParticles2D/ExplosionTimer

@onready var health_bar = $HealthBar
@onready var health_bar_initial_position = health_bar.position
@onready var health_bar_initial_height = health_bar.size.y

var bomb_scene = preload("res://singleplayer_objects/raft_objects/bomb.tscn")

var base_health: int = (GLOBAL_VARS.difficulty + 1) * 5
var health_per_level: int = 3
var max_health := base_health

var is_stunned := false
var stun_length := 20

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

var music_vol: float:
	get:
		return db_to_linear(boss_music.volume_db)
	set(v):
		boss_music.volume_db = linear_to_db(v)

func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), true)

func _set_healthbar(t: float):
	health_bar.size.y = health_bar_initial_height * t
	health_bar.position.y = health_bar_initial_position.y + (health_bar_initial_height - health_bar.size.y) * health_bar.scale.y

func death():
	is_stunned = true
	stun_timer.start(stun_length)
	explosions.emitting = true
	explosion_timer.start()
	death_sfx.play()
	
	boss_defeated.emit()
	
	var tween = create_tween()
	tween.tween_property(self, "music_vol", 0.0, 2.0)
	await tween.finished
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), true)

func _on_attack_timer_timeout() -> void:
	pass # Replace with function body.


func _on_stun_timer_timeout() -> void:
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
	
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), false)
	var tween = create_tween()
	music_vol = 0
	tween.tween_property(self, "music_vol", 1.0, 2.0)


func _on_blink_timer_timeout() -> void:
	animation_tree["parameters/Normal/Blink/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	blink_timer.start(randf_range(0.5, 5.0))


func _on_explosion_timer_timeout() -> void:
	explosions.emitting = false
