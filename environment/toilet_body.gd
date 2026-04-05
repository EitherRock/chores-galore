extends StaticBody3D

class_name Toilet

#signal toilet_flushed
signal toilet_clogged
signal toilet_unclogged

@onready var water_mesh = $WaterMesh
@onready var flush_particles = $FlushParticles
@onready var fill_sound = $FillSound
@onready var flush_sound = $FlushSound
@onready var clog_area = $ClogArea
@export var interact_prompt = 'Flush'

@export var flush_speed: float = 2.0
@export var refill_speed: float = 1.0

@export var water_level: float = 1.0:
	set(value):
		if is_clogged:
			water_level = value
		else:
			water_level = clamp(value, 0.0, 1.0)
		update_water_visuals()

@export var clog_overflow_level: float = 3.2
@export var refill_delay: float = 1.0

@export var clog_chance: float = 0.3
@export var flush_spin_speed: float = 10.0
@export var flush_shrink_speed: float = 2.0
@export var unclog_launch_force: float = 25.0

var is_flushing: bool = false
var is_refilling: bool = false
var is_clogged: bool = false
var items_in_toilet: Array = []
var clogged_items: Array = []

@export var water_full_height: float = 1.0
@export var water_empty_height: float = 0.4
@export var water_bottom_position: float = 0.4

func _ready():
	water_level = 1.0
	update_water_visuals()
	update_interact_prompt()
	
	if clog_area:
		clog_area.body_entered.connect(_on_item_entered_toilet)
		clog_area.body_exited.connect(_on_item_exited_toilet)

func update_interact_prompt():
	if is_clogged:
		interact_prompt = 'Unclog'
	else:
		interact_prompt = 'Flush'

func interact():
	if not multiplayer.is_server():
		rpc_id(1, "request_interact")
		return
	
	if is_clogged:
		unclog_toilet()
	else:
		flush_toilet()

func flush_toilet():
	if is_flushing or is_refilling:
		return
	
	is_flushing = true
	
	flush_items_in_toilet()
	rpc("play_flush_effect")

func flush_items_in_toilet():
	if items_in_toilet.is_empty():
		return
	
	var clog_roll = randf()
	var will_clog = clog_roll < clog_chance
	for item in items_in_toilet:
			if is_instance_valid(item):
				clogged_items.append(item)
	
	if will_clog:
		for item in items_in_toilet:
			if is_instance_valid(item):
				#clogged_items.append(item)
				rpc("animate_item_clog", item.get_path())
		
		is_clogged = true
		toilet_clogged.emit()
		rpc("show_clog_effect")
		update_interact_prompt()
		
		items_in_toilet.clear()
	else:
		for item in items_in_toilet:
			if is_instance_valid(item):
				rpc("animate_item_flush", item.get_path())
		items_in_toilet.clear()

@rpc("reliable", "call_local")
func animate_item_flush(item_path: NodePath):
	var item = get_node(item_path)
	if not item:
		return
	
	var tween = create_tween()
	tween.parallel().tween_property(item, "rotation", Vector3(0, 360, 0), flush_spin_speed)
	tween.parallel().tween_property(item, "scale", Vector3.ZERO, flush_shrink_speed)
	tween.parallel().tween_property(item, "global_position:y", item.global_position.y - 2.0, flush_shrink_speed)
	
	await tween.finished
	if is_instance_valid(item):
		item.queue_free()

@rpc("reliable", "call_local")
func animate_item_clog(item_path: NodePath):
	var item = get_node(item_path)
	if not item:
		return
	
	var tween = create_tween()
	tween.parallel().tween_property(item, "rotation", Vector3(0, 45, 0), .5)
	tween.parallel().tween_property(item, "global_position:y", item.global_position.y - 0.3, 0.5)
	
	item.freeze = true
	item.visible = true

@rpc("reliable", "call_local")
func play_flush_effect():
	if flush_particles:
		flush_particles.emitting = true
	if flush_sound:
		flush_sound.play()

