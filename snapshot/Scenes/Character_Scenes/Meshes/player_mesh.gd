extends Node3D

@onready var ray = $Ray
var grabbed = null

func _ready():
	ray.add_exception(get_parent())
	
func _physics_process(delta):
	if ray.is_colliding():
		pass
