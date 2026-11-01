extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.get_child(1).pressed.emit()
	assert(game.female)
	game.update_targets()
	assert(game.target==null)
	assert(not game.target_ring.visible)
	game.hero.position=Vector3(0,0,-15)
	game.update_targets()
	var first=game.target
	assert(is_instance_valid(first))
	assert(game.target_ring.visible)
	game.select_target(true)
	assert(game.target!=first)
	game.enemies[0].hp=20
	game.enemies[0].freeze=game.clock+3
	game.update_targets()
	assert(game.enemies[0].label.text.contains("20/45"))
	assert(game.enemies[0].label.modulate==Color(0.4,0.8,1))
	for enemy in game.enemies:
		enemy.hp=0
	game.update_targets()
	assert(game.target==null)
	assert(not game.target_ring.visible)
	await process_frame
	await process_frame
	print("PASS: out-of-range target, nearest selection, Tab cycling, health, frozen indicator, dead target clearing")
	quit()
