extends Node3D

var hero: Node3D
var camera: Camera3D
var enemies: Array = []
var herbs: Array = []
var hp := 100.0
var mana := 100.0
var leaves := 0
var berries := 0
var clock := 0.0
var attack_time := 0.0
var spell_time := 0.0
var selected_spell := KEY_Q
var cast_requested := false
var attack_held := false
var block_held := false
var female := false
var axe := false
var started := false
var hud: Label
var menu: VBoxContainer
var message := "Лесная тропа ведёт к разорённой деревне."
var talked := false
var combat_started := -1.0
var restart_button: Button
var stamina := 100.0
var roll_until := 0.0
var roll_ready := 0.0
var roll_direction := Vector3.FORWARD
var jump_until := 0.0
var jump_started := 0.0
var last_exertion := -10.0
var movement := Vector3.ZERO
var lessons := {"leaf":false,"berry":false,"roll":false,"magic":false}
var paused := false
var tutorial_label: Label
var pause_panel: VBoxContainer
var obstacles: Array = []
var camera_distance := 1.0
var item_ready := 0.0
var villager: Node3D
var villager_label: Label3D
var facing := Vector3.FORWARD
var resource_bars: Array = []
var spell_status: Label
var previous_enemy_hp: Dictionary = {}
var target: Node3D
var target_ring: MeshInstance3D

