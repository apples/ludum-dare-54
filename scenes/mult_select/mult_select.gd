extends Node2D

var lobby_scene = "res://scenes/lobby/lobby.tscn"
@onready var ip = $LineEdit

func _on_c_host_pressed() -> void:
	MULT_UTILS.is_hosting = true
	MULT_UTILS.is_coop = true
	UTILS.change_to_scene(lobby_scene)


func _on_c_join_pressed() -> void:
	MULT_UTILS.is_hosting = false
	MULT_UTILS.is_coop = true
	if ip.text != "":
		MULT_UTILS.ip_target = ip.text
	UTILS.change_to_scene(lobby_scene)


func _on_v_host_pressed() -> void:
	MULT_UTILS.is_hosting = true
	MULT_UTILS.is_coop = false
	UTILS.change_to_scene(lobby_scene)


func _on_v_join_pressed() -> void:
	MULT_UTILS.is_hosting = false
	MULT_UTILS.is_coop = false
	if ip.text != "":
		MULT_UTILS.ip_target = ip.text
	UTILS.change_to_scene(lobby_scene)
