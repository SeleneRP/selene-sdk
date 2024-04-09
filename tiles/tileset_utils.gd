extends RefCounted
class_name TileSetUtils

func copy_tileset_shallow(source: TileSet, target: TileSet):
	target.tile_layout = source.tile_layout
	target.tile_offset_axis = source.tile_offset_axis
	target.tile_shape = source.tile_shape
	target.tile_size = source.tile_size
	target.uv_clipping = source.uv_clipping

func copy_tileset_source(source_tileset: TileSet, target_tileset: TileSet, source: TileSetSource, copy: TileSetSource):
	if source is TileSetAtlasSource:
		copy.texture = source.texture
		copy.margins = source.margins
		copy.separation = source.separation
		copy.texture_region_size = source.texture_region_size
		copy.use_texture_padding = source.use_texture_padding
		for i in source.get_tiles_count():
			var coords = source.get_tile_id(i)
			var size = source.get_tile_size_in_atlas(coords)
			var source_tile = source.get_tile_data(coords, 0)
			copy.create_tile(coords, size)
			var copied_tile = copy.get_tile_data(coords, 0)
			copy_tile_data(source_tileset, target_tileset, source_tile, copied_tile)
			copy.set_tile_animation_columns(coords, source.get_tile_animation_columns(coords))
			copy.set_tile_animation_speed(coords, source.get_tile_animation_speed(coords))
			copy.set_tile_animation_separation(coords, source.get_tile_animation_separation(coords))
			copy.set_tile_animation_mode(coords, source.get_tile_animation_mode(coords))
			copy.set_tile_animation_frames_count(coords, source.get_tile_animation_frames_count(coords))
			for j in source.get_alternative_tiles_count(coords):
				var alt_id = source.get_alternative_tile_id(coords, j)
				if alt_id == 0:
					continue
				var source_alt_tile = source.get_tile_data(coords, alt_id)
				copy.create_alternative_tile(coords, alt_id)
				var copied_alt_tile = copy.get_tile_data(coords, alt_id)
				copy_tile_data(source_tileset, target_tileset, source_alt_tile, copied_alt_tile)
	elif source is TileSetScenesCollectionSource:
		for i in source.get_scene_tiles_count():
			var tile_id = source.get_scene_tile_id(i)
			var scene = source.get_scene_tile_tile(i)
			copy.create_scene_tile(scene, tile_id)
			copy.set_scene_tile_display_placeholder(tile_id, source.get_scene_tile_display_placeholder(tile_id))
	copy.resource_name = source.resource_name

func copy_tile_data(source_tileset: TileSet, target_tileset: TileSet, source: TileData, target: TileData):
	target.flip_h = source.flip_h
	target.flip_v = source.flip_v
	target.material = source.material
	target.modulate = source.modulate
	target.probability = source.probability
	if source.terrain_set != -1:
		target.terrain_set = source.terrain_set
	if source.terrain != -1:
		target.terrain = source.terrain
	target.texture_origin = source.texture_origin
	target.transpose = source.transpose
	target.y_sort_origin = source.y_sort_origin
	target.z_index = source.z_index
	for i in source_tileset.get_custom_data_layers_count():
		var custom_data_layer_name = source_tileset.get_custom_data_layer_name(i)
		var target_data_layer_id = target_tileset.get_custom_data_layer_by_name(custom_data_layer_name)
		if target_data_layer_id != -1:
			target.set_custom_data(custom_data_layer_name, source.get_custom_data(custom_data_layer_name))