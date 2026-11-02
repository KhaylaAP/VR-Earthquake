extends RigidBody3D

# Dulu dalam skala "intensity" lama (4.5). Sekarang dalam satuan g (PGA),
# supaya cocok dengan actual_pga_g yang dikirim dari classroom_structure.gd.
# 0.3g dipilih sebagai perkiraan kasar titik dimana benda mulai tergelincir/
# terguling (tergantung tinggi & lebar dasar benda) - sesuaikan sesuai uji coba.
@export var break_intensity_threshold := 0.3 

@onready var wall_joint = get_node_or_null("Generic6DOFJoint3D")

var has_fallen := false

func _ready() -> void:
	print(name, " wall_joint found: ", wall_joint != null)
	
# Dipanggil dari classroom_structure.gd, sekarang menerima PGA aktual (g),
# bukan angka intensity lama.
func check_earthquake_stress(current_pga_g: float) -> void:
	# If the quake is strong enough, snap the joint!
	if current_pga_g >= break_intensity_threshold:
		snap_and_fall()

func snap_and_fall() -> void:
	if has_fallen:
		return
	has_fallen = true

	if wall_joint != null:
		wall_joint.queue_free()
	
	# Lepaskan dari ClassroomStructure supaya benda tidak lagi ikut
	# bergoyang bersama ruangan - benda jadi objek fisika bebas,
	# posisi globalnya dipertahankan supaya tidak ada lompatan visual.
	var world_transform := global_transform
	var old_parent := get_parent()
	var scene_root := get_tree().current_scene  # ambil referensi SEBELUM remove_child
	
	if old_parent != null and scene_root != null:
		old_parent.remove_child(self)
		scene_root.add_child(self)
		global_transform = world_transform
	
	freeze = false
