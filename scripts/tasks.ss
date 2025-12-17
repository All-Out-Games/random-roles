import "core:core.ss"
import "gamemanager.ss"

NUM_TASKS: int : 8;

Task_Base :: class {
	id: string;
	started: bool;
	completed: bool;

	start_attempt :: proc(using this: Task_Base, player: Player) {
		if started {
			return;
		}
		started = true;
	}

	complete_attempt :: proc(using this: Task_Base, player: Player, success: bool) {
		log(format_string("Task % completed: %", .{this.id, success}));
		if completed {
			return;
		}
		if success {
			completed = true;
			player->Notify("You completed the task!");
		} else {
			player->Notify("You failed the task!");
		}
	}
}

get_random_task_list :: proc(num_tasks: int, player: Player) -> List(Task_Base) {
	task_list: List(Task_Base);
	
	// Build a pool of available task indices
	available_indices: List(int);
	for i: 0..NUM_TASKS-1 {
		append(&available_indices, i);
	}
	
	// Select 5 unique tasks (or fewer if num_tasks < 5)
	tasks_to_select := min(5, min(num_tasks, NUM_TASKS));
	for i: 0..tasks_to_select-1 {
		// Pick a random index from remaining available tasks
		random_pick := rng_range_int(&server_rng, 0, available_indices.elements.count-1);
		task_to_add_index := available_indices.elements[random_pick];
		
		// Remove the selected index from the pool (swap with last and pop)
		last_idx := available_indices.elements.count - 1;
		available_indices.elements[random_pick] = available_indices.elements[last_idx];
		pop(&available_indices);
		
		switch task_to_add_index {
			case 0: {
					task := new(Task_Throw_Away_Garbage);
					task.id = "throw_away_garbage";
					append(&task_list, task);
				}
			case 1: {
					task := new(Task_Calibrate_Teleporter);
					task.id = "calibrate_teleporter";
					append(&task_list, task);
				}
			case 2: {
					task := new(Task_Cypher);
					task.id = "cypher";
					append(&task_list, task);
				}
			case 3: {
					task := new(Task_Anagram_Puzzle);
					task.id = "anagram_puzzle";
					append(&task_list, task);
				}
			case 4: {
					task := new(Task_Reroute_Power);
					task.id = "reroute_power";
					append(&task_list, task);
				}
			case 5: {
					task := new(Task_Guide_The_Electron);
					task.id = "guide_the_electron";
					append(&task_list, task);
				}
			case 6: {
					task := new(Task_Signal_Sync);
					task.id = "signal_sync";
					append(&task_list, task);
				}
			case 7: {
					task := new(Task_Build_A_Robot);
					task.id = "build_a_robot";
					append(&task_list, task);
				}
		}
	}
	return task_list;
}

update_tasks :: proc(player: Player) {
	for i: 0..player.active_tasks.elements.count-1 {
		//log("%", .{#object_type(player.active_tasks.elements[i])});
		switch #object_type(player.active_tasks.elements[i]) {
			case Task_Throw_Away_Garbage: player.active_tasks.elements[i].(Task_Throw_Away_Garbage)->update_task(player);
			case Task_Calibrate_Teleporter: player.active_tasks.elements[i].(Task_Calibrate_Teleporter)->update_task(player);
			case Task_Cypher: player.active_tasks.elements[i].(Task_Cypher)->update_task(player);
			case Task_Anagram_Puzzle: player.active_tasks.elements[i].(Task_Anagram_Puzzle)->update_task(player);
			case Task_Reroute_Power: player.active_tasks.elements[i].(Task_Reroute_Power)->update_task(player);
			case Task_Guide_The_Electron: player.active_tasks.elements[i].(Task_Guide_The_Electron)->update_task(player);
			case Task_Signal_Sync: player.active_tasks.elements[i].(Task_Signal_Sync)->update_task(player);
			case Task_Build_A_Robot: player.active_tasks.elements[i].(Task_Build_A_Robot)->update_task(player);
		}
	}
}

