extends Node

@export var tracking : Node3D
@export var materials : Array[ShaderMaterial]
@export var proximity_range : float

func _ready():
	for material in materials:
		material.set_shader_parameter("prox_range",proximity_range)
		material.set_shader_parameter("pulse_radius",50.0)
		material.set_shader_parameter("pulse_origin_world",Vector3(0,0,0))
		material.set_shader_parameter("pulse_amp",0.5)
		material.set_shader_parameter("pulse_thickness",60.0)
	

func _process(_delta):
	for material in materials:
		material.set_shader_parameter("player_pos_world",tracking.global_position)
