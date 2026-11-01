extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.obstacles=[{"center":Vector2.ZERO,"half":Vector2(0.3,0.3)}]
	var end: Vector3=game.resolve_obstacles(Vector3(-3,0,0),Vector3(3,0,0))
	assert(end.x< -0.6)
	assert(not game.blocked(end))
	var clear: Vector3=game.resolve_obstacles(Vector3(-3,0,3),Vector3(3,0,3))
	assert(clear.distance_to(Vector3(3,0,3))<0.01)
	for i in range(30):
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_WHEEL_UP
		event.pressed=true
		game._input(event)
	assert(is_equal_approx(game.camera_distance,0.6))
	print("PASS: obstacle collision, long-step anti-tunneling, clear passage, camera zoom limit")
	quit()
