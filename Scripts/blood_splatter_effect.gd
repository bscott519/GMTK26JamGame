extends GPUParticles3D

@export var duration: float = 0.5

func _ready():
	emitting = true
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(queue_free)
