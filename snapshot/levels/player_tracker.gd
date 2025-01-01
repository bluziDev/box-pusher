extends Node

@export var tracking : Node3D
@export var materials : Array[ShaderMaterial]
@export var proximity_range : float
@export var pulse_amplitude : float
@export var pulse_thickness : float
@export var pulse_lifetime : float
@export var pulse_range : float
@export var pulse_creation_travel : float

func _ready():
	for material in materials:
		material.set_shader_parameter("prox_range",proximity_range)
		material.set_shader_parameter("pulse_thickness",pulse_thickness)
	new_pulse()
	

func _process(_delta):
	for material in materials:
		material.set_shader_parameter("player_pos_world",tracking.global_position)
		var time_percentage_left = ($PulseTimer.time_left / $PulseTimer.wait_time)
		var pulse_radius = pulse_range * (1.0 - time_percentage_left)
		material.set_shader_parameter("pulse_radius",pulse_radius)
		material.set_shader_parameter("pulse_amp",pulse_amplitude * time_percentage_left * min(1.0,pulse_radius / pulse_creation_travel))
		#$PulseTimer/CanvasLayer/Label.text = str(time_percentage_left)

func new_pulse():
	for material in materials:
		material.set_shader_parameter("pulse_origin_world",tracking.global_position)
		$PulseTimer.start(pulse_lifetime)
