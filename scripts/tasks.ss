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

draw_signal_sync_bar :: proc(
	rect: Rect,
	fill01: float,
	bar_bg: Texture_Asset,
	bar_fill: Texture_Asset,
	bar_frame: Texture_Asset,
	bar_complete: Texture_Asset,
	name_tex: Texture_Asset,
	complete_name_tex: Texture_Asset
) {
	fill01 = clamp(fill01, 0.0, 1.0);

	if fill01 >= 1.0 {
		UI.quad(rect, bar_complete, .{1, 1, 1, 1});
		name_rect := rect->inset_unscaled(rect->height() * 0.10, rect->width() * 0.55, rect->height() * 0.10, rect->width() * 0.02);
		name_rect = name_rect->fit_aspect(complete_name_tex.aspect, .KEEP_HEIGHT);
		UI.quad(name_rect, complete_name_tex, .{1, 1, 1, 1});
		return;
	}

	UI.quad(rect, bar_bg, .{1, 1, 1, 1});

	inner := rect->inset_unscaled(rect->height() * 0.20, rect->width() * 0.08, rect->height() * 0.20, rect->width() * 0.53);
	fill_rect := inner->subrect(0.0, 0.0, fill01, 1.0);
	UI.quad(fill_rect, bar_fill, .{1, 1, 1, 1});

	UI.quad(rect, bar_frame, .{1, 1, 1, 1});

	name_rect := rect->inset_unscaled(rect->height() * 0.10, rect->width() * 0.55, rect->height() * 0.10, rect->width() * 0.02);
	name_rect = name_rect->fit_aspect(name_tex.aspect, .KEEP_HEIGHT);
	UI.quad(name_rect, name_tex, .{1, 1, 1, 1});
}

