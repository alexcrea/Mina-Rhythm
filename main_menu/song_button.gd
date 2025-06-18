extends Control

@export var internal_button:Button
@export var label:Label
var audioplayer: AudioStreamPlayer
signal pressed(int)
var id

func _ready() -> void:
	if id == 0:
		_on_button_pressed()

func get_id() -> int:
	return id

func _on_button_pressed() -> void:
	emit_signal("pressed",id)

#func _on_button_focus_entered() -> void:
	#emit_signal("pressed",id)

#func _on_button_mouse_entered() -> void:
	#internal_button.grab_focus()