get_task_display_name :: proc(task_id: string) -> string {
	switch task_id {
		case "throw_away_garbage":
			return "Throw Away Garbage";
		case "calibrate_teleporter":
			return "Calibrate Teleporter";
		case "cypher":
			return "Solve the Cypher";
		case "anagram_puzzle":
			return "Solve the Anagram";
		case "reroute_power":
			return "Reroute Power";
		case "guide_the_electron":
			return "Guide the Electron";
		case "signal_sync":
			return "Sync Signals";
		case "build_a_robot":
			return "Build a Robot";
		case:
			return task_id;
	}
}

update_tasks_ui :: proc(player: Player) {
	// Only show tasks for alive civilians during gameplay
	if !player->is_local_or_server() {
		return;
	}
	if player.player_type != Player_Type.CIVILIAN {
		return;
	}
	if player.player_state != Player_State.ALIVE {
		return;
	}
	if game_state != Game_State.INGAME {
		return;
	}
	if player.active_tasks.elements.count == 0 {
		return;
	}
	
	screen := UI.get_safe_screen_rect();
	
	// Create a panel on the left side
	panel_rect := screen->cut_left(300)->inset(250, 0, 250, 10);
	
	// Background panel
	bg_texture := get_asset(Texture_Asset, "$AO/white.png");
	UI.quad(panel_rect, bg_texture, .{0.1, 0.1, 0.15, 0.9});
	
	// Title - cut from top
	title_rect := panel_rect->cut_top(50);
	title_ts := UI.default_text_settings();
	title_ts.size = 32;
	title_ts.color = .{1, 1, 1, 1};
	title_ts.halign = .CENTER;
	title_ts.valign = .CENTER;
	UI.text(title_rect, title_ts, "TASKS");
	
	// Draw each task - cut from top progressively
	for i: 0..player.active_tasks.elements.count-1 {
		task_id := player.active_tasks.elements[i].id;
		task_started := player.active_tasks.elements[i].started;
		task_completed := player.active_tasks.elements[i].completed;
		
		// Cut top for this task entry
		entry_rect := panel_rect->cut_top(40);
		
		// Color based on completion
		if task_completed {
			UI.quad(entry_rect, null, .{0.2, 0.6, 0.2, 0.7});
		} else {
			UI.quad(entry_rect, null, .{0.3, 0.3, 0.3, 0.7});
		}
		
		// Task text
		task_name := get_task_display_name(task_id);
		if task_completed {
			task_name = format_string("[X] %", .{task_name});
		} else if task_started {
			task_name = format_string("[...] %", .{task_name});
		} else {
			task_name = format_string("[ ] %", .{task_name});
		}
		
		// Inset the text rect slightly from the entry
		text_rect := entry_rect->inset(5, 10, 5, 10);
		task_ts := UI.default_text_settings();
		task_ts.size = 24;
		if task_completed {
			task_ts.color = .{0.5, 1, 0.5, 1};
		} else {
			task_ts.color = .{1, 1, 1, 1};
		}
		task_ts.halign = .LEFT;
		task_ts.valign = .CENTER;
		UI.text(text_rect, task_ts, task_name);
	}
}

