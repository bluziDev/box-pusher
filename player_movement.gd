extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

@export var floor_check_height : float

var target_velocity = Vector3.ZERO
	
@onready var cam : Camera3D = get_viewport().get_camera_3d()

func _process(delta):
	var cam_ratio = 1 / tan(abs(cam.rotation.x))
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		
	if direction != Vector3.ZERO:
		#print(str(cam.rotation.x))
		direction = direction.normalized() * Vector3(1,1,cam_ratio)#).rotated(Vector3.UP,cam.rotation.y)
		# Setting the basis property will affect the rotation of the node.
		#$Pivot.basis = Basis.looking_at(direction)
		
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	#if not move_and_collide(Vector3(0,-floor_check_height,0),true): # If in the air, fall towards the floor. Literally gravity
	#	target_velocity.y = target_velocity.y - (fall_acceleration * delta)
		#pass
	#else:
	#	target_velocity.y = 0

	# Moving the Character
	#velocity = target_velocity * delta
	
	#new method
	#first move and depenetrate to record normal depenetration
	#global_position += target_velocity * delta
	#var colliding_pos = global_position
	#move_and_collide(Vector3.ZERO)
	var colliding_pos = global_position# + velocity
	move_and_collide(Vector3(0,0,0))#,true,0.001,true,5)
	#var collision = move_and_collide(velocity,false,0.001,true,1)
	#var collision = move_and_collide(Vector3.ZERO)
	if colliding_pos != global_position:
		#cols += 1
		#print(str(col_norm))
		var penetration = colliding_pos - global_position
		#print(str(penetration))
		var col_norm = (-penetration).normalized()#collision.get_normal()
		var depen_pos = colliding_pos - penetration
		var scaled_pen = penetration * Vector3(1,1,1 / (cam_ratio * 2))
		var new_colliding_pos = depen_pos + scaled_pen
		var v = new_colliding_pos - depen_pos
		var dist = col_norm.dot(v)
		global_position = new_colliding_pos - dist * col_norm #add to depen or just collide again?
		target_velocity.y = lerpf(target_velocity.y,0,clamp(col_norm.dot(Vector3.UP),0,1))
		#colliding_pos = global_position
		#collision = move_and_collide(Vector3.ZERO)
	#else:
	#	global_position += velocity
	
	velocity = target_velocity * delta
	global_position += velocity
	
	#old method
	#var collision = move_and_collide(velocity,true)
	#var previous_pos = global_position
	#var start_loop = true
	#while collision && (((global_position - previous_pos).length() > 0.05 && velocity.length() / delta > 0.05) || start_loop):
	#	start_loop = false
	#	print(str(velocity))
	#	velocity = velocity.slide(collision.get_normal() * Vector3(-1,1,-1))
	#	collision = move_and_collide(velocity,false)
	#	#velocity -= (global_position - previous_pos)
	#	velocity.move_toward(Vector3.ZERO,max((global_position - previous_pos).length(),0.05))
