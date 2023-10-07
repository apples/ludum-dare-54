@tool
extends EditorScript

var base: PackedScene = load("res://objects/raft_objects/raft_object.tscn")

func _run():
	get_editor_interface().save_scene()
	var root := load(get_scene().scene_file_path)
	print("Updating scene: ", root.resource_path)
	
	var bundled = root._bundled.duplicate()
	if "base_scene" in bundled:
		print("Scene is already inherited from: ", bundled["variants"][bundled["base_scene"]].resource_path)
		return
	
	bundled["variants"].append(base)
	bundled["base_scene"] = bundled["variants"].size() - 1
	root._bundled = bundled
	ResourceSaver.save(root)
	
	print("Success")
	
	get_editor_interface().reload_scene_from_path(root.resource_path)
	get_editor_interface().save_scene()
