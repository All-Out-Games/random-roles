import "core:core.ss"
import "player.ss"

MIN_NUMBER_OF_PLAYERS: int : 4;

Game_State :: enum {
    LOBBY;
	INGAME;
	VOTING;
}

Player_Type :: enum {
    CIVILIAN;
	ANARCHIST;
	TRAITOR;
}

Player_State :: enum {
    PASSIVE;
	ALIVE;
	DEAD;
}

Player_Role :: enum {
    NONE;
	//Civilian Roles
	SHERIFF;
}

game_state: Game_State;
countdown_start_time: float;
countdown_active: bool;
game_end_time: float;
waiting_for_restart: bool;
voting_start_time: float;
round_number: int;

on_player_go_dead :: proc(player: Player) {
	player.player_state = Player_State.DEAD;
	player->add_ghost_reason("spectator");
	player->Notify("You are dead!");
}

on_player_go_passive :: proc(player: Player) {
	player->revive();
	player.player_state = Player_State.PASSIVE;
	world_references->teleport_near_lobby(player);
	player->remove_ghost_reason("spectator");
}

on_player_go_alive :: proc(player: Player) {
	player->revive();
	player.player_state = Player_State.ALIVE;
	player->remove_ghost_reason("spectator");
}

close_all_doors :: proc() {
	foreach door: component_iterator(Door) {
		door->close_door();
	}
}

open_all_doors :: proc() {
	foreach door: component_iterator(Door) {
		door->open_door();
	}
}

setup_lobby :: proc() {
	game_state = Game_State.LOBBY;
	countdown_active = false;
	countdown_start_time = 0.0;
	game_end_time = 0.0;
	waiting_for_restart = false;
	close_all_doors();
	foreach player: component_iterator(Player) {
		on_player_go_passive(player);
	}
	foreach corpse: component_iterator(Corpse) {
		destroy_entity(corpse.entity);
	}
}

setup_ingame :: proc() {
	game_state = Game_State.INGAME;
	countdown_active = false;
	countdown_start_time = 0.0;
	game_end_time = 0.0;
	waiting_for_restart = false;
	voting_start_time = 0.0;
	open_all_doors();
}

setup_voting :: proc() {
	game_state = Game_State.VOTING;
	voting_start_time = get_time();
	close_all_doors();
	
	// Reset all votes
	for i: 0..players.elements.count-1 {
		players.elements[i].voted_for = null;
		players.elements[i].votes_received = 0;
	}
	
	// Teleport all alive players to voting area
	for i: 0..players.elements.count-1 {
		if players.elements[i].player_state == Player_State.ALIVE {
			world_references->teleport_to_voting(players.elements[i]);
		}
	}
	
	// Notify all players
	for i: 0..players.elements.count-1 {
		players.elements[i]->Notify("A body has been reported! Meeting in progress.");
	}
}

cast_vote :: proc(voter: Player, target: Player) {
	if voter.voted_for != null {
		// Already voted, can't change vote
		return;
	}
	if voter.player_state != Player_State.ALIVE || target.player_state != Player_State.ALIVE {
		return;
	}
	if game_state != Game_State.VOTING {
		return;
	}
	
	voter.voted_for = target;
	target.votes_received += 1;
	
	voter->Notify(format_string("You voted for %", .{target.entity->get_name()}));
}

start_meeting :: proc() {
	if game_state == Game_State.INGAME {
		setup_voting();
	}
}

ao_start :: proc() {
	setup_lobby();
  }

ao_update :: proc(dt: float) {
	if(game_state == Game_State.LOBBY) {
		ao_update_lobby(dt);
	} else if(game_state == Game_State.INGAME) {
		ao_update_ingame(dt);
	} else if(game_state == Game_State.VOTING) {
		ao_update_voting(dt);
	}
  }

get_alive_player_count :: proc() -> int {
	alive_count := 0;
	for i: 0..players.elements.count-1 {
		if players.elements[i].player_state == Player_State.ALIVE {
			alive_count += 1;
		}
	}
	return alive_count;
}

get_player_count :: proc(type: Player_Type) -> int {
	count := 0;
	for i: 0..players.elements.count-1 {
		if players.elements[i].player_state == Player_State.ALIVE && players.elements[i].player_type == type {
			count += 1;
		}
	}
	return count;
}

