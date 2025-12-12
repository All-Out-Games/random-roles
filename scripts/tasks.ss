import "core:core.ss"
import "gamemanager.ss"

NUM_TASKS: int : 2;

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
	rng := rng_seed(player.entity.id);
	task_list: List(Task_Base);
	for i: 0..num_tasks-1 {
		task_to_add_index := rng_range_int(&rng, 0, NUM_TASKS-1);
		switch task_to_add_index {
			case 0:
				{
					task := new(Task_Throw_Away_Garbage);
					task.id = "throw_away_garbage";
					append(&task_list, task);
				}
			case 1:
				{
					task := new(Task_Calibrate_Teleporter);
					task.id = "calibrate_teleporter";
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
			case #unwrap_type(Task_Throw_Away_Garbage): player.active_tasks.elements[i].(Task_Throw_Away_Garbage)->update_task(player);
			case #unwrap_type(Task_Calibrate_Teleporter): player.active_tasks.elements[i].(Task_Calibrate_Teleporter)->update_task(player);
		}
	}
}

get_task_display_name :: proc(task_id: string) -> string {
	switch task_id {
		case "throw_away_garbage":
			return "Throw Away Garbage";
		case "calibrate_teleporter":
			return "Calibrate Teleporter";
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
	update_task :: proc(using this: Task_Calibrate_Teleporter, player: Player) {
		if !started {
			return;
		}
		//Instant success
		complete_attempt(this, player, true);
	}
}