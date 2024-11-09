extends Node
class_name SdkBindings
	
static var bindings_impl = null

static func get_default_lua_vm():
	return bindings_impl.get_default_lua_vm()

static func require_lua(module_path: String):
	return bindings_impl.require_lua(module_path)

static func handle_lua_error(error: Variant):
	return bindings_impl.handle_lua_error(error)

static func get_lua_node_script():
	return bindings_impl.get_lua_node_script()