import "core:core.ss"
import "gamemanager.ss"
import "tools.ss"

Kill_Ability :: class : Ability_Base {
    NAME :: "Kill";

    on_init :: proc(instance: Kill_Ability) {
        instance.icon = get_asset(Texture_Asset, "sprites/icons/kill_ability.png");
    }

    get_closest_alive_player :: proc(instance: Kill_Ability, player: Player) -> Player {
        finder := make_finder(Player, player.entity.world_position, 5.0);
        for i: 0..players.elements.count-1 {
            if(players.elements[i].player_state == Player_State.ALIVE && players.elements[i] != player) {
                finder->check(players.elements[i], players.elements[i].entity.world_position);
            }
        }
        return finder.closest;
    }

    can_use :: proc(instance: Kill_Ability, player: Player) -> bool {
        return instance->get_closest_alive_player(player) != null;
    }

    on_update :: proc(instance: Kill_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked && params.can_use {
            closest_alive_player := instance->get_closest_alive_player(player);
            if closest_alive_player != null {
                closest_alive_player->kill();
                //Need to add corpse on floor!
            }
        }
    }
}

Report_Ability :: class : Ability_Base {
    NAME :: "Report";

    on_init :: proc(instance: Report_Ability) {
        instance.icon = get_asset(Texture_Asset, "sprites/icons/report_ability.png");
    }

    get_closest_corpse :: proc(instance: Report_Ability, player: Player) -> Corpse {
        finder := make_finder(Corpse, player.entity.world_position, 5.0);
        foreach corpse: component_iterator(Corpse) {
            finder->check(corpse, corpse.entity.world_position);
        }
        return finder.closest;
    }

    can_use :: proc(instance: Report_Ability, player: Player) -> bool {
        return instance->get_closest_corpse(player) != null;
    }

    on_update :: proc(instance: Report_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked && params.can_use {
            closest_corpse := instance->get_closest_corpse(player);
            if closest_corpse != null {
                // Remove the corpse and start the meeting
                destroy_entity(closest_corpse.entity);
                start_meeting();
            }
        }
    }
}

