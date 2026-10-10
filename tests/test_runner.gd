extends Node2D

## Integration test runner node.
## Runs within full game engine context with Autoloads initialized.

func _ready() -> void:
	print("[TEST] Starting automated verification in full engine context...")
	
	# Load main scene
	var level_scene: PackedScene = load("res://src/levels/home/level_home.tscn")
	if not level_scene:
		push_error("[FAIL] Could not load level_home.tscn")
		get_tree().quit(1)
		return
	
	var level: Node2D = level_scene.instantiate()
	add_child(level)
	
	var caju1: CharacterBody2D = level.get_node_or_null("Caju")
	var caju2: CharacterBody2D = level.get_node_or_null("Caju2")
	var bottle: Area2D = level.get_node_or_null("Items/Bottle")
	var tutorial: CanvasLayer = level.get_node_or_null("TutorialPopup")
	var hud: CanvasLayer = level.get_node_or_null("PlayerHUD")
	
	# Test 1: Verify player instances
	assert(caju1 != null, "[FAIL] Caju1 not found")
	assert(caju2 != null, "[FAIL] Caju2 not found")
	assert(caju1.is_in_group("player"), "[FAIL] Caju1 not in 'player' group")
	assert(caju2.is_in_group("player"), "[FAIL] Caju2 not in 'player' group")
	print("[PASS] Test 1: Both player instances found and in group 'player'.")
	
	# Test 2: Character switching
	assert(caju1.is_active == true, "[FAIL] Caju1 should be initially active")
	assert(caju2.is_active == false, "[FAIL] Caju2 should be initially inactive")
	
	# Switch via GameManager
	GameManager.switch_player()
	assert(caju1.is_active == false, "[FAIL] Caju1 should now be inactive")
	assert(caju2.is_active == true, "[FAIL] Caju2 should now be active")
	assert(GameManager.active_player == caju2, "[FAIL] GameManager active_player mismatch")
	print("[PASS] Test 2: Character switching toggles active states properly via GameManager.")
	
	# Test 3: Inactive character gravity (verifying it does not freeze in mid-air!)
	caju1.velocity.y = 0.0
	var prev_vel_y: float = caju1.velocity.y
	# Simulate physics process on inactive character
	caju1._physics_process(0.016)
	assert(caju1.velocity.y > prev_vel_y, "[FAIL] Inactive character must apply gravity and fall!")
	print("[PASS] Test 3: Inactive character calculates gravity correctly (anti-levitation fix verified).")
	
	# Test 4: Bottle collection by Caju 2 (verifying player 2 can collect items!)
	assert(bottle != null, "[FAIL] Bottle not found")
	var initial_bottles: int = GameManager.collected_bottles
	bottle._on_body_entered(caju2)
	assert(GameManager.collected_bottles == initial_bottles + 1, "[FAIL] Caju2 failed to collect bottle!")
	print("[PASS] Test 4: Caju2 successfully collected bottle (bottle collection bug fixed).")
	
	# Switch back to caju1 for subsequent tests
	GameManager.switch_player()
	assert(GameManager.active_player == caju1, "[FAIL] Active player should be caju1 again")
	
	# Test 5: Verify TutorialPopup custom visual assets
	assert(tutorial != null, "[FAIL] TutorialPopup node not found in level")
	assert(tutorial.panel != null, "[FAIL] Tutorial panel not found")
	var panel_sb: StyleBox = tutorial.panel.get_theme_stylebox("panel")
	assert(panel_sb is StyleBoxTexture, "[FAIL] Tutorial panel must use StyleBoxTexture")
	assert((panel_sb as StyleBoxTexture).texture != null, "[FAIL] Tutorial panel StyleBoxTexture texture missing")
	assert((panel_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_janela.png"), "[FAIL] Tutorial panel texture must be fundo_janela.png")
	
	assert(tutorial.close_button != null, "[FAIL] Tutorial close_button not found")
	var btn_sb: StyleBox = tutorial.close_button.get_theme_stylebox("normal")
	assert(btn_sb is StyleBoxTexture, "[FAIL] close_button must use StyleBoxTexture for normal state")
	assert((btn_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_botao.png"), "[FAIL] close_button texture must be fundo_botao.png")
	
	assert(tutorial.help_button != null, "[FAIL] Tutorial help_button not found")
	assert(tutorial.help_button is TextureButton, "[FAIL] help_button must be a TextureButton")
	var help_tex_btn = tutorial.help_button as TextureButton
	assert(help_tex_btn.texture_normal != null and help_tex_btn.texture_normal.resource_path.ends_with("botao_ajuda.png"), "[FAIL] help_button normal texture must be botao_ajuda.png")
	assert(help_tex_btn.texture_pressed != null and help_tex_btn.texture_pressed.resource_path.ends_with("botao_ajuda_press.png"), "[FAIL] help_button pressed texture must be botao_ajuda_press.png")
	print("[PASS] Test 5: TutorialPopup successfully configured with fundo_janela.png, fundo_botao.png and TextureButton.")
	
	# Test 6: Verify PlayerHUD existence and initialization
	assert(hud != null, "[FAIL] PlayerHUD node not found in level")
	assert(hud is PlayerHUD, "[FAIL] hud node must be instance of PlayerHUD")
	var player_hud = hud as PlayerHUD
	assert(player_hud.max_health == 3, "[FAIL] PlayerHUD max_health must be 3")
	assert(player_hud.current_health == 3, "[FAIL] PlayerHUD current_health must start at 3")
	assert(player_hud.heart_icons.size() == 3, "[FAIL] PlayerHUD must have 3 heart icons")
	for h_icon in player_hud.heart_icons:
		assert(h_icon.texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart icon must initially be coracao_cheio.png")
	print("[PASS] Test 6: PlayerHUD correctly initialized with 3 full hearts and portrait.")
	
	# Test 7: Verify PlayerHUD damage, heal, and clamping
	player_hud.take_damage(1)
	assert(player_hud.current_health == 2, "[FAIL] Health should be 2 after 1 damage")
	assert(player_hud.heart_icons[0].texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart 1 should remain full")
	assert(player_hud.heart_icons[1].texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart 2 should remain full")
	assert(player_hud.heart_icons[2].texture.resource_path.ends_with("coracao_vazio.png"), "[FAIL] Heart 3 should be empty")
	
	player_hud.take_damage(2)
	assert(player_hud.current_health == 0, "[FAIL] Health should be 0 after taking 2 more damage")
	for h_icon in player_hud.heart_icons:
		assert(h_icon.texture.resource_path.ends_with("coracao_vazio.png"), "[FAIL] All hearts should now be coracao_vazio.png")
		
	# Test clamp under 0
	player_hud.take_damage(5)
	assert(player_hud.current_health == 0, "[FAIL] Health should clamp at 0")
	
	# Test heal
	player_hud.heal(1)
	assert(player_hud.current_health == 1, "[FAIL] Health should be 1 after heal 1")
	assert(player_hud.heart_icons[0].texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart 1 should be restored to full")
	assert(player_hud.heart_icons[1].texture.resource_path.ends_with("coracao_vazio.png"), "[FAIL] Heart 2 should remain empty")
	
	# Test heal clamp to max
	player_hud.heal(10)
	assert(player_hud.current_health == 3, "[FAIL] Health should clamp at max_health (3)")
	for h_icon in player_hud.heart_icons:
		assert(h_icon.texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] All hearts should be full after full heal")
	print("[PASS] Test 7: PlayerHUD take_damage, heal, and heart texture swapping verified.")
	
	# Test 8: Verify Player entity health methods and event synchronization
	assert("current_health" in caju1, "[FAIL] caju1 must have current_health property")
	assert("take_damage" in caju1, "[FAIL] caju1 must have take_damage method")
	caju1.take_damage(1)
	assert(caju1.current_health == 2, "[FAIL] caju1 current_health should be 2 after damage")
	assert(player_hud.current_health == 2, "[FAIL] player_hud should synchronize with active player's damage via EventBus")
	caju1.heal(1)
	assert(caju1.current_health == 3, "[FAIL] caju1 current_health should be restored to 3")
	assert(player_hud.current_health == 3, "[FAIL] player_hud should synchronize with active player's heal via EventBus")
	print("[PASS] Test 8: Player entity health methods and EventBus health synchronization verified.")
	
	# Test 9: Verify Portrait update on character swap
	assert(player_hud.portrait != null, "[FAIL] PlayerHUD portrait node not found")
	assert(player_hud.portrait.texture.resource_path.ends_with("personagem_caju.png"), "[FAIL] Initial portrait should be Caju 1")
	GameManager.switch_player() # switch to Caju2
	assert(player_hud.portrait.texture.resource_path.ends_with("personagem_caju2.png"), "[FAIL] Swapped portrait should be Caju 2")
	GameManager.switch_player() # switch back to Caju1
	assert(player_hud.portrait.texture.resource_path.ends_with("personagem_caju.png"), "[FAIL] Swapped back portrait should be Caju 1")
	print("[PASS] Test 9: Portrait dynamically switches between Caju 1 and Caju 2 on character swap.")
	
	print("[TEST] ALL 9 SUITE CHECKS PASSED WITH FLYING COLORS!")
	get_tree().quit(0)