Task_Signal_Sync :: class : Task_Base {
	// Task state
	ui_active: bool;

	beam_tip_pos: v2; // normalized (0..1) within window
	beam_dir: v2;     // normalized direction (mouse controls direction only)
	beam_len_current: float; // current rendered beam length (pixels), eased toward target

	sat_a_fill: float;
	sat_b_fill: float;
	sat_c_fill: float;

	success_time: float;
	last_update_time: float;

	// Textures
	backing_texture: Texture_Asset;

	satellite_tower_texture: Texture_Asset;
	satellite_dish_texture: Texture_Asset;

	sat_texture: Texture_Asset;
	sat_updating_texture: Texture_Asset;
	sat_updated_texture: Texture_Asset;

	bar_bg_texture: Texture_Asset;
	bar_fill_texture: Texture_Asset;
	bar_frame_texture: Texture_Asset;
	bar_complete_texture: Texture_Asset;

	name_a_texture: Texture_Asset;
	name_b_texture: Texture_Asset;
	name_c_texture: Texture_Asset;
	complete_name_a_texture: Texture_Asset;
	complete_name_b_texture: Texture_Asset;
	complete_name_c_texture: Texture_Asset;

	beam_start_texture: Texture_Asset;
	beam_end_texture: Texture_Asset;
	beam_info_texture: Texture_Asset;
	beam_boost_texture: Texture_Asset;

	SUCCESS_DISPLAY_TIME :: 2.5;
	FILL_RATE :: 0.45; // bar fill per second while locked on

	start_attempt :: proc(using this: Task_Signal_Sync, player: Player) {
		if started {
			return;
		}
		started = true;
		ui_active = true;

		beam_tip_pos = .{0.65, 0.55};
		beam_dir = normalize(v2.{1.0, 0.35});
		beam_len_current = 0.0;
		sat_a_fill = 0.0;
		sat_b_fill = 0.0;
		sat_c_fill = 0.0;
		success_time = 0.0;
		last_update_time = 0.0;
	}

	init_textures :: proc(using this: Task_Signal_Sync) {
		backing_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/backing_night.png");
		satellite_tower_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/satellite_tower.png");
		satellite_dish_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/satellite_dish.png");

		sat_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/satellites/satellite.png");
		sat_updating_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/satellites/satellite_updating.png");
		sat_updated_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/satellites/satellite_updated.png");

		bar_bg_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/bar_background.png");
		bar_fill_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/bar.png");
		bar_frame_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/bar_frame.png");
		bar_complete_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/bar_complete.png");

		name_a_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/name_A.png");
		name_b_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/name_B.png");
		name_c_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/name_C.png");
		complete_name_a_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/complete_name_A.png");
		complete_name_b_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/complete_name_B.png");
		complete_name_c_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/bar/complete_name_C.png");

		beam_start_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/beam/beam_start.png");
		beam_end_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/beam/beam_end.png");
		beam_info_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/beam/information_beam.png");
		beam_boost_texture = get_asset(Texture_Asset, "sprites/tasks/signal_sync/beam/information_boost.png");
	}

	update_task :: proc(using this: Task_Signal_Sync, player: Player) {
		if !started {
			return;
		}
		if completed {
			return;
		}
		if !player->is_local_or_server() {
			return;
		}

		if backing_texture == null {
			init_textures(this);
		}

		now := get_time();
		dt := 0.0;
		if last_update_time > 0.0 {
			dt = now - last_update_time;
			dt = clamp(dt, 0.0, 0.05);
		}
		last_update_time = now;

		if success_time > 0.0 {
			if now - success_time >= SUCCESS_DISPLAY_TIME {
				ui_active = false;
				complete_attempt(this, player, true);
				return;
			}
			draw_signal_sync_ui(this, true, 0.0);
			return;
		}

		draw_signal_sync_ui(this, false, dt);
	}

	rotate_about_point :: proc(point: v2, degrees: float) -> Matrix4 {
		return Matrix4.translate(point)->multiply(Matrix4.rotate(degrees, v3.{0.0, 0.0, 1.0})->multiply(Matrix4.translate(-point)));
	}

	rotate_point_about_pivot :: proc(using task: Task_Signal_Sync, point: v2, radians: float, pivot: v2) -> v2 {
		p := point - pivot;
		c := cos(radians);
		s := sin(radians);
		return pivot + v2.{p.x * c - p.y * s, p.x * s + p.y * c};
	}

	// Returns distance along ray (origin + dir * t) until it hits the given axis-aligned rect bounds.
	// Assumes dir is normalized; returns 0.0 if no valid hit.
	ray_rect_distance :: proc(using task: Task_Signal_Sync, origin: v2, dir: v2, rect: Rect) -> float {
		best := 999999.0;
		eps := 0.00001;

		// Hit vertical sides (x = min.x / max.x)
		if abs(dir.x) > eps {
			t1 := (rect.min.x - origin.x) / dir.x;
			if t1 > 0.0 {
				p := origin + dir * t1;
				if p.y >= rect.min.y && p.y <= rect.max.y {
					best = min(best, t1);
				}
			}
			t2 := (rect.max.x - origin.x) / dir.x;
			if t2 > 0.0 {
				p := origin + dir * t2;
				if p.y >= rect.min.y && p.y <= rect.max.y {
					best = min(best, t2);
				}
			}
		}

		// Hit horizontal sides (y = min.y / max.y)
		if abs(dir.y) > eps {
			t3 := (rect.min.y - origin.y) / dir.y;
			if t3 > 0.0 {
				p := origin + dir * t3;
				if p.x >= rect.min.x && p.x <= rect.max.x {
					best = min(best, t3);
				}
			}
			t4 := (rect.max.y - origin.y) / dir.y;
			if t4 > 0.0 {
				p := origin + dir * t4;
				if p.x >= rect.min.x && p.x <= rect.max.x {
					best = min(best, t4);
				}
			}
		}

		if best >= 999998.0 {
			return 0.0;
		}
		return best;
	}

	draw_signal_sync_ui :: proc(using task: Task_Signal_Sync, success_state: bool, delta_time: float) {
		screen := UI.get_screen_rect();
		bg_texture := get_asset(Texture_Asset, "$AO/white.png");
		UI.quad(screen, bg_texture, .{0.0, 0.0, 0.0, 0.85});

		window_size := 1000.0;
		window_rect := screen->center_rect()->grow(window_size / 2.0);
		window_rect = window_rect->fit_aspect(task.backing_texture.aspect, .KEEP_HEIGHT);
		UI.quad(window_rect, task.backing_texture, .{1, 1, 1, 1});

		w := window_rect->width();
		h := window_rect->height();

		// Tower + dish (emitter)
		tower_local := v2.{w * 0.173, h * 0.18};
		tower_rect := window_rect->bottom_left_rect()->offset_unscaled(tower_local.x, tower_local.y);
		tower_rect = tower_rect->grow_unscaled(h * 0.18, w * 0.17, h * 0.18, w * 0.17);
		tower_rect = tower_rect->fit_aspect(task.satellite_tower_texture.aspect, .KEEP_HEIGHT);

		dish_rect := tower_rect->top_right_rect()->grow_unscaled(h * 0.17, w * 0.17, h * 0.17, w * 0.17);
		dish_rect = dish_rect->offset_unscaled(-w * 0.02, -h * 0.05);
		dish_rect = dish_rect->fit_aspect(task.satellite_dish_texture.aspect, .KEEP_HEIGHT);

		// Dish pivot for rotation/aim (middle-left)
		dish_pivot := v2.{dish_rect.min.x, dish_rect.min.y + dish_rect->height() * 0.5};
		emitter_pos := v2.{dish_rect.max.x, dish_rect.min.y + dish_rect->height() * 0.5};

		// Satellites (approx layout matching reference)
		sat_size := h * 0.2;
		sat_a_local := v2.{w * 0.25, h * 0.80};
		sat_b_local := v2.{w * 0.76, h * 0.74};
		sat_c_local := v2.{w * 0.80, h * 0.30};

		sat_a_rect := window_rect->bottom_left_rect()->offset_unscaled(sat_a_local.x, sat_a_local.y);
		sat_a_rect = sat_a_rect->grow_unscaled(sat_size / 2.0, sat_size / 2.0, sat_size / 2.0, sat_size / 2.0);
		sat_b_rect := window_rect->bottom_left_rect()->offset_unscaled(sat_b_local.x, sat_b_local.y);
		sat_b_rect = sat_b_rect->grow_unscaled(sat_size / 2.0, sat_size / 2.0, sat_size / 2.0, sat_size / 2.0);
		sat_c_rect := window_rect->bottom_left_rect()->offset_unscaled(sat_c_local.x, sat_c_local.y);
		sat_c_rect = sat_c_rect->grow_unscaled(sat_size / 2.0, sat_size / 2.0, sat_size / 2.0, sat_size / 2.0);

		sat_a_rect = sat_a_rect->fit_aspect(task.sat_texture.aspect, .KEEP_HEIGHT);
		sat_b_rect = sat_b_rect->fit_aspect(task.sat_texture.aspect, .KEEP_HEIGHT);
		sat_c_rect = sat_c_rect->fit_aspect(task.sat_texture.aspect, .KEEP_HEIGHT);

		sat_a_center := v2.{(sat_a_rect.min.x + sat_a_rect.max.x) * 0.5, (sat_a_rect.min.y + sat_a_rect.max.y) * 0.5};
		sat_b_center := v2.{(sat_b_rect.min.x + sat_b_rect.max.x) * 0.5, (sat_b_rect.min.y + sat_b_rect.max.y) * 0.5};
		sat_c_center := v2.{(sat_c_rect.min.x + sat_c_rect.max.x) * 0.5, (sat_c_rect.min.y + sat_c_rect.max.y) * 0.5};

		// Completion flags (used for target selection + fill gating)
		a_done := task.sat_a_fill >= 1.0;
		b_done := task.sat_b_fill >= 1.0;
		c_done := task.sat_c_fill >= 1.0;

		// Beam aim control (drag anywhere on the window): mouse sets direction, not distance
		if !success_state {
			UI.push_id("signal_sync_drag");
			defer UI.pop_id();
			interact := UI.button(window_rect, .{}, .{}, "");
			if interact.active {
				// Aim relative to the ROTATION PIVOT (the dish is rotated about this point).
				// This keeps input, rendered beam, and hit-testing in the same coordinate space.
				aim_vec := interact.mouse_position - dish_pivot;
				if length(aim_vec) > 1.0 {
					task.beam_dir = normalize(aim_vec);
				}
			}
		}

		// Dish angle (radians for math, degrees for UI)
		angle_rad := atan2(task.beam_dir.y, task.beam_dir.x);
		dish_angle := to_degrees(angle_rad);

		// IMPORTANT: the beam is rendered under a rotation matrix around dish_pivot, so its true world-space
		// origin is the rotated emitter position (not the unrotated emitter_pos).
		emitter_world := task->rotate_point_about_pivot(emitter_pos, angle_rad, dish_pivot);

		// Default beam length: distance until the ray hits the window bounds.
		// (Old code used min distance to ANY edge, which capped the beam to the nearest edge behind/aside the emitter,
		// preventing it from ever reaching satellites.)
		default_len := task->ray_rect_distance(emitter_world, task.beam_dir, window_rect);
		default_len = default_len - h * 0.03;
		if default_len < 50.0 { default_len = 50.0; }

		// Find the "nearest satellite along the current ray" in WORLD space.
		// This avoids subtle mismatch between the visual ray and the math used for lock-on.
		dir := task.beam_dir; // normalized
		max_t := default_len; // ray length within window bounds

		best_lateral := 999999.0;
		target_id := 0; // 0 none, 1 A, 2 B, 3 C
		target_forward := default_len;

		// Helper-ish pattern: compute forward (projection onto ray) + lateral (perp distance to ray)
		rel_a := sat_a_center - emitter_world;
		a_forward := rel_a.x * dir.x + rel_a.y * dir.y;
		a_lateral := length(rel_a - dir * a_forward);
		if !a_done && a_forward > 0.0 && a_forward <= max_t && a_lateral < best_lateral {
			best_lateral = a_lateral;
			target_id = 1;
			target_forward = a_forward;
		}

		rel_b := sat_b_center - emitter_world;
		b_forward := rel_b.x * dir.x + rel_b.y * dir.y;
		b_lateral := length(rel_b - dir * b_forward);
		if !b_done && b_forward > 0.0 && b_forward <= max_t && b_lateral < best_lateral {
			best_lateral = b_lateral;
			target_id = 2;
			target_forward = b_forward;
		}

		rel_c := sat_c_center - emitter_world;
		c_forward := rel_c.x * dir.x + rel_c.y * dir.y;
		c_lateral := length(rel_c - dir * c_forward);
		if !c_done && c_forward > 0.0 && c_forward <= max_t && c_lateral < best_lateral {
			best_lateral = c_lateral;
			target_id = 3;
			target_forward = c_forward;
		}

		// Beam length behavior:
		// - When NOT aiming near a satellite, keep a stable "idle" length to the window boundary.
		// - When aiming near one, smoothly scale down to that satellite distance.
		acquire_threshold := sat_size * 0.55;
		aim01 := 0.0;
		if target_id != 0 && best_lateral <= acquire_threshold {
			aim01 = clamp((acquire_threshold - best_lateral) / acquire_threshold, 0.0, 1.0);
		}

		idle_len := default_len;
		desired_len := idle_len;
		if target_id != 0 {
			desired_len = idle_len * (1.0 - aim01) + clamp(target_forward, 50.0, idle_len) * aim01;
		}

		if task.beam_len_current <= 0.0 {
			task.beam_len_current = desired_len;
		} else {
			// Smooth step toward desired length
			max_delta := 4000.0 * delta_time;
			diff := desired_len - task.beam_len_current;
			step := clamp(diff, -max_delta, max_delta);
			task.beam_len_current = task.beam_len_current + step;
		}

		// Lock-on checks: require the ray to pass close to the satellite (in local space) and the length to match.
		lateral_threshold := sat_size * 0.35;
		len_tolerance := sat_size * 0.30;
		lock_ok := (target_id != 0) && (best_lateral <= lateral_threshold) && (abs(task.beam_len_current - target_forward) <= len_tolerance);

		a_lock := (!a_done) && lock_ok && target_id == 1;
		b_lock := (!b_done) && lock_ok && target_id == 2;
		c_lock := (!c_done) && lock_ok && target_id == 3;

		if !success_state {
			if a_lock { task.sat_a_fill = clamp(task.sat_a_fill + delta_time * FILL_RATE, 0.0, 1.0); }
			if b_lock { task.sat_b_fill = clamp(task.sat_b_fill + delta_time * FILL_RATE, 0.0, 1.0); }
			if c_lock { task.sat_c_fill = clamp(task.sat_c_fill + delta_time * FILL_RATE, 0.0, 1.0); }
		}

		// Draw satellites (stateful sprite)
		sat_a_sprite := task.sat_texture;
		sat_b_sprite := task.sat_texture;
		sat_c_sprite := task.sat_texture;
		if a_done { sat_a_sprite = task.sat_updated_texture; } else if a_lock { sat_a_sprite = task.sat_updating_texture; }
		if b_done { sat_b_sprite = task.sat_updated_texture; } else if b_lock { sat_b_sprite = task.sat_updating_texture; }
		if c_done { sat_c_sprite = task.sat_updated_texture; } else if c_lock { sat_c_sprite = task.sat_updating_texture; }

		UI.quad(sat_a_rect, sat_a_sprite, .{1, 1, 1, 1});
		UI.quad(sat_b_rect, sat_b_sprite, .{1, 1, 1, 1});
		UI.quad(sat_c_rect, sat_c_sprite, .{1, 1, 1, 1});

		// Bars + labels
		bar_w := w * 0.34;

		bar_a_center := v2.{window_rect.min.x + w * 0.23, window_rect.min.y + h * 0.93};
		bar_a_rect := window_rect->bottom_left_rect()->offset_unscaled(bar_a_center.x - window_rect.min.x, bar_a_center.y - window_rect.min.y)->grow_unscaled(bar_w / 2.0, bar_w / 2.0, bar_w / 2.0, bar_w / 2.0);
		bar_a_rect = bar_a_rect->fit_aspect(task.bar_frame_texture.aspect, .KEEP_WIDTH);

		bar_b_center := v2.{window_rect.min.x + w * 0.76, window_rect.min.y + h * 0.86};
		bar_b_rect := window_rect->bottom_left_rect()->offset_unscaled(bar_b_center.x - window_rect.min.x, bar_b_center.y - window_rect.min.y)->grow_unscaled(bar_w / 2.0, bar_w / 2.0, bar_w / 2.0, bar_w / 2.0);
		bar_b_rect = bar_b_rect->fit_aspect(task.bar_frame_texture.aspect, .KEEP_WIDTH);

		bar_c_center := v2.{window_rect.min.x + w * 0.73, window_rect.min.y + h * 0.44};
		bar_c_rect := window_rect->bottom_left_rect()->offset_unscaled(bar_c_center.x - window_rect.min.x, bar_c_center.y - window_rect.min.y)->grow_unscaled(bar_w / 2.0, bar_w / 2.0, bar_w / 2.0, bar_w / 2.0);
		bar_c_rect = bar_c_rect->fit_aspect(task.bar_frame_texture.aspect, .KEEP_WIDTH);

		draw_signal_sync_bar(bar_a_rect, task.sat_a_fill, task.bar_bg_texture, task.bar_fill_texture, task.bar_frame_texture, task.bar_complete_texture, task.name_a_texture, task.complete_name_a_texture);
		draw_signal_sync_bar(bar_b_rect, task.sat_b_fill, task.bar_bg_texture, task.bar_fill_texture, task.bar_frame_texture, task.bar_complete_texture, task.name_b_texture, task.complete_name_b_texture);
		draw_signal_sync_bar(bar_c_rect, task.sat_c_fill, task.bar_bg_texture, task.bar_fill_texture, task.bar_frame_texture, task.bar_complete_texture, task.name_c_texture, task.complete_name_c_texture);

		// Rotate the dish towards the current aim direction (pivot: middle-left)
		// Draw the ray INSIDE this rotation scope so it inherits rotation automatically.
		UI.push_matrix(rotate_about_point(dish_pivot, dish_angle));
		{
			beam_distance := task.beam_len_current;
			if beam_distance > 1.0 {
				connected := lock_ok;

				// Start glow at emitter always
				start_size := h * 0.05;
				if connected {
					start_size = h * 0.15;
				}
				start_rect := window_rect->bottom_left_rect()->offset_unscaled(emitter_pos.x - window_rect.min.x, emitter_pos.y - window_rect.min.y);
				start_rect = start_rect->grow_unscaled(start_size / 2.0, start_size / 2.0, start_size / 2.0, start_size / 2.0);
				start_rect = start_rect->fit_aspect(task.beam_start_texture.aspect, .KEEP_HEIGHT);
				UI.quad(start_rect, task.beam_start_texture, .{1, 1, 1, 0.9});

				if !connected {
					// FREE AIM (dotted look)
					step := h * 0.04;
					count := (beam_distance / step).(int);
					if count < 6 { count = 6; }
					if count > 40 { count = 40; }

					for i: 0..count {
						t := (i.(float)) / (count.(float));
						px := emitter_pos.x + beam_distance * t;
						py := emitter_pos.y;

						alpha := 0.25 + (sin(get_time() * 10.0 + i.(float) * 0.5) * 0.25);
						alpha = clamp(alpha, 0.15, 0.65);

						seg_size := h * 0.02;
						seg_rect := window_rect->bottom_left_rect()->offset_unscaled(px - window_rect.min.x, py - window_rect.min.y)->grow(seg_size / 2.0);
						UI.quad(seg_rect, task.beam_end_texture, .{0.8, 1.0, 0.6, alpha});
					}

					tip_pulse := 1.0 + sin(get_time() * 7.0) * 0.08;
					tip_rect := window_rect->bottom_left_rect()->offset_unscaled((emitter_pos.x + beam_distance) - window_rect.min.x, emitter_pos.y - window_rect.min.y)->grow(h * 0.05 * tip_pulse);
					tip_rect = tip_rect->fit_aspect(task.beam_start_texture.aspect, .KEEP_HEIGHT);
					UI.quad(tip_rect, task.beam_start_texture, .{1, 1, 1, 0.85});
				} else {
					// CONNECTED BEAM (continuous): stretch one beam quad from start to end.
					if target_id != 0 {
						beam_distance = clamp(target_forward, 0.0, beam_distance);
					}

					beam_thickness := h * 0.045;
					x0 := clamp((emitter_pos.x - window_rect.min.x) / w, 0.0, 1.0);
					x1 := clamp((emitter_pos.x + beam_distance - window_rect.min.x) / w, 0.0, 1.0);
					y_center := clamp((emitter_pos.y - window_rect.min.y) / h, 0.0, 1.0);
					y0 := clamp(y_center - (beam_thickness * 0.5) / h, 0.0, 1.0);
					y1 := clamp(y_center + (beam_thickness * 0.5) / h, 0.0, 1.0);

					beam_rect := window_rect->subrect(x0, y0, x1, y1);
					pulse := 0.90 + sin(get_time() * 10.0) * 0.05;
					UI.quad(beam_rect, task.beam_info_texture, .{1, 1, 1, 0.85 * pulse});
					
					ring_step := h * 0.08;
					ring_count := (beam_distance / ring_step).(int);
					if ring_count < 2 { ring_count = 2; }
					if ring_count > 10 { ring_count = 10; }
					for i: 1..ring_count-1 {
						t := (i.(float)) / (ring_count.(float));
						px := emitter_pos.x + beam_distance * t;
						py := emitter_pos.y;

						ring_size := h * (0.1 - (0.05 * t));
						ring_rect := window_rect->bottom_left_rect()->offset_unscaled(px - window_rect.min.x, py - window_rect.min.y)->grow_unscaled(ring_size / 2.0, ring_size / 2.0, ring_size / 2.0, ring_size / 2.0);
						ring_rect = ring_rect->fit_aspect(task.beam_boost_texture.aspect, .KEEP_WIDTH);
						UI.quad(ring_rect, task.beam_boost_texture, .{1, 1, 1, 0.85});
					}

					// End cap at tip
					end_pulse := 1.0 + sin(get_time() * 7.0) * 0.06;
					end_rect := window_rect->bottom_left_rect()->offset_unscaled((emitter_pos.x + beam_distance) - window_rect.min.x, emitter_pos.y - window_rect.min.y)->grow(h * 0.05 * end_pulse);
					end_rect = end_rect->fit_aspect(task.beam_end_texture.aspect, .KEEP_HEIGHT);
					UI.quad(end_rect, task.beam_end_texture, .{1, 1, 1, 0.95});
				}
			}

			// Dish on top of the ray
			UI.quad(dish_rect, task.satellite_dish_texture, .{1, 1, 1, 1});
		}
		UI.pop_matrix();
		UI.quad(tower_rect, task.satellite_tower_texture, .{1, 1, 1, 1});
		
		if !success_state {
			if task.sat_a_fill >= 1.0 && task.sat_b_fill >= 1.0 && task.sat_c_fill >= 1.0 {
				task.success_time = get_time();
			}
		}

		if success_state {
			success_rect := window_rect->cut_top(60)->offset(0, 10);
			success_ts := UI.default_text_settings();
			success_ts.size = 54;
			success_ts.color = .{0.3, 1.0, 0.4, 1.0};
			success_ts.halign = .CENTER;
			success_ts.valign = .CENTER;
			UI.text(success_rect, success_ts, "SIGNALS SYNCHRONIZED!");
		}
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