end_game_with_victor :: proc(victor: Player_Type) {
	// Notify everyone about the victor
	victor_message := format_string("Victory! % wins the round!", .{victor});
	for i: 0..players.elements.count-1 {
		players.elements[i]->Notify(victor_message);
	}
	
	// Set all players to passive
	for i: 0..players.elements.count-1 {
		players.elements[i].player_state = Player_State.PASSIVE;
	}

	round_number += 1;
	
	// Return to lobby and start wait timer
	setup_lobby();
}

ao_update_lobby :: proc(dt: float) {
	current_time := get_time();
	player_count := players.elements.count;
	
	// Check if we're waiting for restart timer (1 minute)
	if waiting_for_restart {
		elapsed := current_time - game_end_time;
		if elapsed >= 60.0 {
			waiting_for_restart = false;
			game_end_time = 0.0;
		} else {
			// Display wait timer
			remaining := 60.0 - elapsed;
			wait_text := format_string("Next round in: %{.2} seconds", .{remaining});
			
			screen := UI.get_safe_screen_rect();
			rect := screen->subrect(0.5, 0.5, 0.5, 0.5, -150, -25, -150, -25);
			
			ts := UI.default_text_settings();
			ts.size = 48;
			ts.color = .{1, 1, 1, 1};
			ts.halign = .CENTER;
			ts.valign = .CENTER;
			
			UI.text(rect, ts, wait_text);
			return;
		}
	}
	
	if player_count >= MIN_NUMBER_OF_PLAYERS {
		// Start or continue countdown
		if !countdown_active {
			countdown_active = true;
			countdown_start_time = current_time;
		}
		
		// Check if countdown has completed (10 seconds)
		elapsed := current_time - countdown_start_time;
		if elapsed >= 10.0 {
			// Start the game
			assign_players_to_types();
			setup_ingame();
		} else {
			// Display countdown on screen
			remaining := 10.0 - elapsed;
			countdown_text := format_string("Game starting in: %{.2}", .{remaining});
			
			screen := UI.get_safe_screen_rect();
			rect := screen->subrect(0.5, 0.5, 0.5, 0.5, -100, -25, -100, -25);
			
			ts := UI.default_text_settings();
			ts.size = 48;
			ts.color = .{1, 1, 1, 1};
			ts.halign = .CENTER;
			ts.valign = .CENTER;
			
			UI.text(rect, ts, countdown_text);
		}
	} else {
		// Player count dropped below threshold, reset countdown
		if countdown_active {
			countdown_active = false;
			countdown_start_time = 0.0;
		}
	}
}

ao_update_ingame :: proc(dt: float) {
	alive_count := get_alive_player_count();
	civilian_count := get_player_count(Player_Type.CIVILIAN);
	traitor_count := get_player_count(Player_Type.TRAITOR);
	anarchist_count := get_player_count(Player_Type.ANARCHIST);

	//Win Conditions
	// -- Traitor: Only traitors alive
	if traitor_count > 0 && traitor_count == alive_count {
		end_game_with_victor(Player_Type.TRAITOR);
	}
	// -- Civilian: Only civilians alive
	if civilian_count > 0 && civilian_count == alive_count {
		end_game_with_victor(Player_Type.CIVILIAN);
	}
}

ao_update_voting :: proc(dt: float) {
	current_time := get_time();
	elapsed := current_time - voting_start_time;
	
	// Display voting timer
	remaining := 60.0 - elapsed;
	if remaining < 0.0 { remaining = 0.0; }
	
	voting_text := format_string("Voting ends in: %{.0} seconds", .{remaining});
	
	screen := UI.get_safe_screen_rect();
	rect := screen->subrect(0.5, 0.1, 0.5, 0.1, -150, -25, -150, -25);
	
	ts := UI.default_text_settings();
	ts.size = 48;
	ts.color = .{1, 1, 1, 1};
	ts.halign = .CENTER;
	ts.valign = .CENTER;
	
	UI.text(rect, ts, voting_text);

	// Check if all alive players have voted - early end if so
	alive_count := 0;
	voted_count := 0;
	for i: 0..players.elements.count-1 {
		if players.elements[i].player_state == Player_State.ALIVE {
			alive_count += 1;
			if players.elements[i].voted_for != null {
				voted_count += 1;
			}
		}
	}
	
	if alive_count > 0 && voted_count == alive_count {
		end_voting();
		return;
	}
	
	// After 1 minute, end voting and return to game
	if elapsed >= 60.0 {
		end_voting();
	}
}