func unclog_toilet():
	if not is_clogged:
		return
	
	if clogged_items.is_empty():
		is_clogged = false
		update_interact_prompt()
		water_level = 1.0
		return
	
	var count = clogged_items.size()
	var radius = 0.5
	
	# First pass: spread items in a circle above toilet
	for i in range(count):
		var item = clogged_items[i]
		print('clogged item: ', item)
		
		if is_instance_valid(item) and item is RigidBody3D:
			item.freeze = false
			item.sleeping = false
			item.visible = true
			item.scale = Vector3.ONE
			
			# Evenly distribute in a circle
			var angle = (float(i) / count) * TAU
			
			var offset = Vector3(
				cos(angle) * radius,
				1.0 + (i * 0.05), # slight vertical stacking
				sin(angle) * radius
			)
			
			item.global_position = global_position + offset
			
			item.linear_velocity = Vector3.ZERO
			item.angular_velocity = Vector3.ZERO
	
	# Let physics update once
	await get_tree().process_frame
	
	# Second pass: launch
	for item in clogged_items:
		if is_instance_valid(item) and item is RigidBody3D:
			print('launching: ', item)
			var launch_direction = Vector3(
				randf_range(-1.0, 1.0),
				randf_range(3.5, 5.5),
				randf_range(-1.0, 1.0)
			).normalized()
			
			item.apply_central_impulse(launch_direction * unclog_launch_force)
			item.apply_central_impulse(Vector3.UP * 15.0)
			
			item.apply_torque(Vector3(
				randf_range(-40, 40),
				randf_range(-40, 40),
				randf_range(-40, 40)
			))
			
			rpc("play_launch_effect", item.get_path())
	
	clogged_items.clear()
	
	is_clogged = false
	toilet_unclogged.emit()
	rpc("show_unclog_effect")
	update_interact_prompt()
	
	water_level = 1.0


@rpc("reliable", "call_local")
func play_launch_effect(item_path: NodePath):
	var item = get_node(item_path)
	if item and item.has_node("SplashParticles"):
		item.get_node("SplashParticles").emitting = true

@rpc("reliable", "call_local")
func show_clog_effect():
	if has_node("ClogParticles"):
		$ClogParticles.emitting = true
		await get_tree().create_timer(2.0).timeout
		if has_node("ClogParticles"):
			$ClogParticles.emitting = false

@rpc("reliable", "call_local")
func show_unclog_effect():
	if has_node("UnclogParticles"):
		$UnclogParticles.emitting = true
		if has_node("UnclogSound"):
			$UnclogSound.play()
		await get_tree().create_timer(2.0).timeout
		if has_node("UnclogParticles"):
			$UnclogParticles.emitting = false

func _on_item_entered_toilet(body: Node):
	if body is RigidBody3D and not items_in_toilet.has(body) and not clogged_items.has(body):
		items_in_toilet.append(body)

func _on_item_exited_toilet(body: Node):
	if body is RigidBody3D:
		items_in_toilet.erase(body)

func _process(delta):
	if not multiplayer.is_server():
		return
	
	if is_clogged:
		if water_level < clog_overflow_level:
			water_level += delta * 0.2
		return
	
	if is_flushing:
		water_level -= delta * flush_speed
		
		if water_level <= 0:
			water_level = 0
			is_flushing = false
			
			if not is_clogged:
				is_refilling = true
			
			rpc("stop_flush_effect")
			
			await get_tree().create_timer(refill_delay).timeout
			if not is_clogged and not is_flushing:
				is_refilling = true
	
	elif is_refilling:
		await get_tree().create_timer(refill_delay).timeout
		water_level += delta * refill_speed
		
		if water_level >= 1.0:
			water_level = 1.0
			is_refilling = false

func update_water_visuals():
	if not water_mesh:
		return
	
	var visual_level = clamp(water_level, 0.0, clog_overflow_level)
	var t = visual_level / clog_overflow_level
	var water_height = water_empty_height + (t * (water_full_height - water_empty_height))
	
	water_mesh.scale = Vector3(1.0, water_height, 1.0)
	water_mesh.position.y = water_bottom_position + (water_height / 2)

@rpc("reliable", "call_local")
func stop_flush_effect():
	if flush_particles:
		flush_particles.emitting = false

@rpc("any_peer", "call_local")
func request_interact():
	if multiplayer.is_server():
		if is_clogged:
			unclog_toilet()
		else:
			flush_toilet()
