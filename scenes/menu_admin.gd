extends Control

# Grab references to your slider and the master earthquake node
@onready var intensity_slider = $VBoxContainer/HSlider
# Magnitude slider value 
@onready var slider_value: Label = $VBoxContainer/HSlider/SliderValue
# Use the brute-force search we used earlier so it never crashes!
@onready var classroom_structure = get_tree().root.find_child("ClassroomStructure", true, false)

@export var intensity_menu_viewport: Node

func _on_confirm_button_pressed() -> void:
	if classroom_structure != null:
		# 1. Get the current number from the slider
		var chosen_intensity: float = intensity_slider.value
		
		# 2. Tell the earthquake script to start, using our new number!
		if classroom_structure.has_method("begin_simulation_intensity"):
			classroom_structure.begin_simulation_intensity(chosen_intensity)
		else:
			classroom_structure.begin_simulation(chosen_intensity)
		
		# 3. Hide this entire 3D menu so it's not floating in the air during the quake
		var target_viewport = intensity_menu_viewport
		if target_viewport == null:
			target_viewport = get_tree().root.find_child("IntensityMenuViewport", true, false)
		if target_viewport == null:
			target_viewport = get_tree().root.find_child("AdminMenuViewport", true, false)
		
		if target_viewport:
			target_viewport.visible = false
			# Turn off its physics so VR hands don't bump into the invisible menu
			target_viewport.process_mode = Node.PROCESS_MODE_DISABLED 
	else:
		push_error("WARNING: Could not find the ClassroomStructure node!")

func _on_h_slider_value_changed(value: float) -> void:
	slider_value.text = "%.1f" % value
