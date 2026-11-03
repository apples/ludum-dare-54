class_name CoopTile extends Node2D

const FIRE_BURN_TICKS := 300

var damage_number_scene = preload("res://singleplayer_objects/damage_numbers/damage_numbers.tscn")
var tile_break_scene = preload("res://singleplayer_objects/VFX/tile_break/tile_break.tscn")
var buoy_scene = load("res://coop_objects/buoy/buoy.tscn")

@export var tile_object: CoopItem = null

var player_ref : CoopPlayer = null

var raft_ref: CoopRaft
var grid_pos: Vector2i

@onready var burning_sfx = $Burning
@onready var fire_sprite = $Fire
@onready var fire_progress = $Fire/ProgressBar

@onready var item_parent = $"/root/CoopGameplay/ItemParent"
@onready var gameplay = $"/root/CoopGameplay"

@onready var effect_sprite = $MatchEffect
@onready var effect_sfx = $MatchSFX

var water_sfx := preload("res://assets/sfx/water_kill_fire.ogg")
var bomb_sfx := preload("res://assets/sfx/bomb_explode.ogg")
var hammer_sfx := preload("res://assets/sfx/repair_hammer.ogg")
var cannon_sfx := preload("res://assets/sfx/cannon_sfx.ogg")
var gem_sfx := preload("res://assets/sfx/gem_combo_get.ogg")
#var wood_sfx := preload("res://assets/sfx/water_kill_fire.ogg") #doesn't exist

var _health: int = 3
@export var health: int = 3 :
	get = _get_health,
	set = _set_health
@export var max_health: int = 3

@export var fire_health_ticks: int = 0 :
	set = _set_fire_health
@export var max_fire_health_ticks: int = 60

var burn_ticks_left: int = 0

var is_on_fire: bool:
	get:
		return fire_health_ticks > 0

func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if is_on_fire:
		fire_progress.value = float(fire_health_ticks) / float(max_fire_health_ticks)

func _get_health() -> int:
	return _health

func _set_health(value: int):
	_health = value
	if _health <= 0:
		var tile_break= tile_break_scene.instantiate()
		tile_break.position = self.position
		get_parent().add_child(tile_break)
		raft_ref.remove_tile(grid_pos)
		if player_ref: # splash
			player_ref.rooted = true
			#player_ref.grid_pos = Vector2i(-1, -1)
			SyncManager.spawn("Buoy", $"/root/CoopGameplay/BuoyParent", buoy_scene, {pos = raft_ref.grid_pos_to_global_position(grid_pos), player_path = player_ref.get_path()})
		if tile_object:
			SyncManager.despawn(tile_object)
		SyncManager.despawn(self)
	else:
		_set_damage_sprite()

func _set_damage_sprite() -> void:
	match _health:
		2:
			$AnimatedSprite2D.frame = 1
		1:
			$AnimatedSprite2D.frame = 2
		_:
			$AnimatedSprite2D.frame = 0

func _set_fire_health(value: int):
	var was_on_fire := fire_health_ticks > 0
	fire_health_ticks = clampi(value, 0, max_fire_health_ticks)
	if was_on_fire and fire_health_ticks == 0:
		burn_ticks_left = 0
	_refresh_fire_visuals()

func _refresh_fire_visuals() -> void:
	if not is_node_ready():
		return
	fire_sprite.visible = is_on_fire
	if is_on_fire:
		if not burning_sfx.playing:
			burning_sfx.play()
	elif burning_sfx.playing:
		burning_sfx.stop()

func damage(value: int):
	if value < 0:
		if health < max_health:
			health -= value
	else:
		var dmg_number = damage_number_scene.instantiate()
		dmg_number.number_value = value
		dmg_number.position = self.position
		get_parent().add_child(dmg_number)
		health -= value

func ignite(amount: int = max_fire_health_ticks):
	if !is_on_fire and amount > 0:
		fire_health_ticks = amount
		burn_ticks_left = FIRE_BURN_TICKS

func push(player_grid_pos: Vector2i) -> bool:
	var dir := grid_pos - player_grid_pos
	var next_tile = raft_ref.get_tile(grid_pos + dir)
	
	if tile_object:
		if tile_object.is_moving:
			return false
		
		if next_tile and !next_tile.tile_object and !next_tile.player_ref:
			next_tile.tile_object = tile_object
			tile_object = null
			next_tile.tile_object.start_move(position, next_tile.position)
			next_tile.tile_object.grid_pos = next_tile.grid_pos
			raft_ref.check_matches(next_tile)
			return true
	elif player_ref:
		if player_ref.move_ticks <= player_ref.move_ticks_target:
			return false
		
		if next_tile and !next_tile.player_ref and !next_tile.tile_object:
			player_ref.walk(dir)
			return true
	
	return false

func process_fire() -> void:
	if SyncManager.current_tick % 4 == 0 and fire_health_ticks < max_fire_health_ticks:
		fire_health_ticks += 1
	
	if fire_health_ticks < max_fire_health_ticks:
		return
	
	burn_ticks_left -= 1
	if burn_ticks_left > 0:
		return
	
	burn_ticks_left = FIRE_BURN_TICKS
	_spread_fire()
	damage(1)

func _spread_fire() -> void:
	for tile in raft_ref.get_adjacent_tiles(grid_pos):
		if MULT_UTILS.mult_rng.randi_range(0, 4) == 0:
			tile.ignite()

func _save_state() -> Dictionary:
	return {
		health = health,
		fire_health_ticks = fire_health_ticks,
		burn_ticks_left = burn_ticks_left,
		tile_object_path = tile_object.get_path() if tile_object else ^"",
		player_ref_path = player_ref.get_path() if player_ref else ^"",
	}

func _load_state(state: Dictionary) -> void:
	_health = state['health']
	_set_damage_sprite()
	burn_ticks_left = state['burn_ticks_left']
	fire_health_ticks = state['fire_health_ticks']
	player_ref = gameplay.get_node_or_null(state['player_ref_path'])
	tile_object = item_parent.get_node_or_null(state['tile_object_path'])

func _network_spawn(data: Dictionary) -> void:
	raft_ref = self.get_parent()
	grid_pos = data.coord
	position = grid_pos * 32
	raft_ref.add_tile(self)

func play_effect(effect_name: String):
	effect_sprite.show()
	match(effect_name):
		"hammer":
			effect_sprite.play("hammer")
		"water":
			effect_sprite.play("water")
		_:
			effect_sprite.play("sparkle")

func _on_match_effect_animation_finished() -> void:
	effect_sprite.hide()

func play_sfx(type: GLOBAL_VARS.object_type):
	match(type):
		GLOBAL_VARS.object_type.WATER:
			effect_sfx.stream = water_sfx
		GLOBAL_VARS.object_type.HAMMER:
			effect_sfx.stream = hammer_sfx
		GLOBAL_VARS.object_type.CANNON:
			effect_sfx.stream = cannon_sfx
		GLOBAL_VARS.object_type.GEM:
			effect_sfx.stream = gem_sfx
		GLOBAL_VARS.object_type.BOMB:
			effect_sfx.stream = bomb_sfx
		_: #wood
			effect_sfx.stream = hammer_sfx
	effect_sfx.play()
