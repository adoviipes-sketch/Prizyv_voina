extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.get_child(0).pressed.emit()
	for direction in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		game.stamina=100
		game.roll_ready=0
		var before: Vector3 = game.hero.position
		assert(game.dodge(direction))
		assert(game.stamina==75)
		assert(not game.dodge(direction))
		var health: float = game.hp
		game.hurt()
		assert(game.hp==health)
		await create_timer(0.55).timeout
		assert((game.hero.position-before).dot(direction)>3)
	game.stamina=0
	game.roll_ready=0
	assert(not game.dodge(Vector3.LEFT))
	game.stamina=100
	game.enemies[0].node.position=game.hero.position+Vector3(0,0,-2)
	var enemy_health: float = game.enemies[0].hp
	assert(game.jump(true))
	assert(game.enemies[0].hp==enemy_health-15)
	assert(game.enemies[0].freeze>game.clock)
	assert(not game.jump(true))
	await create_timer(0.8).timeout
	game.axe=true
	assert(not game.jump(true))
	assert(game.jump(false))
	await create_timer(0.8).timeout
	assert(abs(game.hero.position.y)<0.01)
	print("PASS: four dodge directions, stamina cost, cooldown, invulnerability, shield damage/stun, axe restriction, jump landing")
	quit()
