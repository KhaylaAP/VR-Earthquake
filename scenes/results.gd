extends Label3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	outline_modulate.a = 0.0

func show_results(objects: Array[String], count: int) -> void:
	var obj_list = ", ".join(objects)
	# Update the text dynamically
	if count != 0:
		text = "Kepala Anda terkena oleh: %s \nJumlah Benturan: %d" % [obj_list, count]
	else:
		text = "Anda sama sekali tidak terbentur objek!"
	
	var tween = create_tween()
	# Tween the alpha (a) channel of the modulate property to 1.0 (fully visible) over 0.5 seconds
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "outline_modulate:a", 1.0, 0.5)
	
func _on_left_hand_button_pressed(btn_name: String) -> void:
	if btn_name == "grip_click":
		# Fade it back out to 0.0 over 1 second
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.parallel().tween_property(self, "outline_modulate:a", 0.0, 1.0)