end_voting :: proc() {
	// Tally votes and find player with most votes
	most_votes := 0;
	voted_out: Player = null;
	tie_detected := false;
	
	for i: 0..players.elements.count-1 {
		p := players.elements[i];
		if p.player_state == Player_State.ALIVE && p.votes_received > most_votes {
			most_votes = p.votes_received;
			voted_out = p;
			tie_detected = false;
		} else if p.player_state == Player_State.ALIVE && p.votes_received == most_votes && most_votes > 0 {
			tie_detected = true;
		}
	}
	
	// Execute the voted out player (if no tie and someone got votes)
	if voted_out != null && !tie_detected && most_votes > 0 {
		// Kill without spawning corpse
		voted_out.player_state = Player_State.DEAD;
		voted_out->add_ghost_reason("spectator");
		
		// Notify everyone
		ejected_message := format_string("% has been ejected!", .{voted_out.entity->get_name()});
		for i: 0..players.elements.count-1 {
			players.elements[i]->Notify(ejected_message);
		}
	} else if tie_detected {
		// Notify about tie
		for i: 0..players.elements.count-1 {
			players.elements[i]->Notify("It's a tie! No one was ejected.");
		}
	} else {
		// No votes cast
		for i: 0..players.elements.count-1 {
			players.elements[i]->Notify("No votes were cast. No one was ejected.");
		}
	}
	
	// Reset votes
	for i: 0..players.elements.count-1 {
		players.elements[i].voted_for = null;
		players.elements[i].votes_received = 0;
	}
	
	game_state = Game_State.INGAME;
	voting_start_time = 0.0;
	open_all_doors();
	
	// Notify all players
	for i: 0..players.elements.count-1 {
		players.elements[i]->Notify("Voting has ended. The game continues!");
	}
}

//Player count should change how many of each type there are
//Player count is from 5 - 10.
//at 5:  3 CIV, 1 AN, 1 TR
//at 6:  4 CIV, 1 AN, 1 TR
//at 7:  4 CIV, 1 AN, 2 TR
//at 8:  5 CIV, 1 AN, 2 TR
//at 9:  5 CIV, 2 AN, 2 TR
//at 10: 6 CIV, 2 AN, 2 TR
assign_players_to_types :: proc() {
	player_count := players.elements.count;
	
	// Determine counts for each type based on player count
	civ_count: int;
	an_count: int;
	tr_count: int;

	if player_count < 5 {
		civ_count = player_count - 1;
		an_count = 0;
		tr_count = 1;
	} else if player_count == 5 {
		civ_count = 3;
		an_count = 1;
		tr_count = 1;
	} else if player_count == 6 {
		civ_count = 4;
		an_count = 1;
		tr_count = 1;
	} else if player_count == 7 {
		civ_count = 4;
		an_count = 1;
		tr_count = 2;
	} else if player_count == 8 {
		civ_count = 5;
		an_count = 1;
		tr_count = 2;
	} else if player_count == 9 {
		civ_count = 5;
		an_count = 2;
		tr_count = 2;
	} else {
		// player_count >= 10
		civ_count = player_count - 4;
		an_count = 2;
		tr_count = 2;
	}
	
	// Create a list of types to assign
	type_list: []Player_Type = new(Player_Type, player_count);
	
	// Fill the array with the correct counts
	index := 0;
	for i: 0..civ_count-1 {
		type_list[index] = Player_Type.CIVILIAN;
		index += 1;
	}
	for i: 0..an_count-1 {
		type_list[index] = Player_Type.ANARCHIST;
		index += 1;
	}
	for i: 0..tr_count-1 {
		type_list[index] = Player_Type.TRAITOR;
		index += 1;
	}
	
	// Shuffle the type list using Fisher-Yates algorithm
	rng := rng_seed((player_count.(u64) + round_number.(u64)));
	for i: 0..type_list.count-1 {
		j := rng_range_int(&rng, i, type_list.count-1);
		temp := type_list[i];
		type_list[i] = type_list[j];
		type_list[j] = temp;
	}
	
	// Assign types to players
	for i: 0..players.elements.count-1 {
		if i < type_list.count {
			on_player_go_alive(players.elements[i]);
			players.elements[i].player_type = type_list[i];
			if(players.elements[i]->is_local_or_server()) {
				message := format_string("Player type assigned: %", .{type_list[i]});
				players.elements[i]->Notify(message);
			}
		}
	}

	// Assign roles to civilians
	for i: 0..players.elements.count-1 {
		if players.elements[i].player_type == Player_Type.CIVILIAN {
			players.elements[i].player_role = Player_Role.SHERIFF;
		}
	}
}