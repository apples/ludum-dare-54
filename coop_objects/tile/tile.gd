class_name CoopTile extends Node2D

var damage_number_scene = preload("res://singleplayer_objects/damage_numbers/damage_numbers.tscn")
var tile_break_scene = preload("res://singleplayer_objects/VFX/tile_break/tile_break.tscn")

@export var tile_object: CoopItem = null

var player_ref : CoopPlayer = null

var raft_ref: CoopRaft
var grid_pos: Vector2i

@onready var burning_sfx = $Burning
@onready var fire_sprite = $Fire
@onready var fire_progress = $Fire/ProgressBar
@onready var fire_timer = $FireNetworkTimer

@onready var item_parent = $"/root/CoopGameplay/ItemParent"
@onready var gameplay = $"/root/CoopGameplay"

@onready var effect_sprite = $MatchEffect

var _health: int = 3
@export var health: int = 3 :
	get = _get_health,
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
		if SyncManager.current_tick % 4 == 0 and fire_health_ticks < max_fire_health_ticks:
			fire_health_ticks += 1

func _get_health() -> int:
	return _health

func _set_health(value: int):
	_health = value
	if _health <= 0:
		var tile_break= tile_break_scene.instantiate() #TODO does this need to be mult spawned? just visual, but queue_free could replicate out before _set_health gets hit
		tile_break.position = self.position
		get_parent().add_child(tile_break)
		raft_ref.remove_tile(grid_pos)
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
	if fire_health_ticks > 0 and value == 0: #extinguish
		fire_sprite.visible = false
		burning_sfx.stop()
		fire_timer.stop()
	elif fire_health_ticks == max_fire_health_ticks and value < max_fire_health_ticks: #pause timer on extinguish start
		fire_timer.pause()
	elif is_on_fire and fire_health_ticks < max_fire_health_ticks and value == max_fire_health_ticks: #resume timer on fire regen
		fire_timer.unpause()
	fire_health_ticks = value

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
	if !is_on_fire:
		fire_health_ticks = amount
		fire_sprite.visible = true
		burning_sfx.play()
		fire_timer.start()

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
		if player_ref.move_ticks <= player_ref.move_ticks_target or player_ref.held_object:
			return false
		
		if next_tile and !next_tile.player_ref and !next_tile.tile_object:
			player_ref.walk(dir)
			return true
	
	return false

func _on_fire_network_timer_timeout() -> void:
	if not is_on_fire:
		return
	damage(1)
	
	var adjacent_tiles = raft_ref.get_adjacent_tiles(grid_pos)
	for tile in adjacent_tiles:
		var fire_spread_chance = MULT_UTILS.mult_rng.randi_range(0, 4)
		
		if fire_spread_chance == 0:
			tile.ignite()


func _save_state() -> Dictionary:
	return {
		health = health,
		fire_health_ticks = fire_health_ticks,
		tile_object_path = tile_object.get_path() if tile_object else ^"",
		player_ref_path = player_ref.get_path() if player_ref else ^"",
	}

func _load_state(state: Dictionary) -> void:
	_health = state['health']
	_set_damage_sprite()
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
