extends Node2D

@onready var buoy_parent = $BuoyParent
@onready var raft = $player_raft
@onready var score = $Score
@onready var level = $Level
@onready var charges = $Charges

var buoy_scene = preload("res://objects/item_buoy/item_buoy.tscn")

signal module_valid_connection_updated(valid)
var module_ui_scene = preload("res://objects/module_ui/module_ui.tscn")

var col_bag := []
var col_ranges := [[1, 16], [5, 10], [7, 8]]

var spawnables_bag := []
var spawnables = [
	{ weight = 10, scene = "water" },
	{ weight = 40, scene = "wood" },
	#{ weight = 15.0, scene = preload("res://objects/raft_objects/bomb.tscn") },
	{ weight = 5, scene = "gem" },
	{ weight = 10, scene = "hammer" },
	{ weight = 20, scene = "cannon" },
]

const bounds_grid_coords = Vector2i(17, 13)
var placing_raft_module = false
var upgrading = false
var module_container: Node2D
var grid_position = Vector2i(7, 7)
var valid_connection = false
var at_direction_edge = {
	'UP': false,
	'DOWN': false,
	'LEFT': false,
	'RIGHT': false,
}
var was_mouse_down = true
var upgrading_player: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if MULT_UTILS.is_hosting:
		$Lobby.create_game()
	else:
		$Lobby.join_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	score.text = "%s" % GLOBAL_VARS.score
	level.text = "%s" % GLOBAL_VARS.level
	charges.text = "%s" % GLOBAL_VARS.upgradeCharges
	
	if placing_raft_module and module_container:
		process_module_placement()

func start_game() -> void:
	$NetworkTimer.start()
	
	var item = SyncManager.spawn("item1", self, GLOBAL_VARS.spawnables["wood"], {})
	raft.place_object(Vector2(6, 9), item)
	item.position = Vector2(0, 0)
	item = SyncManager.spawn("item2", self, GLOBAL_VARS.spawnables["wood"], {})
	raft.place_object(Vector2(7, 9), item)
	item.position = Vector2(0, 0)
	item = SyncManager.spawn("item3", self, GLOBAL_VARS.spawnables["wood"], {})
	raft.place_object(Vector2(9, 9), item)
	item.position = Vector2(0, 0)

## BUOY SPAWNING
func _pick_spawnable():
	if spawnables_bag.is_empty():
		seed(MULT_UTILS.mult_rng.randi())
		for s in spawnables:
			for i in range(s.weight):
				spawnables_bag.append(s.scene)
		spawnables_bag.shuffle()
	
	return spawnables_bag.pop_back()

func _pick_column() -> int:
	if col_bag.is_empty():
		seed(MULT_UTILS.mult_rng.randi())
		for r in col_ranges:
			for i in range(r[0], r[1]):
				col_bag.append(i)
		col_bag.shuffle()
		print()
	return col_bag.pop_back()

func _on_network_timer_timeout() -> void:
	var item_name = _pick_spawnable()
	var spawn_pos = raft.global_position + Vector2(_pick_column() * 32, 0)
	SyncManager.spawn("Buoy", buoy_parent, buoy_scene, {"item": item_name, "pos": spawn_pos})


## UPGRADES HANDLING
func process_module_placement():
	var check_connection_check_bounds = func():
		var connection_response = check_valid_connection()
		valid_connection = connection_response[0]
		at_direction_edge = connection_response[1]
	
	var mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if mouse_down || was_mouse_down:
		var mouse_pos = get_viewport().get_mouse_position()
		grid_position.x = floori((mouse_pos.x - 210) / 32)
		grid_position.y = floori((mouse_pos.y - 48) / 32)
		check_connection_check_bounds.call()
		if was_mouse_down && !mouse_down && valid_connection:
			confirm_module_connection()
		was_mouse_down = mouse_down
	else:
		if Input.is_action_just_pressed("up") and not at_direction_edge['UP']:
			grid_position.y -= 1
			check_connection_check_bounds.call()
		if Input.is_action_just_pressed("down") and not at_direction_edge['DOWN']:
			grid_position.y += 1
			check_connection_check_bounds.call()
		if Input.is_action_just_pressed("left") and not at_direction_edge['LEFT']:
			grid_position.x -= 1
			check_connection_check_bounds.call()
		if Input.is_action_just_pressed("right") and not at_direction_edge['RIGHT']:
			grid_position.x += 1
			check_connection_check_bounds.call()
		
	if Input.is_action_just_pressed("interact") and valid_connection:
		confirm_module_connection()
		
	module_container.global_position = $player_raft.grid_pos_to_global_position(grid_position)

