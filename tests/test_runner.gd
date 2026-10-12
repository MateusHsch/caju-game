extends Node2D

## Integration test runner node for Caju Game.
## Runs within full game engine context with Autoloads initialized.

func _ready() -> void:
	print("[TEST] Starting automated verification in full engine context...")
	
	# =========================================================================
	# PARTE 1: VERIFICAÇÃO DA FASE DA CASA (SOLO CAJU)
	# =========================================================================
	var home_scene: PackedScene = load("res://src/levels/home/level_home.tscn")
	if not home_scene:
		push_error("[FAIL] Could not load level_home.tscn")
		get_tree().quit(1)
		return
	
	var home_level: Node2D = home_scene.instantiate()
	add_child(home_level)
	
	var caju1: CharacterBody2D = home_level.get_node_or_null("Caju")
	var caju2: CharacterBody2D = home_level.get_node_or_null("Caju2")
	var bottle: Area2D = home_level.get_node_or_null("Items/Bottle")
	var tutorial: CanvasLayer = home_level.get_node_or_null("TutorialPopup")
	var hud: CanvasLayer = home_level.get_node_or_null("PlayerHUD")
	
	# Test 1: Solo Caju em level_home
	assert(caju1 != null, "[FAIL] Caju not found in level_home")
	assert(caju2 == null, "[FAIL] Caju2 must not exist in level_home (solo phase requirement)")
	assert(caju1.is_in_group("player"), "[FAIL] Caju not in 'player' group")
	assert(caju1.is_active == true, "[FAIL] Caju should be active")
	print("[PASS] Test 1: level_home verified as solo Caju (Caju2 successfully removed).")
	
	# Test 2: Coleta de garrafa pelo Caju
	assert(bottle != null, "[FAIL] Bottle not found in level_home")
	var initial_bottles: int = GameManager.collected_bottles
	bottle._on_body_entered(caju1)
	assert(GameManager.collected_bottles == initial_bottles + 1, "[FAIL] Caju failed to collect bottle")
	print("[PASS] Test 2: Bottle collection verified for solo Caju.")
	
	# Test 3: TutorialPopup visual assets
	assert(tutorial != null, "[FAIL] TutorialPopup node not found in level")
	assert(tutorial.panel != null, "[FAIL] Tutorial panel not found")
	var panel_sb: StyleBox = tutorial.panel.get_theme_stylebox("panel")
	assert(panel_sb is StyleBoxTexture, "[FAIL] Tutorial panel must use StyleBoxTexture")
	assert((panel_sb as StyleBoxTexture).texture != null, "[FAIL] Tutorial panel texture missing")
	assert((panel_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_janela.png"), "[FAIL] Must be fundo_janela.png")
	
	assert(tutorial.close_button != null, "[FAIL] Tutorial close_button not found")
	var btn_sb: StyleBox = tutorial.close_button.get_theme_stylebox("normal")
	assert(btn_sb is StyleBoxTexture, "[FAIL] close_button must use StyleBoxTexture")
	assert((btn_sb as StyleBoxTexture).texture.resource_path.ends_with("fundo_botao.png"), "[FAIL] Must be fundo_botao.png")
	
	assert(tutorial.help_button != null, "[FAIL] Tutorial help_button not found")
	var help_tex_btn = tutorial.help_button as TextureButton
	assert(help_tex_btn != null, "[FAIL] help_button must be TextureButton")
	assert(help_tex_btn.texture_normal.resource_path.ends_with("botao_ajuda.png"), "[FAIL] Must be botao_ajuda.png")
	print("[PASS] Test 3: TutorialPopup visual assets verified.")
	
	# Test 4: PlayerHUD corações e sincronização de dano/cura
	assert(hud != null and hud is PlayerHUD, "[FAIL] PlayerHUD invalid")
	var player_hud = hud as PlayerHUD
	assert(player_hud.max_health == 3, "[FAIL] Max health must be 3")
	assert(player_hud.current_health == 3, "[FAIL] Current health must start at 3")
	
	player_hud.take_damage(1)
	assert(player_hud.current_health == 2, "[FAIL] Health should be 2 after damage")
	assert(player_hud.heart_icons[2].texture.resource_path.ends_with("coracao_vazio.png"), "[FAIL] Heart 3 empty")
	
	player_hud.heal(1)
	assert(player_hud.current_health == 3, "[FAIL] Health should be 3 after heal")
	assert(player_hud.heart_icons[2].texture.resource_path.ends_with("coracao_cheio.png"), "[FAIL] Heart 3 restored")
	
	caju1.take_damage(1)
	assert(caju1.current_health == 2, "[FAIL] caju1 health should decrease")
	assert(player_hud.current_health == 2, "[FAIL] HUD should sync with player health")
	caju1.heal(1)
	assert(player_hud.current_health == 3, "[FAIL] HUD should sync with player heal")
	print("[PASS] Test 4: PlayerHUD damage/heal and EventBus synchronization verified.")
	
	# Remove a fase home para carregar e testar o Telhado
	home_level.queue_free()
	
	# =========================================================================
	# PARTE 2: VERIFICAÇÃO DA FASE DO TELHADO (CAJU & KIKI + ÁRVORES)
	# =========================================================================
	var telhado_scene: PackedScene = load("res://src/levels/telhado/fase_1.tscn")
	if not telhado_scene:
		push_error("[FAIL] Could not load telhado/fase_1.tscn")
		get_tree().quit(1)
		return
		
	var telhado_level: Node2D = telhado_scene.instantiate()
	add_child(telhado_level)
	
	var telhado_caju: CharacterBody2D = telhado_level.get_node_or_null("Caju")
	var telhado_kiki: CharacterBody2D = telhado_level.get_node_or_null("Kiki")
	var telhado_hud: CanvasLayer = telhado_level.get_node_or_null("PlayerHUD")
	
	# Test 5: Presença de Caju e Kiki no Telhado
	assert(telhado_caju != null, "[FAIL] Caju not found in telhado/fase_1.tscn")
	assert(telhado_kiki != null, "[FAIL] Kiki not found in telhado/fase_1.tscn")
	assert(telhado_caju.is_in_group("player"), "[FAIL] Caju not in player group")
	assert(telhado_kiki.is_in_group("player"), "[FAIL] Kiki not in player group")
	print("[PASS] Test 5: Caju and Kiki verified in telhado/fase_1.tscn.")
	
	# Test 6: Atributos específicos da Kiki (pulo mais baixo, glide, animações)
	assert(telhado_kiki.can_glide == true, "[FAIL] Kiki must have can_glide == true")
	assert(telhado_kiki.jump_height < telhado_caju.jump_height, "[FAIL] Kiki jump_height must be lower than Caju")
	assert(telhado_kiki.jump_height == 32.0, "[FAIL] Kiki jump_height must be 32.0")
	var kiki_anim: AnimatedSprite2D = telhado_kiki.get_node_or_null("AnimatedSprite2D")
	assert(kiki_anim != null and kiki_anim.sprite_frames != null, "[FAIL] Kiki AnimatedSprite2D missing")
	assert(kiki_anim.sprite_frames.has_animation("idle"), "[FAIL] Kiki missing idle animation")
	assert(kiki_anim.sprite_frames.has_animation("walk"), "[FAIL] Kiki missing walk animation")
	assert(kiki_anim.sprite_frames.has_animation("jump"), "[FAIL] Kiki missing jump animation")
	assert(kiki_anim.sprite_frames.has_animation("glide"), "[FAIL] Kiki missing glide animation")
	print("[PASS] Test 6: Kiki mechanics (lower jump 32px, can_glide, idle/walk/jump/glide animations) verified.")
	
	# Test 7: Troca de Personagem (Caju <-> Kiki) e Atualização de Retrato
	assert(telhado_caju.is_active == true, "[FAIL] Caju should start active")
	assert(telhado_kiki.is_active == false, "[FAIL] Kiki should start inactive")
	
	GameManager.switch_player()
	assert(telhado_caju.is_active == false, "[FAIL] Caju should be inactive after switch")
	assert(telhado_kiki.is_active == true, "[FAIL] Kiki should be active after switch")
	assert(GameManager.active_player == telhado_kiki, "[FAIL] GameManager active_player should be Kiki")
	
	# Test 8: Gravidade no personagem inativo (anti-levitação no telhado)
	telhado_caju.velocity.y = 0.0
	var prev_vel: float = telhado_caju.velocity.y
	telhado_caju._physics_process(0.016)
	assert(telhado_caju.velocity.y > prev_vel, "[FAIL] Inactive Caju must apply gravity and fall")
	print("[PASS] Test 8: Inactive character gravity verified during co-op play.")
	
	# Test 9: Árvores em Múltiplos Planos (Background z_index=-1 e Foreground z_index=10)
	var bg_trees: Node2D = telhado_level.get_node_or_null("BackgroundTrees")
	var fg_trees: Node2D = telhado_level.get_node_or_null("ForegroundTrees")
	assert(bg_trees != null, "[FAIL] BackgroundTrees node missing in telhado")
	assert(fg_trees != null, "[FAIL] ForegroundTrees node missing in telhado")
	assert(bg_trees.z_index == -1, "[FAIL] BackgroundTrees must have z_index = -1")
	assert(fg_trees.z_index == 10, "[FAIL] ForegroundTrees must have z_index = 10")
	assert(bg_trees.get_child_count() >= 3, "[FAIL] At least 3 background trees expected")
	assert(fg_trees.get_child_count() >= 2, "[FAIL] At least 2 foreground trees expected")
	for child in bg_trees.get_children():
		var sprite = child as Sprite2D
		assert(sprite != null and sprite.texture.resource_path.ends_with("arvore_noite.png"), "[FAIL] Must be arvore_noite.png")
	for child in fg_trees.get_children():
		var sprite = child as Sprite2D
		assert(sprite != null and sprite.texture.resource_path.ends_with("arvore_noite.png"), "[FAIL] Must be arvore_noite.png")
	print("[PASS] Test 9: Rooftop trees (Background z=-1, Foreground z=10 with arvore_noite.png) verified.")
	
	print("[TEST] ALL INTEGRATION SUITE CHECKS (SOLO HOME + TELHADO CO-OP & KIKI + ASSETS) PASSED WITH FLYING COLORS!")
	get_tree().quit(0)
