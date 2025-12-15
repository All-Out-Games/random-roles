import "core:core.ss"
import "gamemanager.ss"

NUM_TASKS: int : 3;

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
	for i: 0..num_tasks-1 {
		rng := rng_seed(player.entity.id+i.(u64));
		task_to_add_index := rng_range_int(&rng, 0, NUM_TASKS-1);
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
			return "Cypher";
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

Task_Calibrate_Teleporter :: class : Task_Base {
	// Task state
	ui_active: bool;
	reticle_position: v2;  // Normalized position within targeting area (0-1 range)
	target_position: v2;   // The random target spot to find (0-1 range)
	rng_initialized: bool;
	is_touching: bool;
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
		window_texture = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/window.png");
		cursor_texture = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/cursor.png");
		schleem_hologram_L = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/schleem_hologram_piece_L.png");
		schleem_hologram_R = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/schleem_hologram_piece_R.png");
		schleem_piece_L = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/schleem_piece_L.png");
		schleem_piece_R = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/schleem_piece_R.png");
		schleem_alive = get_asset(Texture_Asset, "sprites/Calibrate Teleporter/schleem_ alive.png");
	}
	
	init_target :: proc(using this: Task_Calibrate_Teleporter, player: Player) {
		if rng_initialized {
			return;
		}
		rng_initialized = true;
		rng := rng_seed(player.entity.id + 12345);
		target_position.x = rng_range_float(&rng, 0.2, 0.8);
		target_position.y = rng_range_float(&rng, 0.2, 0.8);
		reticle_position = .{0.5, 0.5};
	}

	update_task :: proc(using this: Task_Calibrate_Teleporter, player: Player) {
		if !started {
			return;
		}
		if completed {
			return;
		}
		
		// Only render UI on local client
		if !player->is_local_or_server() {
			return;
		}
		
		// Initialize textures and target if needed
		if window_texture == null {
			init_textures(this);
		}
		init_target(this, player);
		
		// Start UI if not active yet
		if !ui_active {
			ui_active = true;
		}
		
		// Check if we already succeeded and waiting to close
		if success_time > 0.0 {
			elapsed := get_time() - success_time;
			if elapsed >= SUCCESS_DISPLAY_TIME {
				ui_active = false;
				complete_attempt(this, player, true);
				return;
			}
			// Draw success state UI
			draw_calibrate_ui(this, player, true);
			return;
		}
		
		// Draw the main calibration UI
		draw_calibrate_ui(this, player, false);
	}
}

draw_calibrate_ui :: proc(using task: Task_Calibrate_Teleporter, player: Player, success_state: bool) {
	screen := UI.get_screen_rect();
	
	// Dark overlay behind everything
	bg_texture := get_asset(Texture_Asset, "$AO/white.png");
	UI.quad(screen, bg_texture, .{0.0, 0.0, 0.0, 0.85});
	
	// Window in center - make it appropriately sized
	window_size := 800.0;
	window_rect := screen->center_rect()->grow(window_size / 2.0);
	window_rect = window_rect->fit_aspect(task.window_texture.aspect, .KEEP_HEIGHT);
	UI.quad(window_rect, task.window_texture, .{1, 1, 1, 1});
	
	// The targeting area - a rectangle toward the bottom of the window
	// Inset from window edges and positioned lower
	target_area := window_rect->inset_unscaled(window_rect->height() * 0.57, window_rect->width() * 0.242, window_rect->height() * 0.0365, window_rect->width() * 0.242);
	schleem_rect := window_rect->center_rect()->grow(150)->offset(0, 220);
	
	// Draw target area background
	//UI.quad(target_area, bg_texture, .{1, 0, 0, 0.6});
	
	if success_state {
		// SUCCESS STATE - Show alive schleem with thumbs up
		schleem_rect = schleem_rect->fit_aspect(task.schleem_alive.aspect, .KEEP_WIDTH);
		
		// Pulse animation
		pulse := 1.0 + sin(get_time() * 8.0) * 0.05;
		schleem_rect = schleem_rect->scale(pulse, pulse);
		
		UI.quad(schleem_rect, task.schleem_alive, .{1, 1, 1, 1});
		
		// Success text
		success_rect := window_rect->cut_top(50)->offset(0, 20);
		success_ts := UI.default_text_settings();
		success_ts.size = 42;
		success_ts.color = .{0.3, 1.0, 0.4, 1.0};
		success_ts.halign = .CENTER;
		success_ts.valign = .CENTER;
		UI.text(success_rect, success_ts, "TELEPORTATION COMPLETE!");
	} else {
		// CALIBRATION STATE - Handle input and draw hologram pieces
		
		// Create invisible button over targeting area for touch detection
		UI.push_id("calibrate_target_area");
		defer UI.pop_id();
		
		interact := UI.button(target_area, .{}, .{}, "");
		
		if interact.active {
			task.is_touching = true;
			
			// Calculate relative position within target area
			input_area_size := target_area.max - target_area.min;
			
			if input_area_size.x > 0.0 && input_area_size.y > 0.0 {
				rel_x := (interact.mouse_position.x - target_area.min.x) / input_area_size.x;
				rel_y := (interact.mouse_position.y - target_area.min.y) / input_area_size.y;
				task.reticle_position.x = clamp(rel_x, 0.0, 1.0);
				task.reticle_position.y = clamp(rel_y, 0.0, 1.0);
			}
		} else {
			task.is_touching = false;
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
		
		// Left hologram piece - offset left from center
		left_rect := schleem_rect->offset(-split_amount*5, 0);
		
		// Right hologram piece - offset right from center  
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
		
		// Pulse effect for cursor
		cursor_pulse := 1.0 + sin(get_time() * 4.0) * 0.1;
		cursor_rect = cursor_rect->scale(cursor_pulse, cursor_pulse);																			
		
		UI.quad(cursor_rect, task.cursor_texture, .{1, 1, 1, 0.9});
	}
}

Task_Cypher :: class : Task_Base {
	update_task :: proc(using this: Task_Cypher, player: Player) {
		if !started {																														
			return;
		}
		//Instant success
		complete_attempt(this, player, true);
	}
}