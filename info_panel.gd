extends Control

@export var _icon:Node
@export var _title:Node
@export var _desc:Node


var icon:Texture2D: 
	set(value):
		_icon.texture = value
var title:String:
	set(value):
		_title.text = value
var desc:String:
	set(value):
		_desc.text = value
