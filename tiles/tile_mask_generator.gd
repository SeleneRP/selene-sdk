@tool
extends Resource
class_name TileMaskGenerator

@export var tileset_definition: TileSetDefinition
@export var mask_textures: Array[Texture] = []
@export_dir var output_dir: String = "res://.output/tile_transitions"

@export var generate_textures: bool :
	get:
		return false
	set(value):
		if value:
			_generateTextures()

func _generateTextures():
	if not tileset_definition or not mask_textures:
		return

	var tileset = tileset_definition.generated_tileset
	for i in tileset.get_source_count():
		var source_id = tileset.get_source_id(i)
		var source = tileset.get_source(source_id)
		for j in source.get_tiles_count():
			var tile_id = source.get_tile_id(j)
			var tile_name = source.get_tile_data(tile_id, 0).get_custom_data("name")
			var tile_texture_region = source.get_tile_texture_region(tile_id)
			for mask_texture in mask_textures:
				var mask_name = mask_texture.resource_path.get_file().get_basename()
				var tile_image = Image.create(tile_texture_region.size.x, tile_texture_region.size.y, false, Image.FORMAT_RGBA8)
				tile_image.blit_rect(source.texture.get_image(), tile_texture_region, Vector2i(0, 0))
				var image = Image.create(tile_texture_region.size.x, tile_texture_region.size.y, false, Image.FORMAT_RGBA8)
				image.blit_rect_mask(tile_image, mask_texture.get_image(), Rect2i(0, 0, tile_texture_region.size.x, tile_texture_region.size.y), Vector2i(0, 0))
				var bundle_output_dir = output_dir.path_join(tileset_definition.bundle_id)
				DirAccess.make_dir_recursive_absolute(bundle_output_dir)
				image.save_png(bundle_output_dir.path_join(tile_name + "_" + mask_name + ".png"))