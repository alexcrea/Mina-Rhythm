extends Control

@export var internal_button:Button
@export var label:Label
signal pressed(int)
var id

var _is_highlighted = false

func _ready() -> void:
	if id == 0:
		_on_button_pressed()

func get_id() -> int:
	return id

func _on_button_pressed() -> void:
	emit_signal("pressed",id)
	_on_button_focus_entered()

#Scrapped because of vbox being dumb and not allowing for position changes of children
#
#var select_tween:Tween = null
#
#if !select_tween:
			#position.x +=10
			#select_tween.set_ease(Tween.EASE_OUT)
			#select_tween.tween_property(self,"position:y",self.position.y-10,0.4).set_trans(Tween.TRANS_CUBIC)

func _on_button_focus_entered() -> void:
	if !_is_highlighted:
		var style:StyleBoxFlat = $PanelContainer.get_theme_stylebox("panel").duplicate()
		style.bg_color.v += 0.15
		$PanelContainer.add_theme_stylebox_override("panel",style)
		_is_highlighted = true


func _on_button_mouse_entered() -> void:
	internal_button.grab_focus()

func _on_button_focus_exited() -> void:
	if _is_highlighted:
		var style:StyleBoxFlat = $PanelContainer.get_theme_stylebox("panel").duplicate()
		style.bg_color.v -= 0.15
		$PanelContainer.add_theme_stylebox_override("panel",style)
		_is_highlighted = false
