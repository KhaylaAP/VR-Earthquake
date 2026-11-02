# Skrip Ruangan Kelas (Pengendali Gempa) - versi playback rekaman seismik
# Guncangan dibaca dari data displacement nyata (quake_*.json, dibuat oleh
# prepare_quake_data.py). Data HANYA berisi gelombang-S; gelombang-P dipakai
# sebagai peringatan dini saja (tidak menggerakkan ruangan).
extends AnimatableBody3D

# Mode Admin
# Jika true, simulasi tidak akan mulai secara otomatis.
@export var admin_mode := false

@export_category("Earthquake Settings")
# Waktu dari mulai simulasi sampai jaringan sensor "mendeteksi" gelombang-P.
# Ini murni pilihan desain skenario, bukan angka dari data.
@export var pre_detection_delay := 5.0
# Besaran referensi dimana pengali = 1.0 (tidak menguatkan/melemahkan data asli)
@export var baseline_intensity := 5.0
# Seberapa kuat guncangan dibanding rekaman asli. Nilai default 9 sengaja
# melebihi baseline supaya langsung berada di batas atas (max_intensity_multiplier),
# sama seperti pengaturan lama yang paling terasa intens.
@export var intensity := 9.0
# Batas atas pengali intensitas, sama seperti clamp di skrip lama (dulu 8.0)
@export var max_intensity_multiplier := 8.0

# Pengaturan playback data rekaman
@export_group("Data Rekaman Gempa")
# Daftar rekaman yang tersedia. Urutan di sini = urutan di dropdown menu admin.
@export var record_paths: Array[String] = [
	"res://assets/datas/megathrust_selatan_jawa.json",
	"res://assets/datas/sesar_baribis.json",
	"res://assets/datas/sesar_cimandiri.json",
	"res://assets/datas/sesar_garsela.json",
	"res://assets/datas/sesar_lembang.json",
]
# Rekaman yang dipakai jika tidak ada yang dipilih (mode normal / tanpa dropdown)
@export var default_record_index := 0
# Batas kenyamanan VR: displacement puncak ruangan tidak akan melebihi ini.
@export var max_displacement_m := 0.75
# Putar arah guncangan horizontal terhadap ruangan (derajat, sumbu Y).
@export_range(-180.0, 180.0) var horizontal_rotation_deg := 0.0

# Referensi Node
@onready var rumble_audio: AudioStreamPlayer3D = $RumbleAudio
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var ground_dust_particles: GPUParticles3D = $GroundDustParticles

# Data rekaman yang sedang dipakai (diisi oleh _load_record)
var record_loaded := false
var record_label := ""
var record_target_pga_g := 0.15
var record_dt := 0.01
var record_count := 0
var record_x := PackedFloat32Array() # East
var record_y := PackedFloat32Array() # Up
var record_z := PackedFloat32Array() # North
var record_peak_accel_g := 1.0
var record_peak_vel_mps := 1.0
var record_peak_disp_m := 1.0
var record_warning_lead_time_s := 10.0 # Jeda nyata P -> S, dari data
var record_phone_texture := "res://images/phone_transparent.png"
var record_distance_km := 0.0
var record_datetime_label := ""

# Diisi dari data rekaman
var total_duration := 20.0 # Durasi guncangan gelombang-S (detik)

# Variabel State
var time_passed := 0.0
var is_quaking := false
var simulation_started := false
var initial_position: Vector3
var has_quake_started := false
var exact_time_survived := 0.0
var player_was_hit := false
var quake_gain := 0.02
var rumble_max_db := 0.0
var prev_offset := Vector3.ZERO
var speed_smooth := 0.0

func _ready() -> void:
	initial_position = global_position
	
	if not admin_mode:
		begin_simulation(randi() % record_paths.size())

# Daftar label semua rekaman, untuk mengisi dropdown menu admin
func get_record_labels() -> Array[String]:
	var labels: Array[String] = []
	for path in record_paths:
		var label := path.get_file().get_basename()
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has("label"):
				label = parsed["label"]
		labels.append(label)
	return labels

