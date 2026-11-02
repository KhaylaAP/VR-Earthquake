extends Control

# --- HELPER FUNCTION ---
# Both buttons will call this function to handle the screen fade
func fade_to_black() -> void:
	# 1. Ask the absolute root of the game to search every single node to find "Fade" node
	var camera_fade = get_tree().root.find_child("Fade", true, false)
	
	# 2. Check if the search was successful
	if camera_fade != null and camera_fade is MeshInstance3D:
		var fade_material = camera_fade.get_active_material(0)
		
		# Double check that the material actually exists so the tween doesn't crash
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

# --- BUTTON COMMANDS ---
func _on_reset_button_pressed() -> void:
	# 1. Wait for the screen to go black
	await fade_to_black()
	
	# 2. Reload the exact scene we are currently standing in!
	get_tree().reload_current_scene()

func _on_exit_to_menu_button_pressed() -> void:
	DataLogging.advance_to_next_subject()
	# 1. Wait for the screen to go black
	await fade_to_black()
	
	# 2. Load the main menu
	#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	# Quit game
	get_tree().quit()
