extends Node

@export var component_name: String = ""

func _ready():
	if not component_name.is_empty():
		set_script(load(component_name))