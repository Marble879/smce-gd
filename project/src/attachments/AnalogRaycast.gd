class_name AnalogRaycastGD
extends RayCast

export(int, 100) var pin = 0
export(float) var min_distance = 0

var view = null setget set_view

var distance: float = 0

func set_view(_view: Node) -> void:
	if ! _view:
		return
	
	view = _view
	
	view.connect("validated", self, "set_physics_process", [true])
	view.connect("invalidated", self, "set_physics_process", [false])
	
	set_physics_process(true)


func _ready() -> void:
	set_physics_process(false)


func _physics_process(_delta: float):
	var dist = 0 # if not coliding 0 is reported
	if is_colliding():
		var pos = global_transform.origin
		var hit = get_collision_point()
		dist = pos.distance_to(hit)
	
	if dist < min_distance:
		dist = 0
	
	distance = dist
	view.write_analog_pin(pin, int(dist * 100))


func name() -> String:
	return "Infrared Distance"


func visualize() -> Control:
	var visualizer = NodeVisualizer.new()
	visualizer.display_node(self, "visualize_content")
	return visualizer


func visualize_content() -> String:
	return "   Pin: %d\n   Distance: %.3fm" % [pin, distance]
