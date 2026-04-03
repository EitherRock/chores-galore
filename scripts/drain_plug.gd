@tool

class_name DynamicChain extends Node3D

signal chain_ready
signal attachment_created(attachment_node: Node3D)

@export_group('Chain Setup')
@export_range(2, 50) var link_count: int = 10:
	set(value):
		link_count = value
		if Engine.is_editor_hint():
			_regenerate_chain()
			
@export var link_length: float = 0.3:
	set(value):
		link_length = value
		if Engine.is_editor_hint():
			_regenerate_chain()

@export var link_radius: float = 0.05:
	set(value):
		link_radius = value
		if Engine.is_editor_hint():
			_regenerate_chain()

@export_group('Joint Settings')
@export var angular_limit_degrees: float = 30.0
@export var twist_limit_degrees: float = 15.0

@export_group('Physics Properties')
@export var link_mass: float = 0.5
@export var gravity_scale: float = 1.0
@export var link_damping: float = 0.5

@export_group('Collision')
@export_flags_3d_physics var link_collision_layer: int = 1
@export_flags_3d_physics var link_collision_mask: int = 1

@export_group('Attachment')
@export var attached_scene: PackedScene = null

@export_group('References')
@export var anchor: StaticBody3D
@export var link_container: Node3D

var links: Array[RigidBody3D] = []
var joints: Array[Generic6DOFJoint3D]

func _ready():
	#if not Engine.is_editor_hint():
		#_generate_chain()
		_generate_chain()
		
func _generate_chain():
	_clear_chain()
		
	# Generate links
	for i in range(link_count):
		var link = _create_link(i)
		link_container.add_child(link)
		links.append(link)
		link.position = Vector3(0, -(i + 1) * link_length, 0)
	
	# wait for links to be in treee
	await get_tree().process_frame
	
	# create joints between links
	for i in range(link_count):
		var body_a = anchor if i == 0 else links[i - 1]
		var body_b = links[i]
		
		var joint = _create_joint(body_a, body_b)
		body_b.add_child(joint)
		joints.append(joint)
	
	# Attach scene to bottom link if provided
	if attached_scene and links.size() > 0:
		var attachment = attached_scene.instantiate()
		attachment.name = 'plug'
		link_container.add_child(attachment) # Add as sibling to avoid cleanup
		
		var bottom_link = links[links.size() - 1]
		attachment.global_position = bottom_link.global_position + Vector3(0, -link_length, 0)
		
		# If Attachment is RigidBody3D, connect it with a joint
		if attachment is RigidBody3D:
			var joint = _create_joint(bottom_link, attachment)
			attachment.add_child(joint)
	
	chain_ready.emit()
	if attached_scene:
		attachment_created.emit(get_attachment())

func _create_link(index: int) -> RigidBody3D:
	var link = RigidBody3D.new()
	link.name = 'Link_'+ str(index)
	
	# Physics Properties
	link.mass = link_mass
	link.gravity_scale = gravity_scale
	link.linear_damp = link_damping
	link.angular_damp = link_damping
	link.collision_layer = link_collision_layer
	link.collision_mask = link_collision_mask
	
	# Visual Mesh
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = link_length
	cylinder.top_radius = link_radius
	cylinder.bottom_radius = link_radius
	mesh_instance.mesh = cylinder
	link.add_child(mesh_instance)
	
	# Collision Shape
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = link_length
	shape.radius = link_radius
	collision_shape.shape = shape
	link.add_child(collision_shape)
	
	return link
	
	
func _create_joint(body_a: Node3D, body_b: RigidBody3D) -> Generic6DOFJoint3D:
	var joint = Generic6DOFJoint3D.new()
	joint.name = 'Joint_to_' + body_a.name
	joint.position = Vector3(0, link_length * 0.5, 0)
	
	# Lock X axis (no left/right swing)
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	
	# Lock y axis (no up/down stretch)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	
	# Lock z axis (no forward/back stretch)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0)
	
	# Angular Limits (swing range)
	var angular_limit_rad = deg_to_rad(angular_limit_degrees)
	var twist_limit_rad = deg_to_rad(twist_limit_degrees)
	
	# X axis swing (pitch)
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -angular_limit_rad)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_limit_rad)
	
	# y axis twist
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -twist_limit_rad)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, twist_limit_rad)
	
	# z axis swing (roll)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -angular_limit_rad)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_limit_rad)
	
	# set node paths after joint is in tree
	joint.ready.connect(func():
		joint.node_a = joint.get_path_to(body_a)
		joint.node_b = NodePath('..')
	)
	
	return joint

func _clear_chain() -> void:
	# clear existing
	for link in links:
		if is_instance_valid(link):
			link.queue_free()
	links.clear()
	joints.clear()
		
	for child in link_container.get_children():
		child.queue_free()

func _regenerate_chain() -> void:
	if Engine.is_editor_hint():
		_clear_chain()
		
		# wait for cleanup
		await get_tree().process_frame
		
		# Generate new chain
		_generate_chain()

func get_attachment() -> Node3D:
	return link_container.get_node_or_null('plug')
