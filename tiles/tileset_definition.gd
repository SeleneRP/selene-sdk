@tool
extends Resource
class_name TileSetDefinition

@export var bundle_id: String
@export_file("*.tpsheet") var sheet: String
@export_file("*.json") var offsetDefinitions: String
@export_file("*.json") var animationDefinitions: String

@export var generated_tileset: TileSet

@export var generate_tiles: bool:
	get:
		return false
	set(value):
		if value:
			_generateTiles()

var tileset_utils = TileSetUtils.new()

func _generateTiles():
	var previous_tileset = generated_tileset
	generated_tileset = TileSet.new()
	generated_tileset.add_custom_data_layer(0)
	generated_tileset.set_custom_data_layer_name(0, "name")
	generated_tileset.set_custom_data_layer_type(0, Variant.Type.TYPE_STRING)

	var existing_tiles = {}
	if previous_tileset:
		tileset_utils.copy_tileset_shallow(previous_tileset, generated_tileset)
		for i in previous_tileset.get_source_count():
			var source_id = previous_tileset.get_source_id(i)
			var source = previous_tileset.get_source(source_id)
			for j in source.get_tiles_count():
				var tile_id = source.get_tile_id(j)
				var tile_data = source.get_tile_data(tile_id, 0)
				var tile_name = tile_data.get_custom_data("name")
				for k in source.get_alternative_tiles_count(tile_id):
					var alt_tile_id = source.get_alternative_tile_id(tile_id, k)
					if alt_tile_id == 0:
						existing_tiles[tile_name] = []
					existing_tiles[tile_name].append(source.get_tile_data(tile_id, alt_tile_id))

	var metadata = _parse_tpsheet(sheet)
	var offsets = _parse_offsets(offsetDefinitions)
	var animations = _parse_animations(animationDefinitions)

	var alt_offsets = {}
	if offsets:
		for offset_key in offsets.offsets.keys():
			if offset_key.contains("#"):
				var parts = offset_key.split("#")
				var sprite_name = parts[0]
				var alt_name = parts[1]
				if not alt_offsets.has(sprite_name):
					alt_offsets[sprite_name] = []
				alt_offsets[sprite_name].append(offset_key)

	for atlas in metadata.atlases:
		var atlas_source = TileSetAtlasSource.new()
		atlas_source.resource_name = bundle_id + ":" + atlas.name
		atlas_source.texture = load(atlas.path)
		atlas_source.texture_region_size = Vector2i(atlas.cell_size.x, atlas.cell_size.y)
		generated_tileset.add_source(atlas_source)

		var used_animation_sprites = {}
		for sprite_name in atlas.sprites.keys():
			var sprite = atlas.sprites[sprite_name]
			if used_animation_sprites.has(sprite.name):
				continue
			atlas_source.create_tile(sprite.atlas_coords)
			var existing_alts = existing_tiles.get(sprite.name) if existing_tiles.has(sprite.name) else []
			var expected_alts = {}
			expected_alts[sprite.name] = null
			for alt_offset in alt_offsets.get(sprite.name, []):
				expected_alts[alt_offset] = null
			for j in existing_alts.size():
				var existing_tile_data = existing_alts[j]
				var alt_tile_name = existing_tile_data.get_custom_data("name")
				expected_alts[alt_tile_name] = existing_tile_data
			for alt_tile_name in expected_alts.keys():
				var alt_tile_id = atlas_source.create_alternative_tile(sprite.atlas_coords) if alt_tile_name != sprite.name else 0
				var alt_tile_data = atlas_source.get_tile_data(sprite.atlas_coords, alt_tile_id)
				alt_tile_data.texture_origin = offsets["get_offset"].call(offsets.offsets, atlas, sprite, alt_tile_name) if offsets else sprite.offset
				var existing_tile_data = expected_alts[alt_tile_name]
				if existing_tile_data:
					tileset_utils.copy_tile_data(previous_tileset, generated_tileset, existing_tile_data, alt_tile_data)
				alt_tile_data.set_custom_data("name", alt_tile_name)
			var animation = animations.get(sprite.name) if animations else null
			if animation:
				atlas_source.set_tile_animation_speed(sprite.atlas_coords, animation.speed)
				var min_x = sprite.atlas_coords.x
				var max_x = 0
				for frame in animation.frames:
					var frame_sprite = atlas.sprites.get(animation.template % frame)
					if not frame_sprite:
						continue
					max_x = max(max_x, frame_sprite.atlas_coords.x)
					used_animation_sprites[frame_sprite.name] = true
				var columns = max_x - min_x + 1
				atlas_source.set_tile_animation_columns(sprite.atlas_coords, columns)
				atlas_source.set_tile_animation_frames_count(sprite.atlas_coords, animation.frames)

func _parse_tpsheet(path: String):
	var json = FileAccess.get_file_as_string(path)
	var metadata = JSON.parse_string(json)
	var atlases = []
	for texture in metadata.textures:
		var atlas_path = path.get_base_dir().path_join(texture.image)
		var atlas_name = texture.image.get_basename()
		var atlas_size = Vector2i(texture.size.w, texture.size.h)
		var sprites = {}
		var sheet_cols = 0
		var sheet_rows = 0
		for sprite in texture.sprites:
			if sprite.region.x == 0:
				sheet_rows += 1
			if sprite.region.y == 0:
				sheet_cols += 1
		var cell_size = Vector2i((atlas_size.x / sheet_cols) if sheet_cols > 0 else atlas_size.x,  (atlas_size.y / sheet_rows) if sheet_rows > 0 else atlas_size.y)
		for sprite in texture.sprites:
			var sprite_name = sprite.filename.get_basename()
			var sprite_offset = Vector2i(sprite.region.w / 2 - cell_size.x / 2, sprite.region.h / 2 - cell_size.y / 2)
			var sprite_region = Rect2i(sprite.region.x, sprite.region.y, sprite.region.w, sprite.region.h)
			var sprite_coords = Vector2i(sprite.region.x / cell_size.x, sprite.region.y / cell_size.y)
			sprites[sprite_name] = {
				"name": sprite_name,
				"offset": sprite_offset,
				"region": sprite_region,
				"atlas_coords": sprite_coords
			}
		atlases.append({
			"name": atlas_name,
			"path": atlas_path,
			"atlas_size": atlas_size,
			"cell_size": cell_size,
			"sprites": sprites
		})
	return {
		"atlases": atlases
	}

func _parse_offsets(path: String):
	var json = FileAccess.get_file_as_string(path)
	var metadata = JSON.parse_string(json)
	return {
		"offsets": metadata.offsets,
		"get_offset": _get_center_yup_offset
	}

func _parse_animations(path: String):
	var json = FileAccess.get_file_as_string(path)
	var metadata = JSON.parse_string(json)
	return metadata

func _get_center_yup_offset(offsets, atlas, sprite, sprite_name):
	var offset = offsets.get(sprite_name)
	if offset:
		var cell_width = atlas.cell_size.x
		var cell_height = atlas.cell_size.y
		var sprite_width = sprite.region.size.x
		var sprite_height = sprite.region.size.y
		return Vector2i(-cell_width / 2 + sprite_width / 2 - offset.x, -cell_height / 2 + sprite_height + offset.y)
	return sprite.offset
