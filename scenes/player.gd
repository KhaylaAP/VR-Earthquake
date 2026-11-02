extends XROrigin3D

@onready var camera = $XRCamera3D 
@export var fall_limit := -3.0 

var hit_history: Array[String] = []
var obj_count := 0
var entered_safe := false
var entered_hazard := false
var entered_zone := ""

var reaction_time := 0.0
var is_timing := false

var is_menu_locked := false
##asd
var flat_mode := false
##asd
func _ready() -> void:
	## 1. Save the exact global spawn point the moment the scene loads
	## before the VR headset has a chance to move anything!
	#var target_spawn_pos = global_position
	#
	#await get_tree().create_timer(0.1).timeout
	#
	#if camera != null:
		## 2. Fix the Rotation (Spin the world)
		#var camera_yaw = camera.transform.basis.get_euler().y
		#rotate_y(-camera_yaw)
		#
		## 3. Fix the Position (Using GLOBAL coordinates)
		## Find out exactly where their actual head ended up AFTER the spin
		#var current_head_pos = camera.global_position
		#
		## Calculate the exact distance between their head and the target spawn
		#var offset_x = target_spawn_pos.x - current_head_pos.x
		#var offset_z = target_spawn_pos.z - current_head_pos.z
		#
		## Slide the Origin by that exact distance on the X and Z axes
		#global_position.x += offset_x
		#global_position.z += offset_z
		
	# 1. Save the exact editor spawn coordinates before the headset moves anything
	var spawn_pos = global_position
	
	# Give the Meta Quest tracking time to fully initialize (0.2 is safer than 0.1 for mobile VR)
	await get_tree().create_timer(0.2).timeout
	
	if camera != null:
		# 2. Fix the Rotation: Look at how far they physically turned, and counter-rotate the Origin
		var local_yaw = camera.transform.basis.get_euler().y
		rotate_y(-local_yaw)
		
		# 3. Fix the Position: Grab their physical walk distance from the center of their real room
		var local_walk_offset = camera.position
		
		# We ignore the Y axis so we don't accidentally offset their height and push them through the floor!
		local_walk_offset.y = 0 
		
		# 4. Slide the entire origin backward by exactly the distance they walked
		global_position = spawn_pos - (transform.basis * local_walk_offset)
	
##asd
	flat_mode = not (XRServer.primary_interface and XRServer.primary_interface.is_initialized())
	
func _input(event: InputEvent) -> void:
	if not flat_mode:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clampf(camera.rotation.x, -1.4, 1.4)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1:
				var inst = _get_instructions()
				if inst:
					inst._on_right_hand_button_pressed("ax_button")
			KEY_F2:
				var inst = _get_instructions()
				if inst:
					inst._on_right_hand_button_pressed("by_button")
			KEY_F3:
				_on_left_hand_button_pressed("grip_click")
	

func _get_instructions() -> Node:
	return get_tree().root.find_child("PlayerInstructions", true, false)
##asd

# The Fall Boundary (Kill Z) remains the same
func _process(delta: float) -> void:
	if is_timing:
		reaction_time += delta
		
	##asd
	if flat_mode:
		var dir := Vector3.ZERO
		if Input.is_key_pressed(KEY_W): dir -= global_transform.basis.z
		if Input.is_key_pressed(KEY_S): dir += global_transform.basis.z
		if Input.is_key_pressed(KEY_A): dir -= global_transform.basis.x
		if Input.is_key_pressed(KEY_D): dir += global_transform.basis.x
		dir.y = 0
		global_position += dir.normalized() * 2.0 * delta
	##asd
		
	if camera != null:
		if camera.global_position.y < fall_limit:
			get_tree().reload_current_scene()

func start_reaction_timer() -> void:
	is_timing = true
	reaction_time = 0.0
	entered_safe = false
	entered_hazard = false
	entered_zone = ""

func lock_menu() -> void:
	is_menu_locked = true
	
func unlock_menu() -> void:
	is_menu_locked = false

func _on_left_hand_button_pressed(node_name: String) -> void:
	if node_name == "grip_click":
		if is_menu_locked:
			return
		var player_menu = get_tree().root.find_child("PlayerMenu", true, false)
		
		if player_menu:
			if player_menu.visible == true:
				player_menu.visible = false
				player_menu.process_mode = Node.PROCESS_MODE_DISABLED
			else:
				player_menu.visible = true
				player_menu.process_mode = Node.PROCESS_MODE_INHERIT

func _on_player_head_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body.freeze == true:
			return
		var obj_name = body.name
		obj_count += 1
		hit_history.append(obj_name)
		
		var earthquake_node = get_node_or_null("../KelasModel/ClassroomStructure")
		if earthquake_node and earthquake_node.has_method("end_simulation_early"):
			earthquake_node.end_simulation_early()

func _on_under_table_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_safe:
			entered_safe = true
			entered_zone = "Under Table"
			is_timing = false
			print("SUCCESS: Player reached cover in ", reaction_time, " seconds.")

func _on_near_window_right_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Near Window Right"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")

func _on_near_window_left_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Near Window Left"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")

func _on_under_ceiling_lights_body_entered(body: Node3D) -> void:
	if body is XRToolsPlayerBody:
		if not entered_hazard:
			entered_hazard = true
			entered_zone = "Under Ceiling Lights"
			is_timing = false
			print("DANGER: Player entered hazard zone in ", reaction_time, " seconds.")
