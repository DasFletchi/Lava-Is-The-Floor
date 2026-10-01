extends RigidBody3D
class_name BeanRagdoll

@onready var bean_visual: BeanVisual = get_node_or_null("BeanVisual") as BeanVisual

func setup(col: Color, eyes: int, impulse: Vector3 = Vector3.ZERO) -> void:
	if bean_visual == null:
		bean_visual = get_node_or_null("BeanVisual") as BeanVisual
	if bean_visual:
		bean_visual.apply_customization(col, eyes)

	# Lustiger, dramatischer Physik-Impuls
	linear_velocity = impulse + Vector3(randf_range(-2.5, 2.5), randf_range(4.0, 6.5), randf_range(-2.5, 2.5))
	angular_velocity = Vector3(randf_range(-6.0, 6.0), randf_range(-3.0, 3.0), randf_range(-6.0, 6.0))

	# Nach 5 Sekunden aufräumen
	get_tree().create_timer(5.0).timeout.connect(queue_free)
