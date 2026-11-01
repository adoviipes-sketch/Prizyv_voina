extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.get_child(0).pressed.emit()
	game.hero.position=Vector3(2.7,0,24)
	await process_frame
	await process_frame
	assert(game.lessons.leaf and game.leaves==1)
	assert(game.tutorial_text().contains("[+] Собрать подорожник"))
	game.set_paused(true)
	var before: float=game.clock
	await create_timer(0.2,true).timeout
	assert(game.clock==before)
	assert(game.pause_panel.visible)
	game.set_paused(false)
	await process_frame
	await process_frame
	assert(game.clock>before)
	game.talked=true
	assert(game.tutorial_text().contains("МИССИЯ ЗАВЕРШЕНА"))
	print("PASS: plant lesson, checklist, pause freezes game clock, resume, mission completion")
	quit()
