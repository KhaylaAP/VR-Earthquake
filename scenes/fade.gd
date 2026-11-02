extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. Grab the material
	var fade_material = get_active_material(0)
	
	if fade_material != null:
		# 2. Force it to be completely black the exact millisecond the scene loads
		fade_material.albedo_color.a = 1.0
		
		# 3. Create a tween to fade it back to perfectly clear over 1.5 seconds
		var tween = create_tween()
		tween.tween_property(fade_material, "albedo_color:a", 0.0, 1.5)