# Membaca satu file JSON hasil preprocessing. Mengembalikan false jika gagal.
func _load_record(path: String) -> bool:
	record_loaded = false
	
	if not FileAccess.file_exists(path):
		push_error("Data gempa tidak ditemukan: " + path)
		return false
	
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Data gempa tidak valid: " + path)
		return false
	
	record_label = parsed.get("label", path.get_file().get_basename())
	record_target_pga_g = float(parsed.get("target_pga_g", 0.15))
	record_phone_texture = parsed.get("phone_texture", "res://images/phone_transparent.png")
	record_distance_km = float(parsed.get("distance_km", 0.0))
	record_datetime_label = parsed.get("datetime_label", "")
	record_dt = parsed["dt"]
	record_x = PackedFloat32Array(parsed["x"])
	record_y = PackedFloat32Array(parsed["y"])
	record_z = PackedFloat32Array(parsed["z"])
	record_count = record_x.size()
	record_peak_accel_g = parsed["peak_accel_g"]
	record_peak_vel_mps = parsed["peak_vel_mps"]
	record_peak_disp_m = parsed["peak_disp_m"]
	total_duration = parsed["duration_s"]
	record_warning_lead_time_s = parsed.get("warning_lead_time_s", 10.0)
	
	record_loaded = true
	print("Data gempa dimuat: '%s' | %d sampel | %.1f detik | peringatan %.1f detik" % [
		record_label, record_count, total_duration, record_warning_lead_time_s])
	return true

# Pengali amplitudo: menggabungkan kekuatan target rekaman (target_pga_g)
# dengan pengali intensity manual, dibatasi max_intensity_multiplier
# (persis logika clamp di skrip lama).
func _compute_gain() -> float:
	var raw_multiplier: float = pow(10, intensity - baseline_intensity)
	var realistic_multiplier: float = clamp(raw_multiplier, 0.0001, max_intensity_multiplier)
	var target_g: float = record_target_pga_g * realistic_multiplier
	var gain: float = target_g / record_peak_accel_g
	gain = minf(gain, max_displacement_m / record_peak_disp_m)
	return gain

# Membaca offset ruangan pada waktu t (interpolasi linier antar sampel)
func _sample_offset(t: float) -> Vector3:
	var i := int(t / record_dt)
	if i >= record_count - 1:
		return Vector3.ZERO
	
	var x := record_x[i]
	var y := record_y[i]
	var z := record_z[i]
	
	var h := Vector3(x, y, z).rotated(Vector3.UP, deg_to_rad(horizontal_rotation_deg))
	return Vector3(h.x, y, h.z) * quake_gain

# Fungsi memulai simulasi
# Dipanggil sekali oleh tombol pemilihan gempa (earthquake_options),
# langsung dengan indeks rekaman yang dipilih. Intensity dibaca dari
# @export di atas, tidak lagi diatur lewat slider.
func begin_simulation(record_index: int) -> void:
	if simulation_started:
		return
	
	if record_index < 0 or record_index >= record_paths.size():
		push_error("Indeks rekaman tidak valid: %d" % record_index)
		return
	if not _load_record(record_paths[record_index]):
		return
	
	simulation_started = true
	
	var player_node = get_node_or_null("../../XROrigin3D")
	var eews_node = get_node_or_null("../../XROrigin3D/XRCamera3D/EEWSUI")
	
	if player_node and player_node.has_method("lock_menu"):
		player_node.lock_menu()
	
	# TAHAP 1: menunggu sampai gelombang-P "terdeteksi" (murni desain skenario)
	await get_tree().create_timer(pre_detection_delay).timeout
	
	# Peringatan muncul TEPAT saat P terdeteksi, dengan hitung mundur = jeda
	# nyata P -> S dari data (record_warning_lead_time_s), bukan angka buatan.
	if eews_node:
		eews_node.trigger_warning(record_phone_texture, record_distance_km, record_datetime_label, record_warning_lead_time_s)
	
	if player_node:
		player_node.start_reaction_timer()
	
	# TAHAP 2: menunggu sampai gelombang-S benar-benar tiba
	await get_tree().create_timer(record_warning_lead_time_s).timeout
	trigger_earthquake()

