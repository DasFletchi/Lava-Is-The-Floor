extends RigidBody3D

## A deliberately simple bean ragdoll: it gets one real physics tumble, then
## settles and bobs on the molten surface instead of falling through the level.
@export var lava_height := -2.0
var _settled := false
var _time := 0.0

func set_appearance(bean_color: Color, eye_style: int) -> void:
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = bean_color
	body_material.metallic = 0.08
	body_material.roughness = 0.36
	$BeanBody.material_override = body_material
	if eye_style == 1:
		$Eyes/LeftEye.scale = Vector3(1.35, 1.35, 1.0)
		$Eyes/RightEye.scale = Vector3(1.35, 1.35, 1.0)
	elif eye_style == 2:
		$Eyes/LeftEye.rotation.z = 0.38
		$Eyes/RightEye.rotation.z = -0.38

func _physics_process(delta: float) -> void:
	if not _settled and global_position.y <= lava_height + 0.25:
		_settled = true
		freeze = true
		global_position.y = lava_height + 0.12
	_time += delta
	if _settled:
		global_position.y = lava_height + 0.12 + sin(_time * 2.4) * 0.05
