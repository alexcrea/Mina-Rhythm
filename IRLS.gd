extends Node
class_name IRLS
#import reload load system
signal IRLS_import(data: String)

func _ready() -> void:
	Global.connect("imported",Callable(self,"_on_restart"))

func import_to_res(path: String, restart := true, restart_scene := "res://menu.tscn", restart_data := ""):
	path = path.replace('\\','/')
	
	if path != "" and FileAccess.file_exists(path):
		var imported_file = FileAccess.open(str("res://temp/", path.get_slice('/', path.get_slice_count('/') - 1)), FileAccess.WRITE)
		imported_file.store_buffer(FileAccess.get_file_as_bytes(path))
		imported_file.close()
	
	if restart:
		Global.restart_game(restart_scene, str("import\n",restart_data))

func _on_restart(data: String):
	var line_count = data.get_slice_count('\n')
	
	for i in range(line_count):
		var slice = data.get_slice('\n', i)
		
		# Handle specific string data
		if slice.strip_edges().strip_escapes() == "IRLS_IMPORT":
			print(data.get_slice('\n', i+1))
			emit_signal("IRLS_import",data.get_slice('\n', i+1))
		
		###DEPERACATED

		## Check if the slice is a valid callable string (or if the callable is passed correctly)
		#if Callable(slice).is_valid():
			#Callable(slice).call()
		#else:
			#print("Invalid Callable: ", slice)
