# Skrip perekaman data (Data Logging Manager)
# Autoload yang berjalan secara global untuk menyimpan hasil simulasi VR
extends Node

# Menyimpan path untuk file hasil data CSV dan file pelacak ID subjek
var csv_path := ""
var tracker_path := ""

# Menyimpan nomor subjek saat ini
var current_subject_number := 1

func _ready() -> void:
	# Meminta izin penyimpanan dasar jika berjalan di perangkat android (Quest 3)
	if OS.get_name() == "Android":
		OS.request_permissions()

	# Path Android
	#csv_path = "/storage/emulated/0/Download/simulation_results.csv"
	#tracker_path = "/storage/emulated/0/Download/subject_tracker.txt"
	
	# Path Komputer
	csv_path = "user://simulation_results.csv"
	tracker_path = "user://subject_tracker.txt"
	
	# Saat aplikasi dibuka, cek apakah sudah ada subjek sebelumnya,
	# Jika ada, baca nomor terakhir agar tidak menimpa data subjek lama
	if FileAccess.file_exists(tracker_path):
		var file = FileAccess.open(tracker_path, FileAccess.READ)
		current_subject_number = file.get_as_text().to_int()
		file.close()

# Menghasilkan ID string dengan format 3 digit ("Subject_001")
func get_player_id() -> String:
	return "Subject_%03d" % current_subject_number

# Fungsi utama untuk menulis hasil uji coba ke dalam file CSV
func save_session_data(intensity: float, hit_count: int, hit_objects: Array[String], time_survived: float, reaction_time: float, entered_zone: String, entered_safe: bool, entered_hazard: bool) -> void:
	var file: FileAccess
	
	# Periksa apakah ini pertama kalinya CSV dibuat
	var is_new_file = not FileAccess.file_exists(csv_path)
		
	if is_new_file:
		# Jike file baru, buka mode WRITE dan buat header kolom CSV
		file = FileAccess.open(csv_path, FileAccess.WRITE)
		file.store_line("Player ID,Intensity,Hit Count,Objects Hit,Time Survived,Reaction Time,Zone Entered,Reached Safety,Entered Hazard")
	else:
		# Jika file sudah ada, buka mode READ_WRITE dan lompat ke baris paling bawah
		file = FileAccess.open(csv_path, FileAccess.READ_WRITE)
		file.seek_end() 

	if file:
		# Penyusunan Data
		# Jika pengguna terbentur objek, gabungkan array menjadi satu string
		# Dibungkus dengan tanda kutip ganda agar koma di dalam objek tidak merusak format CSV
		var object_string := "None"
		if hit_objects.size() > 0:
			object_string = '"%s"' % ", ".join(hit_objects)
			
		var reaction_string := "None"
		var zone_string := "None"
		
		# Hanya simpan waktu reaksi jika subjek benar bergerak ke zona evakuasi
		if entered_zone != "":
			reaction_string = "%.2f" % reaction_time
			zone_string = entered_zone
			
		var player_id = get_player_id()
		
		# Menggabungkan semua variabel menjadi satu baris teks dengan format CSV
		var data_row = "%s,%.1f,%d,%s,%.2f,%s,%s,%s,%s" % [
			player_id,
			intensity,
			hit_count,
			object_string,
			time_survived,
			reaction_string,
			zone_string,
			str(entered_safe),
			str(entered_hazard)
		]
		
		# Tulis data ke file dan tutup secara aman untuk mencegah kebocoran memori
		file.store_line(data_row)
		file.close()
		print("SUCCESS: Data saved for ", player_id)
		print("Row Data: ", data_row)
	else:
		# Peringatan error jika Quest 3 gagal membuka file
		printerr("ERROR: Could not open the CSV file to save data.")

# Dipanggil saat layar hasil VR ditutup, menyimpan ID subjek baru ke file teks
# Jika Quest 3 di restart, urutan subjek tidak akan kembali ke 1
func advance_to_next_subject() -> void:
	current_subject_number += 1
	var file = FileAccess.open(tracker_path, FileAccess.WRITE)
	file.store_string(str(current_subject_number))
	file.close()
