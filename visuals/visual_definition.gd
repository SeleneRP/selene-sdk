@tool
extends Resource
class_name VisualDefinition

@export_group("Scene")
@export var scene: PackedScene

@export_group("Sprite2D")
@export var texture: Texture2D

@export_group("AnimatedSprite2D")
@export var sprite_frames: SpriteFrames
@export var animation: String