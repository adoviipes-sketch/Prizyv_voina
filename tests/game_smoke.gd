extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.get_child(0).pressed.emit()
	assert(game.started and not game.axe)
	game.hp=50
	game.hurt()
	assert(game.hp==44)
	game.effect(Vector3.ZERO,Vector3.ONE,Color.BLUE,0.1)
	game.root_effect(Vector3.ZERO)
	game.shoot(Vector3(0,1,0),Vector3(0,1,1))
	game.melee_warning(game.enemies[0].node)
	await create_timer(1.2).timeout
	for enemy in game.enemies:
		enemy.hp=0
	await process_frame
	game.hero.position=game.villager.position
	await process_frame
	await process_frame
	assert(not game.talked)
	assert(game.speak_to_villager())
	assert(not game.speak_to_villager())
	await process_frame
	await process_frame
	assert(game.talked)
	assert(game.message.contains("Гой еси, добрый молодец!"))
	assert(game.restart_button.visible)
	print("PASS: menu, damage, timed effects, arrows, victory dialogue, restart visibility")
	quit()
