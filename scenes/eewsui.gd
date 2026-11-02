extends Label3D

@onready var warning_audio: AudioStreamPlayer = $WarningAudio
@onready var phone_sprite: Sprite3D = $PhoneSprite
@onready var display_sprite: Sprite3D = $DisplaySprite
@onready var jarak_label: Label3D = $JarakLabel
@onready var tangal_jam_label: Label3D = $TangalJamLabel

var is_counting_down := false
var time_left := 0.0
var current_intensity := 0.0
var base_display_width_m := 0.0

func _ready() -> void:
	# Ensure it starts completely invisible
	modulate.a = 0.0
	outline_modulate.a = 0.0
	phone_sprite.modulate.a = 0.0
	display_sprite.modulate.a = 0.0
	jarak_label.modulate.a = 0.0
	tangal_jam_label.modulate.a = 0.0
	
	
	if display_sprite.texture:
		base_display_width_m = display_sprite.texture.get_width() * display_sprite.pixel_size
	

# This runs every frame to update the text!
func _process(delta: float) -> void:
	if is_counting_down:
		time_left -= delta
		
		if time_left > 0:
			# Update the text with the live countdown.
			# ceil() rounds the decimal up (so 2.1 seconds shows as "3")
			text = "Dalam %d detik" % [int(ceil(time_left))]
		else:
			# Time is up! Stop counting and fade out.
			is_counting_down = false
			hide_warning()

# This function will be called by your earthquake controller
func trigger_warning(phone_texture_path: String, distance_km: float, datetime_label: String, countdown_seconds: float) -> void:
	if ResourceLoader.exists(phone_texture_path):
		var tex := load(phone_texture_path)
		display_sprite.texture = tex
		
		if base_display_width_m > 0.0 and tex and tex.get_width() > 0:
			display_sprite.pixel_size = base_display_width_m / tex.get_width()
	else:
		push_error("Tekstur HP tidak ditemukan: " + phone_texture_path)
	
	jarak_label.text = "%.0f km" % distance_km
	tangal_jam_label.text = datetime_label
	
	time_left = countdown_seconds
	is_counting_down = true
	
	warning_audio.play()
	
	# Fade IN smoothly
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(self, "outline_modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(phone_sprite, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(display_sprite, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(jarak_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(tangal_jam_label, "modulate:a", 1.0, 0.5)

# A dedicated function to hide the UI when time is up
func hide_warning() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "outline_modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(phone_sprite, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(display_sprite, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(jarak_label, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(tangal_jam_label, "modulate:a", 0.0, 1.0)
