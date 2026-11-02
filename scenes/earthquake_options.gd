extends Control

@onready var classroom_structure = get_tree().root.find_child("ClassroomStructure", true, false)

# UI References
@onready var option_button: Button = $VBoxContainer/OptionButton
@onready var dropdown_panel: Panel = $VBoxContainer/OptionButton/DropdownPanel
@onready var items_list: VBoxContainer = $VBoxContainer/OptionButton/DropdownPanel/VBoxContainer

# NEW: Reference to your styled template button
@onready var template_button: Button = $VBoxContainer/OptionButton/DropdownPanel/VBoxContainer/TemplateButton

@onready var jarak_label: Label = $VBoxContainer/LabelJarak
@onready var golden_time_label: Label = $VBoxContainer/LabelGoldenTime
@onready var magnitudo_label: Label = $VBoxContainer/LabelMagnitudo
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton

@export var admin_menu_viewport: Node

var selected_index := 0

func _ready() -> void:
	if classroom_structure == null:
		push_error("WARNING: Could not find the ClassroomStructure node!")
		return
	
	# Initial Dropdown configuration
	dropdown_panel.visible = false
	template_button.visible = false # Ensure the template remains hidden
	
	option_button.pressed.connect(_on_dropdown_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	_populate_custom_dropdown()
	_update_info(0)

func _populate_custom_dropdown() -> void:
	# Clear previous dynamic buttons, but KEEP the template button
	for child in items_list.get_children():
		if child != template_button:
			child.queue_free()
		
	var labels: Array[String] = classroom_structure.get_record_labels()
	
	if not labels.is_empty():
		option_button.text = labels[0]
	
	for i in labels.size():
		var label_text = labels[i]
		
		# FIX: Duplicate the template button to copy your exact styles
		var item_btn: Button = template_button.duplicate()
		item_btn.text = label_text
		item_btn.visible = true # Make the duplicate visible
		
		item_btn.pressed.connect(_on_item_pressed.bind(i, label_text))
		items_list.add_child(item_btn)

func _on_dropdown_pressed() -> void:
	dropdown_panel.visible = !dropdown_panel.visible
	
	# FIX: Because DropdownPanel is now "Top Level", we force it to snap 
	# precisely beneath the OptionButton position layout.
	if dropdown_panel.visible:
		dropdown_panel.global_position = option_button.global_position + Vector2(0, option_button.size.y)

func _on_item_pressed(index: int, item_text: String) -> void:
	option_button.text = item_text
	dropdown_panel.visible = false
	_update_info(index)

func _update_info(index: int) -> void:
	selected_index = index
	var info: Dictionary = classroom_structure.get_record_info(index)
	
	if info.is_empty():
		jarak_label.text = "Jarak: -"
		golden_time_label.text = "Golden Time: -"
		magnitudo_label.text = "Magnitudo: -"
		return
	
	jarak_label.text = "Jarak: %.0f km" % info["distance_km"]
	golden_time_label.text = "Golden Time: %.1f detik" % info["golden_time_display_s"]
	magnitudo_label.text = "Magnitudo: Mw %.1f" % info["magnitude_mw"]

func _on_confirm_button_pressed() -> void:
	if classroom_structure == null:
		push_error("WARNING: Could not find the ClassroomStructure node!")
		return
	
	classroom_structure.begin_simulation(selected_index)
	
	if admin_menu_viewport:
		admin_menu_viewport.visible = false
		admin_menu_viewport.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		push_error("WARNING: admin_menu_viewport belum di-drag ke Inspector!")
