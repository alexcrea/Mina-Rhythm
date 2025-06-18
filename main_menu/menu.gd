extends CanvasLayer

var editor_scene:= preload("res://editor/editor.tscn")
var import_dialog: String
var show_import_dialog: bool
signal import(songs:PackedStringArray)

func _on_control_add_songs_pressed() -> void:
	$FileDialog.visible = true

func _on_file_dialog_files_selected(paths: PackedStringArray) -> void:
	import_dialog = ""
	print("Attempting to load minapaks")
	var failed := []
	var success := []
	var exists := []
	for path in paths:
		var pass_code = await Global.pak_reader.import_minapak(path)
		var file_name = pass_code.substr(pass_code.find(": ") + 2, pass_code.length())  # Extract the name after ": "
		var err_code = pass_code.substr(0, pass_code.find(": "))  # Extract the error code before ": "
	
		match err_code:
			"failed":
				failed.append(file_name)
			"exists":
				exists.append(file_name)
			"success":
				success.append(file_name)
	if !failed.is_empty():
		import_dialog += "Failed: "
		for f in failed.size():
			import_dialog += failed[f] + str(", " if f != failed.size() - 1 else " ")
	if !exists.is_empty():
		import_dialog += "Already exists: "
		for e in exists.size():
			import_dialog += exists[e] + str(", " if e != exists.size() - 1 else " ")
	if !success.is_empty():
		import_dialog += "Success: "
		for s in success.size():
			import_dialog += success[s] + str(", " if s != success.size() - 1 else " ")
	show_import_dialog = true
	emit_signal("import",success)

#could be replaced by a signal instead of process
func _process(_delta: float) -> void:
	if show_import_dialog:
		if import_dialog.length() > 2:
			%AcceptDialog.dialog_text = import_dialog
		else:
			%AcceptDialog.dialog_text = "Something went very Very wrong...."
		%AcceptDialog.title = "import status"
		%AcceptDialog.visible = true
		import_dialog = ""
		show_import_dialog = false

func _on_button_pressed() -> void:
	pass
	#$ColorRect.visible = true
	#var tween = create_tween()
	#tween.set_trans(Tween.TRANS_QUINT)
	#tween.tween_property($ColorRect,"position:x",0,1).set_ease(Tween.EASE_IN_OUT)
	#await tween.finished
	#await Global.clear_temp()
	#get_tree().change_scene_to_packed(editor_scene)

func _on_button_mouse_entered() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button/Control2/ColorRect,"position:x",1.5,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button/Control/Label,"position:x",3,0.4).set_ease(Tween.EASE_IN_OUT)

func _on_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button/Control2/ColorRect,"position:x",-20,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button/Control/Label,"position:x",-325,0.4).set_ease(Tween.EASE_IN_OUT)

func _on_button_2_pressed() -> void:
	$Panel/Button2.disabled = true
	$SettingsPanel.show()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($SettingsPanel,"position:x",867,0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$SettingsPanel/Exit.disabled = false

func _on_button_2_mouse_entered() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button2/Control2/ColorRect,"position:x",0,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button2/Control/Label,"position:x",1,0.4).set_ease(Tween.EASE_IN_OUT)

func _on_button_2_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button2/Control2/ColorRect,"position:x",30,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Panel/Button2/Control/Label,"position:x",70,0.4).set_ease(Tween.EASE_IN_OUT)
