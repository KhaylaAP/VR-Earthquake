extends Node3D

# Instruction nodes
@onready var panel: Sprite3D = $Prompts/Panel
@onready var title: Label3D = $Prompts/Panel/Title
@onready var instructions: Label3D = $Prompts/Panel/Title/Instructions
@onready var details: Label3D = $Prompts/Panel/Title/Details
@onready var more_inst: Label3D = $Prompts/Panel/Title/MoreInst

# Areas
@onready var under_table: Area3D = $"../../../UnderTable"
@onready var exit_doors: Area3D = $"../../../ExitDoors"

# Keeps track of where we are in the tutorial
var current_step := 0

# Stops player triggering next step while text is invisible
var is_animating := false

var title_new := ""
var instructions_new := ""
var details_new := ""
var more_inst_new := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set starting text
	panel.modulate.a = 0.6
	title.modulate.a = 1.0
	title.outline_modulate.a = 1.0
	instructions.modulate.a = 1.0
	instructions.outline_modulate.a = 1.0
	details.modulate.a = 1.0
	details.outline_modulate.a = 1.0
	more_inst.modulate.a = 0.0
	more_inst.outline_modulate.a = 0.0
	title.text = "Merunduk"
	instructions.text = "Tekan tombol 'A' untuk merunduk."
	details.text = "Guncangan yang hebat dapat membuat Anda terlempar ke seberang ruangan. \
	Menjatuhkan diri menjaga pusat gravitasi Anda tetap rendah, mencegah Anda terjatuh, \
	dan memungkinkan Anda merangkak dengan aman ke tempat berlindung."
	
	title.visible = true
	instructions.visible = true
	details.visible = true
	
	under_table.visible = false
	under_table.process_mode = Node.PROCESS_MODE_DISABLED
	exit_doors.visible = false
	exit_doors.process_mode = Node.PROCESS_MODE_DISABLED

# Text fade helper
func fade_to_new_text(new_title: String, new_instructions: String, new_details: String, new_more_inst: String) -> void:
	is_animating = true
	# Fade the text out
	var fade_out = create_tween()
	fade_out.tween_property(panel, "modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(title, "modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(title, "outline_modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(instructions, "modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(instructions, "outline_modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(details, "modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(details, "outline_modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(more_inst, "modulate:a", 0.0, 0.5)
	fade_out.parallel().tween_property(more_inst, "outline_modulate:a", 0.0, 0.5)
	await fade_out.finished
	
	# Change the text while text is invisible
	title.text = new_title
	instructions.text = new_instructions
	details.text = new_details
	more_inst.text = new_more_inst
	
	# Fade the text back in
	var fade_in = create_tween()
	fade_in.tween_property(panel, "modulate:a", 0.6, 0.5)
	fade_in.parallel().tween_property(title, "modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(title, "outline_modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(instructions, "modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(instructions, "outline_modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(details, "modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(details, "outline_modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(more_inst, "modulate:a", 1.0, 0.5)
	fade_in.parallel().tween_property(more_inst, "outline_modulate:a", 1.0, 0.5)
	await fade_in.finished
	
	is_animating = false # Unlock the script so the player can proceed

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

func _on_right_hand_button_pressed(button_name: String) -> void:
	# If text currently fading, ignore button
	if is_animating:
		return
	# If "A" button pressed (Crouch)
	if button_name == "ax_button" and current_step == 0:
		under_table.visible = true
		under_table.process_mode = Node.PROCESS_MODE_INHERIT
		
		current_step = 1
		
		title_new = "Berlindung"
		instructions_new = "Berlindung di bawah meja, dan lindungi kepala dan leher Anda."
		details_new = "Bahaya terbesar dalam gempa bumi bukanlah runtuhnya bangunan, \
		melainkan benda jatuh dan pecahan kaca. Di kelas ini, jauhi jendela, \
		papan tulis, dan rak tinggi. Bertahan sepenuhnya di bawah meja."
		
		fade_to_new_text(title_new, instructions_new, details_new, more_inst_new)
	
	# If "B" button pressed (show evacuation)
	if button_name == "by_button" and current_step == 2:
		current_step = 3
		title_new = "Evakuasi"
		instructions_new = "Tetap tenang. Berjalanlah dengan teratur menuju pintu keluar."
		details_new = "Setelah guncangan benar-benar berhenti, segera tinggalkan kelas. \
		Jangan berlari, jangan panik, dan tinggalkan barang bawaan yang berat."
		more_inst_new = "(Tekan tombol 'A' untuk berdiri.)"
		
		fade_to_new_text(title_new, instructions_new, details_new, more_inst_new)
		
		exit_doors.visible = true
		exit_doors.process_mode = Node.PROCESS_MODE_INHERIT
	
func _on_under_table_body_entered(body: Node3D) -> void:
	if is_animating:
		return
	# Check if player entered under the table
	if body.name == "PlayerBody":
		# Only trigger if on step "Berlindung"
		if current_step == 1:
			title_new = "Bertahan"
			instructions_new = "Pegang meja dan bertahan sampai guncangan benar-benar berhenti."
			details_new = "Gempa bumi akan membuat tempat berlindung Anda terguncang di sekitar ruangan. \
			Pegang kaki meja dengan satu tangan, lindungi leher Anda dengan tangan lainnya, \
			dan bersiaplah terhadap guncangan gempa."
			more_inst_new = "(Tekan tombol 'B' untuk lanjut.)"
			
			fade_to_new_text(title_new, instructions_new, details_new, more_inst_new)
			
			current_step = 2
		
		under_table.visible = false
		under_table.process_mode = Node.PROCESS_MODE_DISABLED

func _on_exit_doors_body_entered(body: Node3D) -> void:
	if is_animating:
		return
	# Check if player entered under the table
	if body.name == "PlayerBody":
		# Only trigger if on step "Berlindung"
		if current_step == 3:
			# 1. Wait for the screen to go black
			await fade_to_black()
			
			# 2. Load the scene
			get_tree().change_scene_to_file("res://scenes/classroom.tscn")