Task_Throw_Away_Garbage :: class : Task_Base {
	update_task :: proc(using this: Task_Throw_Away_Garbage, player: Player) {
		if !started {
			return;
		}
		log(format_string("Throw Away Garbage Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Reroute_Power :: class : Task_Base {
	update_task :: proc(using this: Task_Reroute_Power, player: Player) {
		if !started {
			return;
		}
		log(format_string("Reroute Power Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Guide_The_Electron :: class : Task_Base {
	update_task :: proc(using this: Task_Guide_The_Electron, player: Player) {
		if !started {
			return;
		}
		log(format_string("Guide the Electron Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Signal_Sync :: class : Task_Base {
	update_task :: proc(using this: Task_Signal_Sync, player: Player) {
		if !started {
			return;
		}
		log(format_string("Signal Sync Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Build_A_Robot :: class : Task_Base {
	update_task :: proc(using this: Task_Build_A_Robot, player: Player) {
		if !started {
			return;
		}
		log(format_string("Build a Robot Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Anagram_Puzzle :: class : Task_Base {
	update_task :: proc(using this: Task_Anagram_Puzzle, player: Player) {
		if !started {
			return;
		}
		log(format_string("Anagram Puzzle Task Updated"));
		//Instant success
		complete_attempt(this, player, true);
	}
}

Task_Calibrate_Teleporter :: class : Task_Base {
	// Task state
	ui_active: bool;
	reticle_position: v2;  // Normalized position within targeting area (0-1 range)
	target_position: v2;   // The random target spot to find (0-1 range)
	rng_initialized: bool;
	success_time: float;   // Time when success was achieved
	task_complete_displayed: bool;
	
	// Textures
	window_texture: Texture_Asset;
	cursor_texture: Texture_Asset;
	schleem_hologram_L: Texture_Asset;
	schleem_hologram_R: Texture_Asset;
	schleem_piece_L: Texture_Asset;
	schleem_piece_R: Texture_Asset;
	schleem_alive: Texture_Asset;
	
	ALIGNMENT_THRESHOLD :: 0.05;  // How close reticle needs to be to target
	SUCCESS_DISPLAY_TIME :: 2.5;  // How long to show thumbs up before closing
	
	init_textures :: proc(using this: Task_Calibrate_Teleporter) {
		window_texture = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/window.png");
		cursor_texture = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/cursor.png");
		schleem_hologram_L = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/schleem_hologram_piece_L.png");
		schleem_hologram_R = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/schleem_hologram_piece_R.png");
		schleem_piece_L = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/schleem_piece_L.png");
		schleem_piece_R = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/schleem_piece_R.png");
		schleem_alive = get_asset(Texture_Asset, "sprites/tasks/calibrate_teleporter/schleem_alive.png");
	}
	
	init_target :: proc(using this: Task_Calibrate_Teleporter, player: Player) {
		if rng_initialized {
			return;
		}
		rng_initialized = true;
		target_position.x = rng_range_float(&server_rng, 0.2, 0.8);
		target_position.y = rng_range_float(&server_rng, 0.2, 0.8);
		reticle_position = .{0.5, 0.5};
	}

	update_task :: proc(using this: Task_Calibrate_Teleporter, player: Player) {
		if !started {
			return;
		}
		if completed {
			return;
		}
		
		if !player->is_local_or_server() {
			return;
		}
		
		if window_texture == null {
			init_textures(this);
		}
		init_target(this, player);
		
		if !ui_active {
			ui_active = true;
		}
		
		if success_time > 0.0 {
			elapsed := get_time() - success_time;
			if elapsed >= SUCCESS_DISPLAY_TIME {
				ui_active = false;
				complete_attempt(this, player, true);
				return;
			}
			draw_calibrate_ui(this, player, true);
			return;
		}
		
		draw_calibrate_ui(this, player, false);
	}

	draw_calibrate_ui :: proc(using task: Task_Calibrate_Teleporter, player: Player, success_state: bool) {
		screen := UI.get_screen_rect();
		
		bg_texture := get_asset(Texture_Asset, "$AO/white.png");
		UI.quad(screen, bg_texture, .{0.0, 0.0, 0.0, 0.85});
		
		// Window in center - make it appropriately sized
		window_size := 800.0;
		window_rect := screen->center_rect()->grow(window_size / 2.0);
		window_rect = window_rect->fit_aspect(task.window_texture.aspect, .KEEP_HEIGHT);
		UI.quad(window_rect, task.window_texture, .{1, 1, 1, 1});
		
		target_area := window_rect->inset_unscaled(window_rect->height() * 0.57, window_rect->width() * 0.242, window_rect->height() * 0.0365, window_rect->width() * 0.242);
		schleem_rect := window_rect->center_rect()->grow(150)->offset(0, 220);
		
		// DEBUG: Draw target area background
		//UI.quad(target_area, bg_texture, .{1, 0, 0, 0.6});
		
		if success_state {
			// SUCCESS STATE - Show alive schleem with thumbs up
			schleem_rect = schleem_rect->fit_aspect(task.schleem_alive.aspect, .KEEP_WIDTH);
			pulse := 1.0 + sin(get_time() * 8.0) * 0.05;
			schleem_rect = schleem_rect->scale(pulse, pulse);
			
			UI.quad(schleem_rect, task.schleem_alive, .{1, 1, 1, 1});
			
			success_rect := window_rect->cut_top(50)->offset(0, 20);
			success_ts := UI.default_text_settings();
			success_ts.size = 42;
			success_ts.color = .{0.3, 1.0, 0.4, 1.0};
			success_ts.halign = .CENTER;
			success_ts.valign = .CENTER;
			UI.text(success_rect, success_ts, "TELEPORTATION COMPLETE!");
		} else {
			// CALIBRATION STATE - Handle input and draw hologram pieces
			UI.push_id("calibrate_target_area");
			defer UI.pop_id();
			
			interact := UI.button(target_area, .{}, .{}, "");
			
			if interact.active {
				// Calculate relative position within target area
				input_area_size := target_area.max - target_area.min;
				
				if input_area_size.x > 0.0 && input_area_size.y > 0.0 {
					rel_x := (interact.mouse_position.x - target_area.min.x) / input_area_size.x;
					rel_y := (interact.mouse_position.y - target_area.min.y) / input_area_size.y;
					task.reticle_position.x = clamp(rel_x, 0.0, 1.0);
					task.reticle_position.y = clamp(rel_y, 0.0, 1.0);
				}
			}
			
			// Calculate distance from target (0 = perfect, 1 = far)
			dx := task.reticle_position.x - task.target_position.x;
			dy := task.reticle_position.y - task.target_position.y;
			distance := sqrt(dx * dx + dy * dy);
			max_distance := sqrt(2.0);  // Max possible distance in unit square
			alignment := 1.0 - clamp(distance / max_distance, 0.0, 1.0);
			
			// Check for success
			if distance < ALIGNMENT_THRESHOLD {
				task.success_time = get_time();
			}
			
			// Calculate split offset based on distance (further = more split)
			split_amount := (1.0 - alignment) * 75.0;
			
			// Hologram opacity - more solid as alignment increases
			hologram_alpha := 0.3 + alignment * 0.4;
			solid_alpha := clamp(alignment * alignment - 0.5, 0.0, 0.5) * 2.0;  // Quadratic for dramatic reveal
			left_rect := schleem_rect->offset(-split_amount*5, 0);
			right_rect := schleem_rect->offset(split_amount*5, 0);
			// Hologram tint (cyan/green glow)
			hologram_tint := v4.{0.3, 1.0, 0.8, hologram_alpha};
			// Draw hologram pieces (back layer)
			left_rect = left_rect->fit_aspect(task.schleem_hologram_L.aspect, .KEEP_WIDTH);
			right_rect = right_rect->fit_aspect(task.schleem_hologram_R.aspect, .KEEP_WIDTH);
			UI.quad(left_rect, task.schleem_hologram_L, hologram_tint);
			UI.quad(right_rect, task.schleem_hologram_R, hologram_tint);
			// Draw solid pieces on top as they align (front layer)
			if solid_alpha > 0.05 {
				solid_tint := v4.{1.0, 1.0, 1.0, solid_alpha};
				UI.quad(left_rect, task.schleem_piece_L, solid_tint);
				UI.quad(right_rect, task.schleem_piece_R, solid_tint);
			}
	
			// Draw the reticle/cursor
			cursor_size := 50.0;
			target_area = target_area->inset(25);
			cursor_offset :v2= .{task.reticle_position.x * target_area->width(), task.reticle_position.y * target_area->height()};
			cursor_rect := target_area->bottom_left_rect()->grow(cursor_size / 2.0)->offset_unscaled(cursor_offset.x, cursor_offset.y);
			cursor_rect = cursor_rect->fit_aspect(task.cursor_texture.aspect, .KEEP_HEIGHT);
			cursor_pulse := 1.0 + sin(get_time() * 4.0) * 0.1;
			cursor_rect = cursor_rect->scale(cursor_pulse, cursor_pulse);																			
			UI.quad(cursor_rect, task.cursor_texture, .{1, 1, 1, 0.9});
		}
	}
}

Task_Cypher :: class : Task_Base {
	// Task state
	ui_active: bool;
	rng_initialized: bool;

	code_icons: List(int);   // icon indices in correct order (len = 4)
	input_icons: List(int);  // player's current input

	success_time: float;
	fail_time: float;

	// Textures
	frame_texture: Texture_Asset;
	pass_card_texture: Texture_Asset;
	button_texture: Texture_Asset;
	button_pressed_texture: Texture_Asset;
	lights_off_texture: Texture_Asset;
	lights_on_texture: Texture_Asset;

	icon_ssundee: Texture_Asset;
	icon_sigils: Texture_Asset;
	icon_garry: Texture_Asset;
	icon_skull: Texture_Asset;
	icon_schleem: Texture_Asset;
	icon_foot: Texture_Asset;
	icon_knife: Texture_Asset;
	icon_apple: Texture_Asset;
	icon_hand: Texture_Asset;

	CODE_LEN :: 4;
	FAIL_LOCK_TIME :: 0.75;
	SUCCESS_DISPLAY_TIME :: 2.5;

	start_attempt :: proc(using this: Task_Cypher, player: Player) {
		if started {
			return;
		}
		started = true;
		// Reset any previous state (in case task is re-opened)
		input_icons = List(int).{};
		success_time = 0.0;
		fail_time = 0.0;
		ui_active = true;
	}

	init_textures :: proc(using this: Task_Cypher) {
		frame_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/keypad_frame.png");
		pass_card_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/pass_card.png");
		button_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/button_base.png");
		button_pressed_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/button_pressed_base.png");
		lights_off_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/light_red.png");
		lights_on_texture = get_asset(Texture_Asset, "sprites/tasks/cypher/light_green.png");

		icon_ssundee = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_ssundee.png");
		icon_sigils = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_sigils.png");
		icon_garry = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_garry.png");
		icon_skull = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_skull.png");
		icon_schleem = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_schleem.png");
		icon_foot = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_foot.png");
		icon_knife = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_knife.png");
		icon_apple = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_apple.png");
		icon_hand = get_asset(Texture_Asset, "sprites/tasks/cypher/icons/icon_hand.png");
	}

	get_icon_texture :: proc(using this: Task_Cypher, icon_idx: int) -> Texture_Asset {
		switch icon_idx {
			case 0: return icon_ssundee;
			case 1: return icon_sigils;
			case 2: return icon_garry;
			case 3: return icon_skull;
			case 4: return icon_schleem;
			case 5: return icon_foot;
			case 6: return icon_knife;
			case 7: return icon_apple;
			case 8: return icon_hand;
			case: return null;
		}
	}

	get_hint_text :: proc(icon_idx: int) -> string {
		switch icon_idx {
			case 0: return "Boss";
			case 1: return "Books";
			case 2: return "100 Channels";
			case 3: return "Death";
			case 4: return "All Out";
			case 5: return "Dawgs";
			case 6: return "Sharp";
			case 7: return "Juice";
			case 8: return "Wave";
			case: return "???";
		}
	}

	init_code :: proc(using this: Task_Cypher, player: Player) {
		if rng_initialized {
			return;
		}
		rng_initialized = true;

		code_icons = List(int).{};
		input_icons = List(int).{};

		// Build a pool [0..8] and pick 4 unique hints/icons in order
		available: List(int);
		for i: 0..8 {
			append(&available, i);
		}

		for i: 0..CODE_LEN-1 {
			pick := rng_range_int(&server_rng, 0, available.elements.count-1);
			val := available.elements[pick];

			last_idx := available.elements.count - 1;
			available.elements[pick] = available.elements[last_idx];
			pop(&available);

			append(&code_icons, val);
		}
	}

	is_input_prefix_correct :: proc(using this: Task_Cypher) -> bool {
		if input_icons.elements.count == 0 {
			return true;
		}
		for i: 0..input_icons.elements.count-1 {
			if input_icons.elements[i] != code_icons.elements[i] {
				return false;
			}
		}
		return true;
	}

	handle_press :: proc(using this: Task_Cypher, icon_idx: int) {
		if success_time > 0.0 {
			return;
		}
		if fail_time > 0.0 {
			if get_time() - fail_time < FAIL_LOCK_TIME {
				return;
			}
			fail_time = 0.0;
		}
		if input_icons.elements.count >= CODE_LEN {
			return;
		}

		append(&input_icons, icon_idx);

		// Wrong input -> fail flash and reset
		if !is_input_prefix_correct(this) {
			fail_time = get_time();
			input_icons = List(int).{};
			return;
		}

		// Completed and correct
		if input_icons.elements.count == CODE_LEN {
			success_time = get_time();
		}
	}

	update_task :: proc(using this: Task_Cypher, player: Player) {
		if !started {
			return;
		}
		if completed {
			return;
		}
		if !player->is_local_or_server() {
			return;
		}

		if frame_texture == null {
			init_textures(this);
		}
		init_code(this, player);

		if success_time > 0.0 {
			elapsed := get_time() - success_time;
			if elapsed >= SUCCESS_DISPLAY_TIME {
				ui_active = false;
				complete_attempt(this, player, true);
				return;
			}
			draw_cypher_ui(this, true);
			return;
		}

		draw_cypher_ui(this, false);
	}

	draw_cypher_ui :: proc(using task: Task_Cypher, success_state: bool) {
		screen := UI.get_screen_rect();
		bg_texture := get_asset(Texture_Asset, "$AO/white.png");
		UI.quad(screen, bg_texture, .{0.0, 0.0, 0.0, 0.85});

		fail_active := false;
		if task.fail_time > 0.0 {
			fail_active = (get_time() - task.fail_time) < FAIL_LOCK_TIME;
			if !fail_active {
				task.fail_time = 0.0;
			}
		}

		// Layout: keypad on left, note on right (matches reference screenshot)
		window_size := 900.0;
		keypad_rect := screen->center_rect()->grow(window_size / 2.0)->offset(-220, 0);
		keypad_rect = keypad_rect->fit_aspect(task.frame_texture.aspect, .KEEP_HEIGHT);

		// Slight shake when failing (for juice)
		if fail_active {
			shake := sin(get_time() * 40.0) * 6.0;
			keypad_rect = keypad_rect->offset(shake, 0);
		}

		UI.quad(keypad_rect, task.frame_texture, .{1, 1, 1, 1});

		note_rect := screen->center_rect()->grow(180)->offset(420, 60);
		note_rect = note_rect->fit_aspect(task.pass_card_texture.aspect, .KEEP_WIDTH);
		UI.quad(note_rect, task.pass_card_texture, .{1, 1, 1, 1});

		// Note text (the "hints")
		title_ts := UI.default_text_settings();
		title_ts.size = 64;
		title_ts.color = .{1, 1, 1, 1};
		title_ts.halign = .CENTER;
		title_ts.valign = .CENTER;
		UI.text(note_rect->cut_top(80)->offset(0, -10), title_ts, "HINTS");

		hint_ts := UI.default_text_settings();
		hint_ts.size = 48;
		hint_ts.color = .{0.5, 0.5, 0.5, 1};
		hint_ts.halign = .LEFT;
		hint_ts.valign = .CENTER;

		hints_rect := note_rect->inset_unscaled(20, 20, 20, 20);
		for i: 0..CODE_LEN-1 {
			line := hints_rect->cut_top(55);
			hint := get_hint_text(task.code_icons.elements[i]);
			UI.text(line, hint_ts, format_string("%) %", .{i+1, hint}));
		}

		// Screen text feedback area (top green display)
		display_rect := keypad_rect->inset_unscaled(keypad_rect->height() * 0.16, keypad_rect->width() * 0.15, keypad_rect->height() * 0.62, keypad_rect->width() * 0.15);
		display_ts := UI.default_text_settings();
		display_ts.size = 64;
		display_ts.halign = .LEFT;
		display_ts.valign = .CENTER;

		if success_state {
			display_ts.color = .{0.1, 0.35, 0.1, 1};
			UI.text(display_rect, display_ts, "ACCESS GRANTED");
		} else if fail_active {
			display_ts.color = .{0.7, 0.1, 0.1, 1};
			UI.text(display_rect, display_ts, "ACCESS DENIED");
		} else {
			display_ts.color = .{0.1, 0.25, 0.1, 1};
			stars := "";
			for i: 0..task.input_icons.elements.count-1 {
				stars = format_string("% *", .{stars});
			}
			display_rect->offset_unscaled(0, -10);
			display_ts.size = 128;
			UI.text(display_rect, display_ts, stars);
		}

		// Top Lights
		keypad_rect->cut_top_unscaled(keypad_rect->height() * 0.05);
		lights_rect := keypad_rect->cut_top_unscaled(keypad_rect->height() * 0.075);
		lights_rect = lights_rect->fit_aspect(task.lights_off_texture.aspect, .KEEP_HEIGHT);
		if success_state {
			UI.quad(lights_rect, task.lights_on_texture, .{1, 1, 1, 1});
		} else {
			UI.quad(lights_rect, task.lights_off_texture, .{1, 1, 1, 1});
		}

		// Keypad area (bottom blue panel) -> 3x3 icon buttons
		k_height := keypad_rect->height();
		k_width := keypad_rect->width();
		keypad_area := keypad_rect->inset_unscaled(k_height * 0.35, k_width * 0.11, k_height * 0.09, k_width * 0.11);

		// Ordering matches the icons in the hint table (indices 0..8)
		for row: 0..2 {
			for col: 0..2 {
				idx := row * 3 + col;
				cell := keypad_area->subrect(col.(f32) / 3.0, row.(f32) / 3.0, (col.(f32) + 1.0) / 3.0, (row.(f32) + 1.0) / 3.0);
				cell = cell->grow(3);

				UI.push_id("cypher_btn_%", .{idx});
				defer UI.pop_id();

				interact := UI.button(cell, .{}, .{}, "");

				// Draw base/pressed
				base_tex := task.button_texture;
				if interact.active {
					base_tex = task.button_pressed_texture;
				}
				btn_rect := cell->fit_aspect(base_tex.aspect, .KEEP_WIDTH);
				UI.quad(btn_rect, base_tex, .{1, 1, 1, 1});

				// Icon
				icon := task->get_icon_texture(idx);
				icon_rect := btn_rect->inset_unscaled(10, 10, 10, 10);
				icon_rect = icon_rect->fit_aspect(icon.aspect, .KEEP_HEIGHT);
				UI.quad(icon_rect, icon, .{1, 1, 1, 1});

				if interact.clicked && !success_state && !fail_active {
					task->handle_press(idx);
				}
			}
		}
	}
}