# Fungsi pemicu gempa (gelombang-S mulai bergetar)
func trigger_earthquake() -> void:
	if not record_loaded:
		push_error("Gempa dibatalkan: data rekaman belum dimuat.")
		return
	
	if not is_quaking:
		is_quaking = true
		time_passed = 0.0
		has_quake_started = false
		prev_offset = Vector3.ZERO
		speed_smooth = 0.0
		
		quake_gain = _compute_gain()
		
		# PGA yang benar-benar akan terasa di sesi ini, dalam satuan g.
		var actual_pga_g := record_peak_accel_g * quake_gain
		
		print("Gempa '%s' dimulai. intensity %.1f | gain x%.1f | PGA ~%.3f g | disp puncak ~%.1f cm" % [
			record_label, intensity, quake_gain, actual_pga_g, record_peak_disp_m * quake_gain * 100.0])
		
		# Perhitungan debu dinamis berdasarkan PGA aktual
		var final_dust_amount := 1
		if actual_pga_g >= 0.09:
			var visual_multiplier = clamp(actual_pga_g / 0.15, 0.1, 3.0)
			var base_dust_amount := 40
			final_dust_amount = clampi(int(base_dust_amount * visual_multiplier), 5, 150)
		else:
			final_dust_amount = 1

		dust_particles.amount = final_dust_amount
		ground_dust_particles.amount = final_dust_amount
		dust_particles.emitting = true
		ground_dust_particles.emitting = true
		
		# Karena data sudah hanya berisi gelombang-S, stress benda-benda
		# langsung dipicu di awal guncangan.
		# CATATAN: wall_objects.gd & ceiling_group.gd masih membandingkan
		# nilai ini terhadap threshold lama (4.5 / 5.0 / 5.5, skala intensity).
		# Ini perlu ditulis ulang dalam satuan g sebelum baris ini benar.
		get_tree().call_group("drop_objects", "check_earthquake_stress", actual_pga_g)
		get_tree().call_group("drop_objects", "start_quake_flicker", actual_pga_g)
		
		# Volume gemuruh maksimum berdasarkan PGA aktual
		if actual_pga_g < 0.02:
			rumble_max_db = -50.0
		elif actual_pga_g < 0.09:
			rumble_max_db = -30.0
		else:
			rumble_max_db = 0.0
		rumble_audio.volume_db = rumble_max_db - 40.0
		rumble_audio.play()
		
func end_simulation_early() -> void:
	if is_quaking and not player_was_hit:
		print("PLAYER WAS HIT! Recording timestamp: ", time_passed)
		player_was_hit = true
		exact_time_survived = time_passed

func _physics_process(delta: float) -> void:
	if is_quaking:
		time_passed += delta
		
		if time_passed >= total_duration:
			is_quaking = false
			global_position = initial_position
			rotation = Vector3.ZERO
			
			rumble_audio.stop()
			dust_particles.emitting = false
			ground_dust_particles.emitting = false
			
			if not player_was_hit:
				exact_time_survived = total_duration
			
			var structure_node = get_node_or_null("../../../../Zones") 
			if structure_node and structure_node.has_method("call_exit_area"):
				structure_node.call_exit_area()
			
			var results_node = get_node_or_null("../../../../XROrigin3D/XRCamera3D/Results")
			var player_node = get_node_or_null("../../../../XROrigin3D")
			if results_node and player_node:
				player_node.unlock_menu()
				
				DataLogging.save_session_data(
					record_target_pga_g,
					player_node.obj_count,
					player_node.hit_history,
					exact_time_survived,
					player_node.reaction_time,
					player_node.entered_zone,
					player_node.entered_safe,
					player_node.entered_hazard
				)
				
				DataLogging.advance_to_next_subject()
				results_node.show_results(player_node.hit_history, player_node.obj_count)
			
			if admin_mode:
				var player_menu = get_tree().root.find_child("PlayerMenu", true, false)
				if player_menu:
					if player_menu.visible == true:
						player_menu.visible = false
						player_menu.process_mode = Node.PROCESS_MODE_DISABLED
					else:
						player_menu.visible = true
						player_menu.process_mode = Node.PROCESS_MODE_INHERIT
			return
		
		var offset := _sample_offset(time_passed)
		#global_position = initial_position + offset
		
		var ss_amplification := 1.3
		var amplification_offset = offset * ss_amplification
		var target_position = initial_position + amplification_offset
		
		global_position = global_position.lerp(target_position, delta * 35.0)
		
		var speed := (offset - prev_offset).length() / delta
		prev_offset = offset
		speed_smooth = lerpf(speed_smooth, speed, clampf(delta * 5.0, 0.0, 1.0))
		var ref_speed := record_peak_vel_mps * quake_gain
		var level := clampf(speed_smooth / ref_speed, 0.01, 1.0)
		rumble_audio.volume_db = rumble_max_db + linear_to_db(level)
		
func get_record_info(index: int) -> Dictionary:
	if index < 0 or index >= record_paths.size():
		return {}
	
	var path = record_paths[index]
	if not FileAccess.file_exists(path):
		return {}
	
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	
	return {
		"label": parsed.get("label", path.get_file().get_basename()),
		"distance_km": float(parsed.get("distance_km", 0.0)),
		"golden_time_display_s": float(parsed.get("golden_time_display_s", parsed.get("warning_lead_time_s", 10.0))),
		"magnitude_mw": float(parsed.get("magnitude_mw", 0.0)),
	}
