class_name LuaNodeScript
extends Node2D

@export var lua_module_path: String
@export var bindings: Dictionary = {}

var lua_module: Variant
var state: Variant
var lua_bindings = {}

func _ready():
	lua_module = SdkBindings.require_lua(lua_module_path)
	if not lua_module:
		return

	for key in bindings:
		var value = bindings[key]
		if value.begins_with("res://"):
			value = load(value)
		lua_bindings[key] = value

	if "initial_state" in lua_module:
		state = lua_module["initial_state"].call()

	if "ready" in lua_module:
		SdkBindings.handle_lua_error(lua_module["ready"].call(self, state, lua_bindings))

func _process(delta: float):
	# TODO this is just for testing:
	var mouse_pos = get_global_mouse_position()
	var tiled_mouse_pos = Vector2(floor(mouse_pos.x / 76) * 76, floor(mouse_pos.y / 37) * 37)
	global_position = tiled_mouse_pos + Vector2(37, 18.5)

	if lua_module and "process" in lua_module:
		var new_state = SdkBindings.handle_lua_error(lua_module["process"].call(null, state, lua_bindings, delta))
		if new_state is not LuaError:
			state = new_state
