extends Node2D

var upgrade_select_scene = preload("res://scenes/upgrade_select/upgrade_select.tscn")
var placing_raft_module = false
var module_container: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
#	raft_destroyed($enemy_raft)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if placing_raft_module:
		process_module_placement()

func process_module_placement():
	if Input.is_action_just_pressed("up") and module_container:
		module_container.position.y -= 32
	if Input.is_action_just_pressed("down") and module_container:
		module_container.position.y += 32
	if Input.is_action_just_pressed("left") and module_container:
		module_container.position.x -= 32
	if Input.is_action_just_pressed("right") and module_container:
		module_container.position.x += 32


func raft_destroyed(raft: Raft):
	if raft == $enemy_raft:
		$Player.sit()
		var upgrade_select = upgrade_select_scene.instantiate()
		upgrade_select.initiate_module_placement.connect(self.on_initiate_module_placement)
		self.add_child(upgrade_select)
	elif raft == $player_raft:
		print("oops you lost") # game over


func on_initiate_module_placement(module):
	placing_raft_module = true
#	$player_raft.rc_to_pos(Vector2(5, 5))
	render_raft_module(module, $player_raft.rc_to_pos(Vector2(5, 5)))

func render_raft_module(module, pos: Vector2):
	module_container = Node2D.new()
	module_container.position = pos
	var raft_module_structure = module.get_structure()
	var max_x = -999
	var max_y = -999
	var min_x = 999
	var min_y = 999
	for k in raft_module_structure:
		max_x = max(k.x, max_x)
		max_y = max(k.y, max_y)
		min_x = min(k.x, min_x)
		min_y = min(k.y, min_y)
	
	var module_width = (max_x - min_x + 1) * 32
	var module_height = (max_y - min_y + 1) * 32
		
	for k in raft_module_structure:
		var tile_x_offset = 32 * k.x
		var tile_y_offset = 32 * k.y
		var raft_tile = raft_module_structure[k].instantiate()
		raft_tile.position.x += tile_x_offset # - module_width/4
		raft_tile.position.y += tile_y_offset # - module_height/4
		module_container.add_child(raft_tile)
	
	self.add_child(module_container)
