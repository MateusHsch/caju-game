class_name LevelHome2
extends Node2D

## Second house level controller for Caju Game (Fase 2).
## Environment: House (upper floor / continuation).
## Manages character switching, ladder mechanics, and completion.

const TutorialPopupClass = preload("res://src/ui/tutorial_popup.gd")
const PlayerHUDClass = preload("res://src/ui/player_hud.gd")
const ItemsHUDClass = preload("res://src/ui/items_hud.gd")
const TOP_SCREEN_Y_THRESHOLD: float = 16.0

var caju1: CharacterBody2D
var items_hud: CanvasLayer

var _caju1_at_top: bool = false
var _completed: bool = false

func _ready() -> void:
	if has_node("Caju"):
		caju1 = get_node("Caju")
	elif has_node("Entities/Players/Caju"):
		caju1 = get_node("Entities/Players/Caju")

	if caju1 and caju1.has_method("make_active"):
		caju1.make_active()

	# Instancia o tutorial popup (com botão '?' no canto)
	_setup_tutorial_popup()
	_setup_player_hud()
	_setup_items_hud()

func _setup_tutorial_popup() -> void:
	var popup = TutorialPopupClass.new()
	popup.name = "TutorialPopup"
	add_child(popup)
	popup.call_deferred("_hide_tutorial")

func _setup_player_hud() -> void:
	if not has_node("PlayerHUD"):
		var hud = PlayerHUDClass.new()
		hud.name = "PlayerHUD"
		add_child(hud)

func _setup_items_hud() -> void:
	if has_node("ItemsHUD"):
		items_hud = get_node("ItemsHUD") as CanvasLayer
	else:
		items_hud = ItemsHUDClass.new()
		items_hud.name = "ItemsHUD"
		add_child(items_hud)

	var total_items: int = 1
	var items_container = get_node_or_null("Items")
	if items_container:
		total_items = max(1, items_container.get_child_count())
	
	if has_node("/root/GameManager"):
		GameManager.set_level_items(total_items)
	if items_hud:
		items_hud.setup(total_items, 0)

func _physics_process(_delta: float) -> void:
	if _completed:
		return
	
	if caju1 and "na_escada" in caju1:
		if caju1.na_escada and caju1.position.y <= TOP_SCREEN_Y_THRESHOLD:
			if has_node("/root/GameManager") and not GameManager.are_all_level_items_collected():
				caju1.position.y = TOP_SCREEN_Y_THRESHOLD + 2.0
				_caju1_at_top = false
				if items_hud and items_hud.has_method("flash_warning"):
					items_hud.flash_warning()
				return
			_caju1_at_top = true
		elif not caju1.na_escada or caju1.position.y > TOP_SCREEN_Y_THRESHOLD + 20.0:
			_caju1_at_top = false
	
	if _caju1_at_top:
		_on_level_finished()

func _on_escada_body_entered(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = true

func _on_escada_body_exited(body: Node2D) -> void:
	if "na_escada" in body:
		body.na_escada = false

func _on_level_finished() -> void:
	if _completed:
		return
	_completed = true
	print("Parabéns! Fase 2 concluída com ambos os personagens!")
	
	if has_node("/root/EventBus"):
		get_node("/root/EventBus").level_completed.emit()
