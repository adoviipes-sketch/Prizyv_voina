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
var female := false
var axe := false
var started := false
var hud: Label
var menu: VBoxContainer
var message := "Лесная тропа ведёт к разорённой деревне."
var talked := false

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
		shape(self,Vector3(x,0.7,-22),Vector3(4,1.4,4),Color(0.15,0.12,0.10))
		shape(self,Vector3(x,1.7,-23),Vector3(4,0.3,0.3),Color(0.08,0.07,0.06))
	hero = person(Vector3(0,0,30),Color(0.3,0.35,0.4))
	for i in range(3):
		var enemy := person(Vector3((i-1)*3,0,-15-i*2),Color(0.45,0.25,0.15))
		enemies.append({"node":enemy,"hp":45.0,"freeze":0.0,"next":0.0,"archer":i==2})
	person(Vector3(4,0,-28),Color(0.35,0.4,0.3))
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20,20)
	hud.add_theme_font_size_override("font_size",20)
	layer.add_child(hud)
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
			if not axe: shape(hero,Vector3(-0.5,0.9,0),Vector3(0.15,0.85,0.7),Color(0.32,0.19,0.1))
		)

func _process(dt: float) -> void:
	clock += dt
	camera.position = hero.position+Vector3(0,15,12)
	camera.look_at(hero.position)
	hud.text = "Лесная переправа · прототип\nЗдоровье %d · Мана %d · Листья %d · Клюква %d\nWASD — ходьба · пробел — удар · Shift — щит\nQ — коловрат · E — колотун · R — корень · 1/2 — восстановление\n%s" % [hp,mana,leaves,berries,message]
	if not started or hp<=0: return
	var move := Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	hero.position += move.normalized()*dt*5
	hero.position.x = clampf(hero.position.x,-30,30)
	hero.position.z = clampf(hero.position.z,-38,38)
	for plant in herbs.duplicate():
		if hero.position.distance_to(plant.node.position)<1.3:
			if plant.berry: berries+=1
			else: leaves+=1
			plant.node.queue_free()
			herbs.erase(plant)
	if clock>attack_time and Input.is_physical_key_pressed(KEY_SPACE):
		attack_time = clock+(1.0 if axe else 0.55)
		for enemy in enemies:
			if hero.position.distance_to(enemy.node.position)<2.8: enemy.hp-=30 if axe else 20
	if clock>spell_time:
		if Input.is_physical_key_pressed(KEY_1) and leaves>0 and hp<100:
			leaves-=1; hp=minf(100,hp+10); spell_time=clock+0.6
		elif Input.is_physical_key_pressed(KEY_2) and berries>0 and mana<100:
			berries-=1; mana=minf(100,mana+10); spell_time=clock+0.6
		elif mana>=20:
			for key in [KEY_Q,KEY_E,KEY_R]:
				if not Input.is_physical_key_pressed(key): continue
				mana-=20; spell_time=clock+3
				for enemy in enemies:
					if hero.position.distance_to(enemy.node.position)>8: continue
					if key==KEY_E: enemy.freeze=clock+3; break
					if key==KEY_R: enemy.hp-=25; enemy.freeze=clock+0.8; break
					if key==KEY_Q and hero.position.distance_to(enemy.node.position)<4: enemy.hp-=35
				message="Призыв коловрата" if key==KEY_Q else ("Призыв колотуна" if key==KEY_E else "Сила земли")
				break
	for enemy in enemies.duplicate():
		if enemy.hp<=0:
			enemy.node.queue_free(); enemies.erase(enemy); continue
		if clock<enemy.freeze: continue
		var distance: float = hero.position.distance_to(enemy.node.position)
		if distance>11: continue
		if distance>(7 if enemy.archer else 1.6):
			enemy.node.position += (hero.position-enemy.node.position).normalized()*dt*1.8
		elif clock>enemy.next:
			enemy.next=clock+2.5
			hp-=2 if not axe and Input.is_physical_key_pressed(KEY_SHIFT) else 6
	if enemies.is_empty() and hero.position.z < -25 and not talked:
		talked=true
		message=("Гой еси, добрая воительница!" if female else "Гой еси, добрый молодец!")+" Людей увели к переправе.\nПервый эпизод завершён."
	if hp<=0: message="Герой пал. Перезапустите игру для новой попытки."
