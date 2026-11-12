class_name VersusBoss extends Node2D

@onready var ouch_sfx = $Hit
@onready var death_sfx = $Death
@onready var boss_music = $BossMusic
@onready var animation_tree = $AnimationTree
@onready var blink_timer = $BlinkTimer
@onready var explosions = $CPUParticles2D
@onready var explosion_timer = $CPUParticles2D/ExplosionTimer

@onready var daze_timer_line = $DazeTimerLine
@onready var daze_duration_line = $DazeDurationLine

var warning_scene = preload("res://coop_objects/raft_object_warning/object_warning.tscn")

var base_health: int = (GLOBAL_VARS.difficulty + 1) * 5
var health_per_level: int = 3
var max_health := base_health

var daze_timer_ticks := 0 #ticks left to trigger a daze
var daze_duration_ticks := 0 #actual active daze duration
var recent_max_duration_ticks := 0
const max_daze_timer_ticks := 240
const daze_effect_ticks := 300
const point_count := 64
const point_length := 64

@export var raft : VersusRaft

var music_vol: float:
	get:
		return db_to_linear(boss_music.volume_db)
	set(v):
		boss_music.volume_db = linear_to_db(v)

func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BossMusic"), true)
	
	if raft.raft_index == 1:
		$FaceRig/Base.flip_h = true
		$FaceRig/Pupils.flip_h = true
		$FaceRig/Eyes.flip_h = true
		$FaceRig/Mouth.flip_h = true
		$FadeAnim.flip_h = true
		$FaceRig.position.x -= 32
		$FadeAnim.position.x -= 32

func _process(_delta: float) -> void:
	var current_point_count = ceil(64 * (float(daze_timer_ticks) / max_daze_timer_ticks))
	if daze_timer_line.get_point_count() > current_point_count:
		daze_timer_line.remove_point(daze_timer_line.get_point_count() - 1)
	if current_point_count > 0:
		daze_timer_line.set_point_position(daze_timer_line.get_point_count() - 1, Vector2(
				-sin((float(daze_timer_ticks) / max_daze_timer_ticks) * 2 * PI) * point_length, 
				-cos((float(daze_timer_ticks) / max_daze_timer_ticks) * 2 * PI) * point_length))
	
	current_point_count = ceil(64 * (float(daze_duration_ticks) / recent_max_duration_ticks))
	if daze_duration_line.get_point_count() > current_point_count:
		daze_duration_line.remove_point(daze_duration_line.get_point_count() - 1)
		if current_point_count == 0:
			recent_max_duration_ticks = 0
	if current_point_count > 0:
		daze_duration_line.set_point_position(daze_duration_line.get_point_count() - 1, Vector2(
				-sin((float(daze_duration_ticks) / recent_max_duration_ticks) * 2 * PI) * (point_length - 10), 
				-cos((float(daze_duration_ticks) / recent_max_duration_ticks) * 2 * PI) * (point_length - 10)))

func _network_process(_input: Dictionary):
	if daze_timer_ticks > 0:
		daze_timer_ticks -= 1
	if daze_duration_ticks > 0:
		daze_duration_ticks -= 1
		if daze_duration_ticks <= 0:
			raft.buoy_timer.unpause()

func daze():
	if daze_timer_ticks > 0:
		animation_tree["parameters/Normal/wince/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		daze_duration_ticks += daze_effect_ticks
		raft.buoy_timer.pause()
		recent_max_duration_ticks = daze_duration_ticks
		daze_duration_line.clear_points()
		for i in range(point_count):
			daze_duration_line.add_point(Vector2(
				-sin((i / float(point_count)) * 2 * PI) * (point_length - 10), 
				-cos((i / float(point_count)) * 2 * PI) * (point_length - 10)))
	daze_timer_ticks = max_daze_timer_ticks
	daze_timer_line.clear_points()
	for i in range(point_count):
		daze_timer_line.add_point(Vector2(
			-sin((i / float(point_count)) * 2 * PI) * point_length, 
			-cos((i / float(point_count)) * 2 * PI) * point_length))

func death():
	explosions.emitting = true
	explosion_timer.start()
	death_sfx.play()

func _save_state() -> Dictionary:
	return {
		daze_timer_ticks = daze_timer_ticks,
		daze_duration_ticks = daze_duration_ticks,
	}

func _load_state(state: Dictionary) -> void:
	daze_timer_ticks = state['daze_timer_ticks']
	daze_duration_ticks = state['daze_duration_ticks']


func _on_blink_timer_timeout() -> void:
	animation_tree["parameters/Normal/Blink/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	blink_timer.start(randf_range(0.5, 5.0))


func _on_explosion_timer_timeout() -> void:
	explosions.emitting = false
