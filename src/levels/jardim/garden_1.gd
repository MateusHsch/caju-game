extends Node2D

## Legacy / Root game controller.
## Routes input to GameManager and supports fallback switching.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup_2.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")

@export var caju: CharacterBody2D
@export var kiki: CharacterBody2D

var current_player: CharacterBody2D

func _ready() -> void:
	# Localiza o personagem na cena
	if has_node("Caju"):
		caju = get_node("Caju")
		caju.set_camera_limits(0, 1115, 0, 180)
	else:
		print("ERRO: Caju não foi encontrado!")
	
	if has_node("Kiki"):
		kiki = get_node("Kiki")
		kiki.set_camera_limits(0, 1115, 0, 180)
	else:
		print("ERRO: Kiki não foi encontrada!")

	# Define o Caju como ativo
	if caju and caju.has_method("make_active"):
		caju.make_active()
	else:
		print("ERRO: Caju sem make_active!")
	
	if kiki and kiki.has_method("make_inactive"):
		kiki.make_inactive()
	else:
		print("ERRO: Kiki sem make_active!")
		
	# Instancia o popup de tutorial com botão '?'
	_setup_tutorial_popup()
	_setup_player_hud()

func _setup_tutorial_popup() -> void:
	var popup = TutorialPopupClass.new()
	popup.name = "TutorialPopup"
	add_child(popup)

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

func _unhandled_input(event: InputEvent) -> void:
	# Only use local fallback when GameManager autoload is not present.
	# GameManager already listens for switch_character globally.
	if not has_node("/root/GameManager"):
		if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
			switch_character()

func switch_character() -> void:
	# Só permite a troca se AMBOS os personagens existirem na cena
	if caju and kiki:
		if current_player == caju:
			caju.make_inactive()
			kiki.make_active()
			current_player = kiki
		else:
			kiki.make_inactive()
			caju.make_active()
			current_player = caju

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false
