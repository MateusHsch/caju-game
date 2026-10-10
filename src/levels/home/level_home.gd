class_name LevelHome
extends Node2D

## Main house level controller for Caju Game (Fase 1).
## Manages active character, ladder interaction, tutorial popup,
## and scene transition when both characters reach the top of the ladder.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const NEXT_LEVEL_PATH = "res://src/levels/home/level_home_2.tscn"

# Limite superior de Y para considerar que tocou a borda superior da tela
const TOP_SCREEN_Y_THRESHOLD: float = 16.0

var caju1: CharacterBody2D
var caju2: CharacterBody2D

var _caju1_at_top: bool = false
var _caju2_at_top: bool = false
var _transitioning: bool = false

func _ready() -> void:
	# Localiza os personagens na cena
	if has_node("Caju"):
		caju1 = get_node("Caju")
	elif has_node("Entities/Players/Caju"):
		caju1 = get_node("Entities/Players/Caju")
		
	if has_node("Caju2"):
		caju2 = get_node("Caju2")
	elif has_node("Entities/Players/Caju2"):
		caju2 = get_node("Entities/Players/Caju2")

	# Define o Caju inicial como ativo e o Caju2 como inativo
	if caju1 and caju1.has_method("make_active"):
		caju1.make_active()
	if caju2 and caju2.has_method("make_inactive"):
		caju2.make_inactive()
	
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

func _physics_process(_delta: float) -> void:
	if _transitioning:
		return
	
	# Verifica se os personagens na escada tocaram a borda superior da tela
	if caju1 and "na_escada" in caju1:
		if caju1.na_escada and caju1.position.y <= TOP_SCREEN_Y_THRESHOLD:
			_caju1_at_top = true
		elif not caju1.na_escada or caju1.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju1_at_top = false
			
	if caju2 and "na_escada" in caju2:
		if caju2.na_escada and caju2.position.y <= TOP_SCREEN_Y_THRESHOLD:
			_caju2_at_top = true
		elif not caju2.na_escada or caju2.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju2_at_top = false
	
	# Transita para a nova fase quando ambos terminarem de subir tocando o topo
	if _caju1_at_top or _caju2_at_top:
		_start_level_transition()

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false

func _start_level_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	print("Ambos os personagens alcançaram o topo da tela! Transitando para Fase 2...")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
	
	# Transição suave para a nova fase
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(_load_next_level)

func _load_next_level() -> void:
	get_tree().change_scene_to_file(NEXT_LEVEL_PATH)
