extends Panel

func _ready() -> void:
	var volume_keys = ["master_volume", "music_volume", "effects_volume"]
	var volume_nodes = [$Volume/Master, $Volume/Music, $Volume/Effects]

	for i in volume_keys.size():
		var key = volume_keys[i]
		var node = volume_nodes[i]
		var db_val = Global.Settings.get(key, 0)
		
		var linear_val: float
		if db_val == -INF:
			linear_val = 0
		else:
			if typeof(db_val) == TYPE_FLOAT and (is_nan(db_val) or db_val == INF):
				db_val = 0
			linear_val = db_to_linear(db_val) * 100.0

		node.value = linear_val
		_on_VolumeSlider_value_changed(linear_val, i)

func _on_VolumeSlider_value_changed(value: float,VolSlider):
	VolSlider = $Volume.get_child(VolSlider)
	if VolSlider == null:
		return
	var id = VolSlider.get_meta("id")
	var label = VolSlider.find_child("Value")
	if id == null || label == null:
		return
	value /= 100
	AudioServer.set_bus_volume_db(id, linear_to_db(value))
	label.text = "Volume: " + str(round(value*100)) + "%"
	Global.Settings[VolSlider.name.to_lower()+"_volume"] = linear_to_db(value)
	Global.save_json_dict(Global.settings_file,Global.Settings)

func _on_exit_pressed() -> void:
	$Exit.disabled = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self,"position:x",1152,0.5).set_ease(Tween.EASE_OUT)
	await tween.finished
	$"/root/CanvasLayer/Panel/Button2".disabled = false
	self.hide()

func _on_exit_mouse_entered() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Exit/Control2/ColorRect,"position:x",1.5,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Exit/Control/Label,"position:x",-280,0.4).set_ease(Tween.EASE_IN_OUT)

func _on_exit_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Exit/Control2/ColorRect,"position:x",-30,0.4).set_ease(Tween.EASE_IN_OUT)
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property($Exit/Control/Label,"position:x",-380,0.4).set_ease(Tween.EASE_IN_OUT)
