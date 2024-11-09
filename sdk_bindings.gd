extends Node
class_name SdkBindings
	
static var bindings_impl = null

static func get_impl_script(p_name: String):
	return bindings_impl.get_impl_script(p_name)

static func get_default_lua_vm():
	return bindings_impl.get_default_lua_vm()
