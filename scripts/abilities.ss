import "core:core.ss"
import "gamemanager.ss"
import "tools.ss"
import "projectile.ss"

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

Always_Aiming_Ability_Data :: struct {
    aim:   bool;
    shoot: bool;
}

update_always_aiming_ability :: proc(player: Player, params: ref Ability_Update_Params) -> Always_Aiming_Ability_Data {
    if player.player_state != Player_State.ALIVE {
        return .{};
    }

    result: Always_Aiming_Ability_Data;
    if params.held {
        if length(params.drag_offset) > 0.1 {
            result.aim = true;
            result.shoot = true;
        }
    }
    else {
        if player.device_kind == .PC {
            if player.active_ability == null {
                UI.push_layer(-1000);
                defer UI.pop_layer();
                UI.push_id("click to shoot");
                defer UI.pop_id();

                interact := UI.button(UI.get_screen_rect(), .{}, .{}, "");

                if interact.hovering {
                    result.aim = true;
                    params.drag_direction = normalize(get_mouse_world_position() - player.entity.world_position);
                }

                if params.can_use {
                    if interact.active {
                        result.shoot = true;
                    }
                }
            }
        }
    }

    if result.aim {
        player.last_aim_direction = params.drag_direction;
        draw_thin_aiming_line(player.entity.world_position, params.drag_direction, 1.0 / player.camera.size * 4);
    }

    return result;
}

shoot_projectile :: proc(spawn_position: v2, velocity: v2, damage: int, lifetime: float, owner: Entity) -> Entity {
    prefab := get_asset(Prefab_Asset, "prefabs/RR_Projectile.prefab");
    entity := instantiate(prefab);
    entity->set_local_position(spawn_position);

    projectile := entity->get_component(RR_Projectile);
    projectile.velocity = velocity;
    projectile.lifetime = lifetime;
    projectile.damage = damage;
    projectile.owner = owner;
    return entity;
}

Shoot_Ability :: class : Ability_Base {
    on_init :: proc(ability: Shoot_Ability) {
        ability.name = "Shoot";
        ability.disable_keybind = true;
        ability.is_aimed_ability = true;
    }

    on_update :: proc(ability: Shoot_Ability, player: Player, params: Ability_Update_Params) {
        aiming := update_always_aiming_ability(player, &params);
        if params.can_use {
            if aiming.shoot {
                sfx := default_sfx_desc();
                sfx->set_position(player.entity.local_position);
                sfx.volume_perturb = 0.2;
                sfx.speed_perturb = 0.1;
                shoot_projectile(player.entity.world_position, params.drag_direction * 10.0, 1, 0.75, player.entity);
                SFX.play(get_asset(SFX_Asset, "sfx/shoot.wav"), sfx);
                ability.current_cooldown = 30.0;
            }
        }
    }
}

// Black Flag - Pirate ability that creates a fog zone
BLACK_FLAG_RADIUS :: 5.0;
BLACK_FLAG_DURATION :: 30.0;

Black_Flag :: class : Component {
    owner_entity: Entity;
    spawn_time: float;
    
    ao_start :: proc(using this: Black_Flag) {
        spawn_time = get_time();
    }
    
    ao_update :: proc(using this: Black_Flag, dt: float) {
        time_alive := get_time() - spawn_time;
        
        // Destroy after duration
        if time_alive >= BLACK_FLAG_DURATION {
            destroy_entity(entity);
            return;
        }
        
        // Apply fog effect to nearby players (client-side rendering)
        foreach player: component_iterator(Player) {
            if player.player_state != Player_State.ALIVE continue;
            if !player->is_local_or_server() continue;
            
            distance := length(player.entity.world_position - entity.world_position);
            if distance < BLACK_FLAG_RADIUS {
                // Check if this player is immune (the Pirate who placed it)
                is_pirate_owner := alive(owner_entity) && owner_entity == player.entity;
                
                if !is_pirate_owner {
                    // Draw fog overlay - obscures vision except small circle in center
                    draw_fog_overlay(player);
                }
            }
        }
    }
}

draw_fog_overlay :: proc(player: Player) {
    fog_texture := get_asset(Texture_Asset, "$AO/white.png");
    
    // Draw dark fog covering the entire screen
    UI.push_layer(1000);
    defer UI.pop_layer();
    
    // Draw fog in 4 rectangles around the center hole
    fog_color := v4.{0, 0, 0, 0.99};
    
    screen := UI.get_screen_rect();
    // Parameters: min_x, min_y, max_x, max_y
    left_rect := screen->subrect(0, 0, 0.4, 1);
    UI.quad(left_rect, fog_texture, fog_color);
    right_rect := screen->subrect(0.6, 0, 1, 1);
    UI.quad(right_rect, fog_texture, fog_color);
    top_rect := screen->subrect(0, 0, 1, 0.4);
    UI.quad(top_rect, fog_texture, fog_color);
    bottom_rect := screen->subrect(0, 0.6, 1, 1);
    UI.quad(bottom_rect, fog_texture, fog_color);
}

Black_Flag_Ability :: class : Ability_Base {
    NAME :: "Black Flag";
    
    on_init :: proc(ability: Black_Flag_Ability) {
        //ability.icon = get_asset(Texture_Asset, "sprites/icons/kill_ability.png"); // TODO: Replace with proper icon
    }
    
    can_use :: proc(ability: Black_Flag_Ability, player: Player) -> bool {
        return player.player_state == Player_State.ALIVE;
    }
    
    on_update :: proc(ability: Black_Flag_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked && params.can_use {
            // Create the black flag at player's position
            flag_entity := create_entity();
            flag_entity->set_local_position(player.entity.local_position);
            
            // Add sprite for the flag
            sprite := flag_entity->add_component(Sprite_Renderer);
            sprite->set_texture(get_asset(Texture_Asset, "$AO/white.png")); // TODO: Replace with skull flag sprite
            sprite.color = .{0.1, 0.1, 0.1, 1.0}; // Dark color for the flag
            flag_entity->set_local_scale(.{100.0, 100.0});
            
            // Add the Black_Flag component
            flag := flag_entity->add_component(Black_Flag);
            flag.owner_entity = player.entity;
            
            player->Notify("Black Flag placed!");
            ability.current_cooldown = 60.0;
        }
    }
}