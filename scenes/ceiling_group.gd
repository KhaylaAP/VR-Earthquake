extends Node3D

@onready var solid_ceiling = $SolidCeiling
@onready var destroyed_ceiling = $DestroyedCeiling
@onready var anim_player = $DestroyedCeiling/AnimationPlayer

# Dulu dalam skala "intensity" lama (5.0 / 5.5). Sekarang dalam satuan g (PGA).
# Sesuaikan kedua nilai ini sesuai hasil uji coba di headset.
@export var flicker_threshold_g := 0.15
@export var partial_collapse_threshold_g := 0.3
@export var total_collapse_threshold_g := 0.5

func _ready() -> void:
	# This single line forces Godot to generate a new, unique random seed
	# every single time the scene loads.
	randomize()
	# Ensure the correct visibility when the game starts
	solid_ceiling.show()
	destroyed_ceiling.hide()

func start_quake_flicker(current_pga_g: float) -> void:
	if current_pga_g >= flicker_threshold_g:
		for child in solid_ceiling.get_children():
			if child.name.begins_with("CeilingLight"):
				var light_anim = child.get_node_or_null("AnimationPlayer")
				if light_anim:
					light_anim.play("quake_flicker")

# Your main earthquake script will automatically call this when the quake starts
# (data sudah hanya berisi gelombang-S, jadi dipanggil segera, bukan menunggu)
func check_earthquake_stress(current_pga_g: float) -> void:
	if current_pga_g >= partial_collapse_threshold_g:
		await get_tree().create_timer(12.0).timeout
		
		# Find all the lights in the solid ceiling and play their flicker animation
		for child in solid_ceiling.get_children():
			if child.name.begins_with("CeilingLight"):
				var light_anim = child.get_node_or_null("AnimationPlayer")
				if light_anim:
					light_anim.play("power_fail")
					
		# Turn off the lights in the Destroyed Ceiling at the same time!
		for piece in destroyed_ceiling.get_children():
			for child in piece.get_children():
				if child.name.begins_with("CeilingLight"):
					var light_anim = child.get_node_or_null("AnimationPlayer")
					if light_anim:
						light_anim.play("power_fail")
						
		# Wait for both light to flicker and die
		await get_tree().create_timer(2.0).timeout
		
		# Instantly swap the meshes so the player doesn't see a seam
		solid_ceiling.hide()
		destroyed_ceiling.show()
		
		if current_pga_g >= total_collapse_threshold_g:
			# Total Collapse
			anim_player.play("ceiling_collapse")
		else:
			# Partial Collapse: Drop only 1 random piece
			var pieces = [
				$DestroyedCeiling/Ceiling1,
				$DestroyedCeiling/Ceiling2,
				$DestroyedCeiling/Ceiling3,
				$DestroyedCeiling/Ceiling4
			]
			
			var random_piece = pieces.pick_random()
			print("THE RANDOM PIECE PICKED IS: ", random_piece.name)
			random_piece.freeze = false
