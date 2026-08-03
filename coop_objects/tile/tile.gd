class_name CoopTile extends Node2D

var damage_number_scene = preload("res://singleplayer_objects/damage_numbers/damage_numbers.tscn")
var tile_break_scene = preload("res://singleplayer_objects/VFX/tile_break/tile_break.tscn")

@export var tile_object: Node
var tile_object_name : StringName

@onready var burning_sfx = $Burning
@onready var fire_sprite = $Fire
@onready var fire_progress = $Fire/ProgressBar
@onready var fire_timer = $FireNetworkTimer

@export var health: int = 3 :
	set = _set_health
@export var max_health: int = 3

@export var fire_health_ticks: int = 0 :
	set = _set_fire_health
@export var max_fire_health_ticks: int = 60

var is_on_fire: bool:
	get:
		return fire_health_ticks > 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if is_on_fire:
		fire_progress.value = float(fire_health_ticks) / float(max_fire_health_ticks)

func _network_process(input: Dictionary):
	if is_on_fire:
		if SyncManager.current_tick % 4 == 0 && fire_health_ticks < max_fire_health_ticks:
			fire_health_ticks += 1

func _set_health(value: int):
	health = value
	if health <= 0:
		queue_free()
		var tile_break= tile_break_scene.instantiate() #does this need to be mult spawned? just visual, but queue_free could replicate out before _set_health gets hit
		tile_break.position = self.position
		get_parent().add_child(tile_break)
	else:
		match health:
			2:
				$AnimatedSprite2D.frame = 1
			1:
				$AnimatedSprite2D.frame = 2
			_:
				$AnimatedSprite2D.frame = 0

func _set_fire_health(value: int):
	if fire_health_ticks > 0 && value == 0:
		fire_sprite.visible = false
		burning_sfx.stop()
		fire_timer.stop()
	fire_health_ticks = value

func damage(value: int):
	if value < 0:
		if health < max_health:
			health -= value
	else:
		health -= value
		var dmg_number = damage_number_scene.instantiate()
		dmg_number.number_value = value
		dmg_number.position = self.position
		get_parent().add_child(dmg_number)

func ignite(amount: int = max_fire_health_ticks):
	if !is_on_fire:
		fire_health_ticks = amount
		fire_sprite.visible = true
		burning_sfx.play()
		fire_timer.start()


func _on_fire_network_timer_timeout() -> void:
	if not is_on_fire:
		return
	damage(1)
	
	assert(false, "need to implement grabbing adjascent neighbors in raft class")
	var adjacent_tiles = []
	for tile in adjacent_tiles:
		var fire_spread_chance = randi_range(0, 5)
		
		if fire_spread_chance == 1:
			tile.ignite()


func _save_state() -> Dictionary:
	return {
		health = health,
		fire_health_ticks = fire_health_ticks,
		tile_object_name = tile_object.name if tile_object else StringName(""),
	}

func _load_state(state: Dictionary) -> void:
	health = state['health']
	fire_health_ticks = state['fire_health_ticks']
	if tile_object_name != state['tile_object_name']:
		tile_object_name = state['tile_object_name']
		tile_object = get_parent().find_child(tile_object_name) if tile_object_name != StringName("") else null
