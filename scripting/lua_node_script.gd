class_name LuaNodeScript
extends Node2D

@export var lua_module_path: String
@export var bindings: Dictionary = {}

func _ready():
	var _lua_module_path = lua_module_path
	var _bindings = bindings.duplicate(true)
	self.script = SdkBindings.get_impl_script("scripting/lua_node_script")
	self.lua_module_path = lua_module_path
	self.bindings = _bindings
	self._ready()

func _process(delta: float):
	pass # keep this method so process_mode is not disabled
