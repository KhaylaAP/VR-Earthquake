extends Control 
@export_file("*.tscn") var simulation_scene := "res://scenes/kelas.tscn"

# Placeholders for later
@export_file("*.tscn") var training_scene := ""
@export_file("*.tscn") var testing_scene := ""

var is_transitioning := false

func fade_to_black() -> void:
	var camera_fade = get_tree().root.find_child("Fade", true, false)
	
	if camera_fade != null and camera_fade is MeshInstance3D:
		var fade_material = camera_fade.get_active_material(0)
		if fade_material != null:
			var tween = create_tween()
			tween.tween_property(fade_material, "albedo_color:a", 1.0, 1.5)
			await tween.finished
		else:
			push_error("WARNING: The Fade mesh has no material attached!")
			await get_tree().create_timer(0.1).timeout
	else:
		push_error("WARNING: Could not find a valid 3D Fade mesh in this scene!")
		await get_tree().create_timer(0.1).timeout

func _go_to_scene(path: String) -> void:
	# Prevents double-presses from VR controller pointers
	if is_transitioning:
		return
	is_transitioning = true

	# Use the staging system (XRToolsSceneBase) on the scene root so that
	# transitions go through proper fade + loading screen instead of a raw swap.
	var scene_root = get_tree().root.find_child("Start Menu", true, false)
	if scene_root and scene_root.has_method("load_scene"):
		scene_root.load_scene(path)
	else:
		# Fallback: direct switch (e.g. when running start_menu standalone)
		await fade_to_black()
		get_tree().change_scene_to_file(path)

func _on_simulation_button_pressed() -> void:
	_go_to_scene(simulation_scene)

func _on_training_button_pressed() -> void:
	print("")

func _on_testing_button_pressed() -> void:
	print("")
