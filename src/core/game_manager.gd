extends Node

## Global Game Manager for Caju Game.
## Coordinates player registry, character switching, score and global gameplay state.

var active_player: CharacterBody2D = null
var players: Array[CharacterBody2D] = []
var collected_bottles: int = 0
var score: int = 0
var level_total_items: int = 0
var level_collected_items: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	var tree: SceneTree = get_tree()
	if tree and tree.paused:
		return
	if event.is_action_pressed("switch_character") or event.is_action_pressed("ui_focus_next"):
		switch_player()

func register_player(player: CharacterBody2D) -> void:
	if not players.has(player):
		players.append(player)
		if active_player == null:
			if ("is_active" in player and player.is_active) or players.size() == 1:
				active_player = player

func unregister_player(player: CharacterBody2D) -> void:
	players.erase(player)
	if active_player == player:
		active_player = players[0] if players.size() > 0 else null

func switch_player() -> void:
	if players.size() < 2:
		return
	
	var current_index: int = players.find(active_player)
	if current_index == -1:
		current_index = 0
	var next_index: int = (current_index + 1) % players.size()
	
	if active_player != null and active_player.has_method("make_inactive"):
		active_player.make_inactive()
		
	active_player = players[next_index]
	if active_player != null and active_player.has_method("make_active"):
		active_player.make_active()
		
	EventBus.player_swapped.emit(active_player)

func set_level_items(total: int) -> void:
	level_total_items = total
	level_collected_items = 0
	if has_node("/root/EventBus"):
		EventBus.level_items_updated.emit(level_collected_items, level_total_items)

func are_all_level_items_collected() -> bool:
	return level_collected_items >= level_total_items

func collect_bottle(collector: CharacterBody2D) -> void:
	collected_bottles += 1
	level_collected_items += 1
	score += 10
	if has_node("/root/EventBus"):
		EventBus.item_collected.emit("bottle", collector)
		EventBus.level_items_updated.emit(level_collected_items, level_total_items)