Vote_Ability :: class : Ability_Base {
    NAME :: "Vote";
    voting_ui_open: bool;

    on_init :: proc(instance: Vote_Ability) {
        instance.icon = get_asset(Texture_Asset, "sprites/icons/report_ability.png");
        instance.voting_ui_open = false;
    }

    can_use :: proc(instance: Vote_Ability, player: Player) -> bool {
        return game_state == Game_State.VOTING && player.player_state == Player_State.ALIVE;
    }

    on_update :: proc(instance: Vote_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked && params.can_use {
            instance.voting_ui_open = !instance.voting_ui_open;
        }
        
        if instance.voting_ui_open && player->is_local_or_server() {
            instance->draw_voting_ui(player);
        }
    }

    draw_voting_ui :: proc(instance: Vote_Ability, local_player: Player) {
        screen := UI.get_safe_screen_rect();
        
        // Dark background overlay
        overlay_rect := screen->subrect(0.0, 0.0, 1.0, 1.0, 0, 0, 0, 0);
        bg_texture := get_asset(Texture_Asset, "$AO/white.png");
        UI.quad(overlay_rect, bg_texture, .{0, 0, 0, 0.9});

        // Panel background
        panel_rect := screen->subrect(0.25, 0.05, 0.75, 0.95, 0, 0, 0, 0);
        UI.quad(panel_rect, bg_texture, .{0.7, 0.7, 0.7, 1.0});
        
        // Title
        title_rect := panel_rect->subrect(0.5, 0.95, 0.5, 0.95, -200, -25, -200, -25);
        ts := UI.default_text_settings();
        ts.size = 48;
        ts.color = .{1, 1, 1, 1};
        ts.halign = .CENTER;
        ts.valign = .CENTER;
        UI.text(title_rect, ts, "VOTE");
        
        // Timer display
        current_time := get_time();
        elapsed := current_time - voting_start_time;
        remaining := 60.0 - elapsed;
        if remaining < 0.0 { remaining = 0.0; }
        
        timer_rect := panel_rect->subrect(0.5, 0.88, 0.5, 0.88, -150, -20, -150, -20);
        timer_ts := UI.default_text_settings();
        timer_ts.size = 36;
        timer_ts.color = .{1, 0.3, 0.3, 1};
        if remaining > 30.0 {
            timer_ts.color = .{1, 1, 1, 1};
        } else if remaining > 10.0 {
            timer_ts.color = .{1, 0.8, 0, 1};
        }
        timer_ts.halign = .CENTER;
        timer_ts.valign = .CENTER;
        timer_text := format_string("Time: %{.0}s", .{remaining});
        UI.text(timer_rect, timer_ts, timer_text);
        
        // Calculate layout for player list
        alive_players: List(Player);
        for i: 0..players.elements.count-1 {
            if players.elements[i].player_state == Player_State.ALIVE {
                append(&alive_players, players.elements[i]);
            }
        }
        
        // Draw player entries
        start_y := 0.75;
        bs := UI.default_button_settings();
        
        for i: 0..alive_players.elements.count-1 {
            target_player := alive_players.elements[i];
            y_offset := i.(f32) * 0.1;
            
            // Entry background
            entry_rect := panel_rect->subrect(0.5, start_y - y_offset, 0.5, start_y - y_offset, -250, -35, -250, -35);
            
            // Highlight if this is who we voted for
            if local_player.voted_for == target_player {
                UI.quad(entry_rect, null, .{0.2, 0.6, 0.2, 0.9});
            } else {
                UI.quad(entry_rect, null, .{0.2, 0.2, 0.3, 0.9});
            }
            
            // Player name
            name_rect := panel_rect->subrect(0.35, start_y - y_offset, 0.35, start_y - y_offset, -100, -20, -100, -20);
            name_ts := UI.default_text_settings();
            name_ts.size = 36;
            name_ts.color = .{1, 1, 1, 1};
            name_ts.halign = .LEFT;
            name_ts.valign = .CENTER;
            UI.text(name_rect, name_ts, target_player.entity->get_name());
            
            // Vote count display
            vote_count_rect := panel_rect->subrect(0.55, start_y - y_offset, 0.55, start_y - y_offset, -30, -20, -30, -20);
            vote_ts := UI.default_text_settings();
            vote_ts.size = 32;
            vote_ts.color = .{1, 0.8, 0, 1};
            vote_ts.halign = .CENTER;
            vote_ts.valign = .CENTER;
            vote_text := format_string("Votes: %", .{target_player.votes_received});
            UI.text(vote_count_rect, vote_ts, vote_text);
            
            // Vote button (only if we haven't voted yet)
            if local_player.voted_for == null && target_player != local_player {
                button_rect := panel_rect->subrect(0.7, start_y - y_offset, 0.7, start_y - y_offset, -50, -25, -50, -25);
                btn_ts := UI.default_text_settings();
                UI.push_id("%", .{i});
                defer UI.pop_id();
                if UI.button(button_rect, bs, btn_ts, "Vote").clicked {
                    cast_vote(local_player, target_player);
                }
            } else if local_player.voted_for == target_player {
                // Show checkmark for selected player
                check_rect := panel_rect->subrect(0.7, start_y - y_offset, 0.7, start_y - y_offset, -30, -20, -30, -20);
                check_ts := UI.default_text_settings();
                check_ts.size = 40;
                check_ts.color = .{0, 1, 0, 1};
                check_ts.halign = .CENTER;
                check_ts.valign = .CENTER;
                UI.text(check_rect, check_ts, "[X]");
            }
        }
        
        // Show who voted for whom
        voter_info_rect := panel_rect->subrect(0.5, 0.15, 0.5, 0.15, -250, -50, -250, -50);
        UI.quad(voter_info_rect, null, .{0.1, 0.1, 0.15, 0.9});
        
        info_ts := UI.default_text_settings();
        info_ts.size = 24;
        info_ts.color = .{0.8, 0.8, 0.8, 1};
        info_ts.halign = .CENTER;
        info_ts.valign = .CENTER;
        
        // Build string showing who voted for whom
        vote_info := "Votes: ";
        for i: 0..players.elements.count-1 {
            p := players.elements[i];
            if p.voted_for != null && p.player_state == Player_State.ALIVE {
                vote_info = format_string("% % -> %,", .{vote_info, p.entity->get_name(), p.voted_for.entity->get_name()});
            }
        }
        UI.text(voter_info_rect, info_ts, vote_info);
        
        // Close button
        close_rect := panel_rect->subrect(0.5, 0.05, 0.5, 0.05, -75, -25, -75, -25);
        close_ts := UI.default_text_settings();
        UI.push_id("%", .{999});
        defer UI.pop_id();
        if UI.button(close_rect, bs, close_ts, "Close").clicked {
            instance.voting_ui_open = false;
        }
    }
}