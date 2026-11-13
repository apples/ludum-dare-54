extends HBoxContainer

signal kick_requested(peer_id)

@export var peer_id = -1
@export var steam_id = -1
@export var display_name = ""

@onready var kick_button = $Button
@onready var name_label := $Label

func _ready() -> void:
	# only the host sees kick buttons, and can't kick itself
	kick_button.visible = MULT_UTILS.is_hosting \
			and peer_id != 1 \
			and peer_id != multiplayer.get_unique_id()
	update_info()

func update_info():
	#replace with steam logic when added
	if peer_id == 1:
		display_name = "(HOST) " + str(peer_id)
	elif peer_id == multiplayer.get_unique_id():
		display_name = "(SELF) " + str(peer_id)
	else:
		display_name = str(peer_id)
	name_label.text = display_name

func _on_button_pressed() -> void:
	kick_requested.emit(peer_id)
