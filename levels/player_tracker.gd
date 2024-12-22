extends Node

@export var tracking : Node3D
@export var materials : Array[ShaderMaterial]
@export var proximity_range : float

func _ready():
	for material in materials:
		material.set_shader_parameter("prox_range",proximity_range)
	

func _process(_delta):
	for material in materials:
		material.set_shader_parameter("player_pos_world",tracking.global_position)