func confirm_module_connection():
	for tile in module_container.get_children():
		var tile_new_grid_pos = tile.grid_pos + grid_position
		spawn_tile.rpc(tile_new_grid_pos, tile.scene_file_path)
		if upgrading_player:
			upgrading_player.reset.rpc()
		upgrading = false
		placing_raft_module = false
	
	grid_position = Vector2i(7, 7)
	delete_children(module_container)
	valid_connection = false

@rpc("any_peer", "call_local", "reliable")
func spawn_tile(pos, scene_path):
	$player_raft.create_tile(pos, load(scene_path))

# Returns [valid_connection_condition, Dict<at_direction_edge>]
func check_valid_connection() -> Array:
	var result_at_direction_edge = {
		'UP': false,
		'DOWN': false,
		'LEFT': false,
		'RIGHT': false,
	}
	
	var touching_neighbor = false
	var overlap = false
	var in_bounds = true
	
	for tile in module_container.get_children():
		var tile_new_grid_pos_row = tile.grid_pos.y + grid_position.y
		var tile_new_grid_pos_col = tile.grid_pos.x + grid_position.x
		
		if tile_new_grid_pos_row > bounds_grid_coords.y:
			result_at_direction_edge['DOWN'] = true
			in_bounds = false
		if tile_new_grid_pos_row < 0:
			result_at_direction_edge['UP'] = true
			in_bounds = false
		if tile_new_grid_pos_col > bounds_grid_coords.x:
			result_at_direction_edge['RIGHT'] = true
			in_bounds = false
		if tile_new_grid_pos_col < 0:
			result_at_direction_edge['LEFT'] = true
			in_bounds = false
		
		if $player_raft.get_tile(tile_new_grid_pos_row, tile_new_grid_pos_col):
			overlap = true
		if $player_raft.get_relative_tile_rc($player_raft.NORTH, tile_new_grid_pos_row, tile_new_grid_pos_col) or $player_raft.get_relative_tile_rc($player_raft.EAST, tile_new_grid_pos_row, tile_new_grid_pos_col) or $player_raft.get_relative_tile_rc($player_raft.SOUTH, tile_new_grid_pos_row, tile_new_grid_pos_col) or $player_raft.get_relative_tile_rc($player_raft.WEST, tile_new_grid_pos_row, tile_new_grid_pos_col):
			touching_neighbor = true
	
	var valid_connection_condition = touching_neighbor and not overlap and in_bounds
	module_valid_connection_updated.emit(valid_connection_condition)
	
	return [valid_connection_condition, result_at_direction_edge]


func on_initiate_module_placement(module, player):
	placing_raft_module = true
	upgrading_player = player
	was_mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
#	$player_raft.grid_pos_to_global_position(Vector2(5, 5))
	grid_position = Vector2i(7, 7)
	render_raft_module(module, $player_raft.grid_pos_to_global_position(grid_position))
	valid_connection = check_valid_connection()

func render_raft_module(raft_module_structure, pos: Vector2):
	module_container = Node2D.new()
	module_container.position = pos
	#var raft_module_structure = module
	var max_x = -999
	var max_y = -999
	var min_x = 999
	var min_y = 999
	for k in raft_module_structure:
		max_x = max(k.x, max_x)
		max_y = max(k.y, max_y)
		min_x = min(k.x, min_x)
		min_y = min(k.y, min_y)
	
	#var module_width = (max_x - min_x + 1) * 32
	#var module_height = (max_y - min_y + 1) * 32
	
	for k in raft_module_structure:
		var tile_x_offset = 32 * k.x
		var tile_y_offset = 32 * k.y
		var raft_tile = raft_module_structure[k].instantiate()
		raft_tile.grid_pos = k
		raft_tile.position.x += tile_x_offset # - module_width/4
		raft_tile.position.y += tile_y_offset # - module_height/4
		module_container.add_child(raft_tile)
		
		var module_ui = module_ui_scene.instantiate()
		self.module_valid_connection_updated.connect(module_ui.on_module_valid_connection_updated)
#		module_ui.position = raft_tile.position
		raft_tile.visual_only()
		raft_tile.add_child(module_ui)
	
	self.add_child(module_container)

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free()


#func raft_destroyed(raft: Raft):
	#if raft == $enemy_raft:
##		$Level.text = "Level: %s" % GLOBAL_VARS
		#GLOBAL_VARS.current_level += 1
		#player.disable()
		#var upgrade_select = upgrade_select_scene.instantiate()
		#upgrade_select.initiate_module_placement.connect(self.on_initiate_module_placement)
		#self.add_child(upgrade_select)
	#elif raft == $player_raft:
		#UTILS.change_to_scene(lose_screen_scene_file)
