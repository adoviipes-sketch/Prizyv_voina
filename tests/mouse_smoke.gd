extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func mouse(button: MouseButton, down: bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=button
	event.pressed=down
	event.button_mask=(1 << (button-1)) if down else 0
	event.position=Vector2(700,600)
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	game.menu.get_child(0).pressed.emit()
	game.hero.position=Vector3(0,0,-14)
	await create_timer(0.1).timeout
	game.enemies[0].node.position=game.hero.position+Vector3(0,0,-1)
	game.attack_time=0
	var health: float=game.enemies[0].hp
	mouse(MOUSE_BUTTON_LEFT,true)
	await create_timer(0.05).timeout
	await create_timer(0.05).timeout
	mouse(MOUSE_BUTTON_LEFT,false)
	print("DEBUG ",game.started," ",game.attack_held," ",game.clock," ",game.attack_time," ",game.enemies[0].hp)
	assert(game.enemies[0].hp<health)
	mouse(MOUSE_BUTTON_RIGHT,true)
	assert(game.blocking())
	game.hp=100
	game.stamina=100
	game.hurt()
	assert(game.hp==98)
	game.axe=true
	game.hurt()
	assert(game.hp==95)
	mouse(MOUSE_BUTTON_RIGHT,false)
	assert(not game.blocking())
	game.selected_spell=KEY_E
	game.mana=100
	game.spell_time=0
	mouse(MOUSE_BUTTON_MIDDLE,true)
	await create_timer(0.05).timeout
	await create_timer(0.05).timeout
	assert(game.mana==80)
	var mana_after: float=game.mana
	await create_timer(0.2).timeout
	assert(game.mana==mana_after)
	mouse(MOUSE_BUTTON_MIDDLE,false)
	print("PASS: left attack, right shield block, axe block, middle cast, no repeated cast while held")
	quit()
