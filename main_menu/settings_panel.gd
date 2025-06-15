extends Panel

func _ready() -> void:
	#Theres a better way to do this, I'm just lazy
	$Volume/Master.value = db_to_linear(Global.Settings.get("master_volume",0))*100
	$Volume/Music.value = db_to_linear(Global.Settings.get("music_volume",0))*100
	$Volume/Effects.value = db_to_linear(Global.Settings.get("effects_volume",0))*100

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