func shape(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	item.material_override = material
	parent.add_child(item)
	item.position = pos
	return item

func person(pos: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	shape(root, Vector3(0,0.9,0),Vector3(0.65,1.2,0.45),color)
	shape(root, Vector3(0,1.7,0),Vector3(0.4,0.4,0.4),Color(0.65,0.49,0.34))
	return root

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_energy = 1.3
	add_child(sun)
	shape(self,Vector3(0,-0.2,0),Vector3(80,0.3,100),Color(0.10,0.16,0.10))
	shape(self,Vector3(0,0,0),Vector3(5,0.1,90),Color(0.25,0.23,0.16))
	var rng := RandomNumberGenerator.new()
	rng.seed = 491
	for i in range(110):
		var x := rng.randf_range(-32,32)
		if abs(x)<4: continue
		var z := rng.randf_range(-38,35)
		obstacles.append({"center":Vector2(x,z),"half":Vector2(0.3,0.3)})
		var trunk := shape(self,Vector3(x,2,z),Vector3(0.6,4,0.6),Color.WHITE)
		if ResourceLoader.exists("res://assets/materials/bark/bark.tres"):
			trunk.material_override = load("res://assets/materials/bark/bark.tres")
		else:
			(trunk.material_override as StandardMaterial3D).albedo_color = Color(0.22,0.14,0.09)
		shape(self,Vector3(x,5,z),Vector3(3,4,3),Color(0.07,0.20,0.12))
	for i in range(12):
		var pos := Vector3(2.7 if i%2==0 else -2.7,0.3,24-i*3)
		var plant := shape(self,pos,Vector3(0.5,0.5,0.5),Color.GREEN if i%2==0 else Color.DARK_RED)
		herbs.append({"node":plant,"berry":i%2==1})
	for x in [-7,7,12]:
		obstacles.append({"center":Vector2(x,-22),"half":Vector2(2,2)})
		shape(self,Vector3(x,0.7,-22),Vector3(4,1.4,4),Color(0.15,0.12,0.10))
		shape(self,Vector3(x,1.7,-23),Vector3(4,0.3,0.3),Color(0.08,0.07,0.06))
	hero = person(Vector3(0,0,30),Color(0.3,0.35,0.4))
	for i in range(3):
		var enemy := person(Vector3((i-1)*3,0,-15-i*2),Color(0.45,0.25,0.15))
		enemies.append({"node":enemy,"hp":45.0,"freeze":0.0,"next":0.0,"archer":i==2})
	setup_enemy_labels()
	villager=person(Vector3(4,0,-28),Color(0.35,0.4,0.3))
	villager_label=Label3D.new()
	villager_label.position=Vector3(0,2.5,0)
	villager_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	villager_label.font_size=42
	villager_label.pixel_size=0.008
	villager.add_child(villager_label)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20,135)
	hud.add_theme_font_size_override("font_size",20)
	layer.add_child(hud)
	setup_resource_bars(layer)
	tutorial_label=Label.new()
	tutorial_label.position=Vector2(850,25)
	tutorial_label.add_theme_font_size_override("font_size",18)
	layer.add_child(tutorial_label)
	pause_panel=VBoxContainer.new()
	pause_panel.position=Vector2(500,250)
	layer.add_child(pause_panel)
	pause_panel.hide()
	for caption in ["Продолжить","Начать заново","Выйти из игры"]:
		var control := Button.new()
		control.text=caption
		pause_panel.add_child(control)
		control.pressed.connect(func():
			if caption=="Продолжить": set_paused(false)
			elif caption=="Начать заново":
				set_paused(false)
				get_tree().reload_current_scene()
			else: get_tree().quit()
		)
	restart_button = Button.new()
	restart_button.text = "Начать заново"
	restart_button.position = Vector2(520,400)
	restart_button.hide()
	layer.add_child(restart_button)
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	menu = VBoxContainer.new()
	menu.position = Vector2(450,200)
	layer.add_child(menu)
	for title in ["Воин · меч и щит","Воительница · меч и щит","Воин · двуручный топор","Воительница · двуручный топор"]:
		var button := Button.new()
		button.text = title
		menu.add_child(button)
		button.pressed.connect(func():
			female = title.contains("Воительница")
			axe = title.contains("топор")
			started = true
			menu.hide()
			shape(hero,Vector3(0.5,0.8,0),Vector3(0.15,1.3,0.15),Color.GRAY)
			if axe: shape(hero,Vector3(0.65,1.35,0),Vector3(0.6,0.4,0.15),Color.DIM_GRAY)
			if not axe: shape(hero,Vector3(-0.5,0.9,0),Vector3(0.15,0.85,0.7),Color(0.32,0.19,0.1))
		)

func _process(dt: float) -> void:
	update_resource_bars()
	tutorial_label.text=tutorial_text() if started else "Выберите героя и оружие"
	if paused: return
	clock += dt
	camera.position = hero.position+Vector3(0,15,12)*camera_distance
	camera.look_at(hero.position)
	hud.text = "Лесная переправа · прототип\nЗдоровье %d · Мана %d · Листья %d · Клюква %d\nWASD — ходьба · Ctrl — бег · колесо — масштаб · ЛКМ — удар · ПКМ — блок · Alt — перекат · Tab — цель · V — разговор\nQ/E/R — выбор магии · СКМ — применить · 1/2 — восстановление · F — прыжок · W+ПКМ+F — удар щитом\n%s" % [hp,mana,leaves,berries,message]
	hud.text += "\nВыносливость: %d · Магия: %s" % [stamina, spell_name()]
	if hp<=0 or talked:
		restart_button.show()
		return
	if not started: return
	var cast_now := cast_requested
	cast_requested=false
	update_targets()
	villager_label.visible=enemies.is_empty()
	villager_label.text="Житель · V — поговорить" if hero.position.distance_to(villager.position)<3 else "Житель"
	var move := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var previous_position := hero.position
	movement = move.normalized()
	if clock>last_exertion+0.8 and clock>=roll_until and clock>=jump_until:
		stamina=minf(100,stamina+dt*22)
	if clock<roll_until:
		hero.position += roll_direction*dt*9
		hero.rotation.x = -sin((roll_until-clock)/0.5*PI)*1.8*roll_direction.z
		hero.rotation.z = sin((roll_until-clock)/0.5*PI)*1.8*roll_direction.x
	else:
		hero.rotation.x=0
		hero.rotation.z=0
		var speed := 2.5 if blocking() else 5.0
		if Input.is_physical_key_pressed(KEY_CTRL) and movement.length()>0.1 and not blocking() and stamina>=1 and clock>=jump_until:
			speed=8.0
			stamina=maxf(0,stamina-dt*18)
			last_exertion=clock
		hero.position += movement*dt*speed
	if clock<jump_until:
		hero.position.y=sin((clock-jump_started)/0.65*PI)*1.2
	else:
		hero.position.y=0
	hero.position=resolve_obstacles(previous_position,hero.position)
	if movement.length_squared()>0.01 and clock>=roll_until:
		facing=movement
		hero.rotation.y=lerp_angle(hero.rotation.y,atan2(-facing.x,-facing.z),minf(1,dt*14))
	hero.position.x = clampf(hero.position.x,-30,30)
	hero.position.z = clampf(hero.position.z,-38,38)
	for plant in herbs.duplicate():
		if hero.position.distance_to(plant.node.position)<1.3:
			if plant.berry:
				berries+=1
				lessons.berry=true
				message="Клюква собрана. Клавиша 2 восстанавливает 10% маны."
			else:
				leaves+=1
				lessons.leaf=true
				message="Подорожник собран. Клавиша 1 восстанавливает 10% здоровья."
			plant.node.queue_free()
			herbs.erase(plant)
	if clock>attack_time and clock>=roll_until and clock>=jump_until and stamina>=10 and attack_held and not blocking():
		stamina-=10
		last_exertion=clock
		attack_time = clock+(1.0 if axe else 0.55)
		effect(hero.position+Vector3(0,1,0), Vector3(2.5,0.12,0.12), Color(0.9,0.85,0.65),0.18)
		for enemy in enemies:
			if hero.position.distance_to(enemy.node.position)<2.8: enemy.hp-=30 if axe else 20
	if clock>item_ready and clock>=roll_until and clock>=jump_until:
		if Input.is_physical_key_pressed(KEY_1) and leaves>0 and hp<100:
			leaves-=1; hp=minf(100,hp+10); item_ready=clock+0.6
		elif Input.is_physical_key_pressed(KEY_2) and berries>0 and mana<100:
			berries-=1; mana=minf(100,mana+10); item_ready=clock+0.6
	if clock>spell_time and clock>=roll_until and clock>=jump_until:
		if mana>=20 and cast_now:
			for key in [selected_spell]:
				mana-=20; spell_time=clock+3
				lessons.magic=true
				if key==KEY_Q:
					effect(hero.position+Vector3(0,4,0),Vector3(0.7,8,0.7),Color(1,0.75,0.15,0.65),0.7)
					effect(hero.position+Vector3(0,0.15,0),Vector3(8,0.1,8),Color(1,0.5,0.08,0.35),0.7)
				for enemy in enemies:
					if hero.position.distance_to(enemy.node.position)>8: continue
					if key!=KEY_Q and enemy.node!=target: continue
					if key==KEY_E:
						enemy.freeze=clock+3
						effect(enemy.node.position+Vector3(0,1,0),Vector3(0.85,2.1,0.85),Color(0.2,0.65,1,0.55),3)
						break
					if key==KEY_R:
						enemy.hp-=25
						enemy.freeze=clock+0.8
						root_effect(enemy.node.position)
						break
					if key==KEY_Q and hero.position.distance_to(enemy.node.position)<4: enemy.hp-=35
				message="Призыв коловрата" if key==KEY_Q else ("Призыв колотуна" if key==KEY_E else "Сила земли")
				break
	for enemy in enemies.duplicate():
		var previous: float=previous_enemy_hp.get(enemy.node,45.0)
		if enemy.hp<previous: damage_number(enemy.node.position,previous-enemy.hp)
		previous_enemy_hp[enemy.node]=enemy.hp
		if enemy.hp<=0:
			previous_enemy_hp.erase(enemy.node)
			enemy.node.queue_free(); enemies.erase(enemy); continue
		if clock<enemy.freeze: continue
		var distance: float = hero.position.distance_to(enemy.node.position)
		if distance>11: continue
		if combat_started<0: combat_started=clock
		if enemy!=enemies[0] and clock-combat_started<2.5: continue
		if distance>(7 if enemy.archer else 1.6):
			enemy.node.position += (hero.position-enemy.node.position).normalized()*dt*1.8
		elif clock>enemy.next:
			enemy.next=clock+2.5
			if enemy.archer:
				shoot(enemy.node.position+Vector3(0,1,0),hero.position+Vector3(0,1,0))
			else:
				melee_warning(enemy.node)
	if enemies.is_empty() and not talked:
		message="Опасность миновала. Подойдите к жителю за домами и нажмите V."
	if hp<=0: message="Герой пал. Нажмите «Начать заново»."


func effect(pos: Vector3, size: Vector3, color: Color, seconds: float) -> void:
	var item := shape(self,pos,size,color)
	var material := item.material_override as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	get_tree().create_timer(seconds,false).timeout.connect(func():
		if is_instance_valid(item): item.queue_free()
	)

func root_effect(pos: Vector3) -> void:
	for i in range(4):
		var root := shape(self,pos+Vector3(i*0.12,0.7,0),Vector3(0.18,1.4,0.18),Color(0.17,0.1,0.06))
		root.rotation.z = (i-1.5)*0.22
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
		root.scale.y=0.05
		tween.tween_property(root,"scale:y",1.0,0.15)
		tween.tween_interval(0.6)
		tween.tween_callback(root.queue_free)

func hurt() -> void:
	if talked or hp<=0: return
	if clock<roll_until-0.15: return
	var damage := 6
	if blocking() and stamina>=(12 if axe else 8):
		stamina-=12 if axe else 8
		last_exertion=clock
		damage=3 if axe else 2
	hp=maxf(0,hp-damage)
	if hp<=0: message="Герой пал. Нажмите «Начать заново»."

func melee_warning(attacker: Node3D) -> void:
	effect(attacker.position+Vector3(0,2.2,0),Vector3(0.3,0.3,0.3),Color.ORANGE,0.65)
	get_tree().create_timer(0.65,false).timeout.connect(func():
		if not is_instance_valid(attacker): return
		for enemy in enemies:
			if enemy.node==attacker and enemy.hp>0 and clock>=enemy.freeze and hero.position.distance_to(attacker.position)<2.2:
				hurt()
	)

func shoot(origin: Vector3, target: Vector3) -> void:
	var arrow := shape(self,origin,Vector3(0.12,0.12,0.8),Color(0.8,0.6,0.3))
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(arrow,"position",target,0.8)
	tween.tween_callback(func():
		if hero.position.distance_to(target-Vector3(0,1,0))<1: hurt()
		arrow.queue_free()
	)


func blocking() -> bool:
	return clock>=roll_until and clock>=jump_until and block_held

func dodge(direction: Vector3) -> bool:
	if not started or talked or hp<=0 or clock<roll_ready or clock<jump_until or stamina<25: return false
	lessons.roll=true
	roll_direction=direction.normalized() if direction.length()>0.1 else Vector3.BACK
	stamina-=25
	last_exertion=clock
	roll_until=clock+0.5
	roll_ready=clock+0.8
	message="Перекат: короткое окно защиты, затем восстановление."
	return true

func jump(bash: bool) -> bool:
	var cost := 30.0 if bash else 10.0
	if not started or talked or hp<=0 or clock<roll_until or clock<jump_until or stamina<cost: return false
	if bash and axe: return false
	stamina-=cost
	last_exertion=clock
	jump_started=clock
	jump_until=clock+0.65
	if bash:
		message="Удар щитом: оглушение на 1,5 секунды."
		effect(hero.position+Vector3(0,0.8,-1.2),Vector3(2,0.6,0.2),Color(0.7,0.8,1,0.7),0.3)
		for enemy in enemies:
			var offset: Vector3 = enemy.node.position-hero.position
			if offset.length()<3.2 and offset.z<0 and abs(offset.x)<2:
				enemy.hp-=15
				enemy.freeze=maxf(enemy.freeze,clock+1.5)
				enemy.node.position+=Vector3(0,0,-1)
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.physical_keycode==KEY_ESCAPE and started:
		set_paused(not paused)
		return
	if paused: return
	if event.physical_keycode in [KEY_Q,KEY_E,KEY_R]:
		selected_spell=event.physical_keycode
	if event.physical_keycode==KEY_V:
		speak_to_villager()
	if event.physical_keycode==KEY_TAB:
		select_target(true)
	if event.physical_keycode==KEY_ALT:
		var direction := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		dodge(direction)
	if event.physical_keycode==KEY_F:
		jump(not axe and block_held and Input.is_physical_key_pressed(KEY_W))


func setup_enemy_labels() -> void:
	for enemy in enemies:
		var label := Label3D.new()
		label.position=Vector3(0,2.7,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=42
		label.pixel_size=0.008
		label.outline_size=8
		enemy.node.add_child(label)
		enemy["label"]=label
	var mesh := TorusMesh.new()
	mesh.inner_radius=0.65
	mesh.outer_radius=0.78
	mesh.rings=16
	mesh.ring_segments=12
	target_ring=MeshInstance3D.new()
	target_ring.mesh=mesh
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(1,0.8,0.15)
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	target_ring.material_override=material
	add_child(target_ring)
	target_ring.hide()

func available_targets() -> Array:
	var result: Array=[]
	for enemy in enemies:
		if is_instance_valid(enemy.node) and enemy.hp>0 and hero.position.distance_to(enemy.node.position)<=10:
			result.append(enemy.node)
	result.sort_custom(func(a,b): return hero.position.distance_squared_to(a.position)<hero.position.distance_squared_to(b.position))
	return result

func select_target(cycle: bool=false) -> void:
	var candidates := available_targets()
	if candidates.is_empty():
		target=null
		return
	var index: int=candidates.find(target)
	if cycle:
		target=candidates[(index+1)%candidates.size()]
	elif index<0:
		target=candidates[0]

func update_targets() -> void:
	select_target()
	target_ring.visible=is_instance_valid(target)
	if is_instance_valid(target): target_ring.position=target.position+Vector3(0,0.12,0)
	for enemy in enemies:
		var distance: float=hero.position.distance_to(enemy.node.position)
		enemy.label.visible=distance<14
		var bars: int=clampi(int(ceil(enemy.hp/45.0*10)),0,10)
		var role: String="Лучник" if enemy.archer else "Сабельник"
		enemy.label.text=("> " if enemy.node==target else "")+role+"\n"+"|".repeat(bars)+".".repeat(10-bars)+" %d/45" % maxi(0,int(enemy.hp))
		enemy.label.modulate=Color(0.4,0.8,1) if clock<enemy.freeze else (Color(1,0.85,0.3) if enemy.node==target else Color.WHITE)


func set_paused(value: bool) -> void:
	paused=value
	attack_held=false
	block_held=false
	get_tree().paused=value
	attack_held=false
	block_held=false
	pause_panel.visible=value

func tutorial_text() -> String:
	if talked: return "МИССИЯ ЗАВЕРШЕНА\nСледующая цель: старая переправа\nПродолжение — в следующем эпизоде."
	if hp<=0: return "ПОРАЖЕНИЕ\nНачните заново и используйте\nщит, перекаты и растения."
	var text := "ОБУЧЕНИЕ · Escape — пауза\n"
	for entry in [["leaf","Собрать подорожник"],["berry","Собрать клюкву"],["roll","Выполнить перекат · Alt"],["magic","Применить магию · СКМ"]]:
		text+=("[+] " if lessons[entry[0]] else "[ ] ")+entry[1]+"\n"
	text+="\nПротивников осталось: %d\n" % enemies.size()
	text+="Найдите жителя за домами" if enemies.is_empty() else "Следуйте по тропе к деревне"
	return text


func spell_name() -> String:
	return "Коловрат" if selected_spell==KEY_Q else ("Колотун" if selected_spell==KEY_E else "Сила земли")

func _unhandled_input(event: InputEvent) -> void:
	if not started or paused or talked or hp<=0: return
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_MIDDLE and event.pressed:
		cast_requested=true
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and not paused:
			if event.button_index==MOUSE_BUTTON_WHEEL_UP: camera_distance=clampf(camera_distance-0.1,0.6,1.5)
			if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: camera_distance=clampf(camera_distance+0.1,0.6,1.5)
		if event.button_index==MOUSE_BUTTON_LEFT: attack_held=event.pressed and started and not paused
		if event.button_index==MOUSE_BUTTON_RIGHT: block_held=event.pressed and started and not paused


func resolve_obstacles(previous: Vector3, destination: Vector3) -> Vector3:
	# Split even a long frame into short steps so a roll cannot tunnel through a trunk.
	var distance: float=Vector2(destination.x-previous.x,destination.z-previous.z).length()
	var steps: int=maxi(1,int(ceil(distance/0.15)))
	var increment: Vector3=(destination-previous)/steps
	var result := previous
	for step in range(steps):
		var next_x: Vector3=result+Vector3(increment.x,0,0)
		if not blocked(next_x): result.x=next_x.x
		var next_z: Vector3=result+Vector3(0,0,increment.z)
		if not blocked(next_z): result.z=next_z.z
	result.y=destination.y
	return result

func blocked(pos: Vector3) -> bool:
	for obstacle in obstacles:
		var delta: Vector2 = Vector2(pos.x,pos.z)-obstacle.center
		var extent: Vector2=obstacle.half+Vector2(0.4,0.4)
		if absf(delta.x)<extent.x and absf(delta.y)<extent.y: return true
	return false


func speak_to_villager() -> bool:
	if not started or paused or hp<=0 or talked or not enemies.is_empty(): return false
	if hero.position.distance_to(villager.position)>=3: return false
	talked=true
	message=("Гой еси, добрая воительница!" if female else "Гой еси, добрый молодец!")+"\nСпасибо за помощь. Остальных увели к старой переправе.\nПервый эпизод завершён."
	return true


func setup_resource_bars(layer: CanvasLayer) -> void:
	var panel := VBoxContainer.new()
	panel.position=Vector2(20,15)
	panel.custom_minimum_size=Vector2(380,0)
	layer.add_child(panel)
	var colors := [Color(0.65,0.12,0.1),Color(0.12,0.35,0.8),Color(0.3,0.6,0.15)]
	for i in range(3):
		var row := HBoxContainer.new()
		panel.add_child(row)
		var caption := Label.new()
		caption.custom_minimum_size.x=130
		caption.text=["Здоровье","Мана","Выносливость"][i]
		row.add_child(caption)
		var bar := ProgressBar.new()
		bar.custom_minimum_size=Vector2(230,23)
		bar.max_value=100
		var style := StyleBoxFlat.new()
		style.bg_color=colors[i]
		bar.add_theme_stylebox_override("fill",style)
		row.add_child(bar)
		resource_bars.append(bar)
	spell_status=Label.new()
	panel.add_child(spell_status)

func update_resource_bars() -> void:
	if resource_bars.size()!=3: return
	resource_bars[0].value=hp
	resource_bars[1].value=mana
	resource_bars[2].value=stamina
	var remaining: float=maxf(0,spell_time-clock)
	var state := "готово · СКМ"
	if remaining>0: state="перезарядка %.1f с" % remaining
	elif mana<20: state="нужно 20 маны"
	spell_status.text=spell_name()+" · "+state
	spell_status.modulate=Color(0.65,0.85,1) if remaining<=0 and mana>=20 else Color(0.75,0.7,0.65)

func damage_number(pos: Vector3, amount: float) -> void:
	var label := Label3D.new()
	label.text="−%d" % int(amount)
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size=56
	label.pixel_size=0.009
	label.modulate=Color(1,0.75,0.35)
	add_child(label)
	label.position=pos+Vector3(0,2.3,0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(label,"position:y",label.position.y+1.2,0.8)
	tween.tween_callback(label.queue_free)
