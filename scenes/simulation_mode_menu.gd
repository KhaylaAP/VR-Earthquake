extends Control

# The viewport that holds THIS menu (so we can hide it)
@export var mode_menu_viewport: Node
# The viewport that holds the earthquake options menu (data-based)
@export var options_menu_viewport: Node
# The viewport that holds the intensity-based menu
@export var intensity_menu_viewport: Node

func _ready() -> void:
	_resolve_viewports()
	# Make sure only the mode menu is visible when the scene starts
	_set_menu_active(options_menu_viewport, false)
	_set_menu_active(intensity_menu_viewport, false)
	_set_menu_active(mode_menu_viewport, true)

func _resolve_viewports() -> void:
	if mode_menu_viewport == null:
		mode_menu_viewport = get_tree().root.find_child("ModeMenuViewport", true, false)
	if options_menu_viewport == null:
		options_menu_viewport = get_tree().root.find_child("AdminMenuViewport", true, false)
	if intensity_menu_viewport == null:
		intensity_menu_viewport = get_tree().root.find_child("IntensityMenuViewport", true, false)

func _set_menu_active(menu: Node, active: bool) -> void:
	if menu == null:
		return
	menu.visible = active
	menu.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func _on_data_button_pressed() -> void:
	_resolve_viewports()
	if options_menu_viewport == null:
		push_error("WARNING: options_menu_viewport tidak ditemukan!")
		return
	_set_menu_active(mode_menu_viewport, false)
	_set_menu_active(options_menu_viewport, true)

func _on_intensity_button_pressed() -> void:
	_resolve_viewports()
	if intensity_menu_viewport == null:
		push_error("WARNING: intensity_menu_viewport tidak ditemukan!")
		return
	_set_menu_active(mode_menu_viewport, false)
	_set_menu_active(intensity_menu_viewport, true)
