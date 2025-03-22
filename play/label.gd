extends Label


func _ready() -> void:
	var vistween = create_tween()
	vistween.set_trans(Tween.TRANS_QUINT)
	vistween.tween_property(self,"self_modulate:a",0,0.5).set_ease(Tween.EASE_IN_OUT)
	var postween = create_tween()
	postween.set_trans(Tween.TRANS_QUINT)
	postween.tween_property(self,"position:y",position.y + 50,0.5).set_ease(Tween.EASE_IN_OUT)
