import "core:core.ss"
import "gamemanager.ss"
import "abilities.ss"
import "tasks.ss"

players: List(Player);

Player :: class : Player_Base {
    player_type: Player_Type;
    player_state: Player_State;
    player_role: Player_Role;
    voted_for: Player;  // Who this player voted for (null if no vote yet)
    votes_received: int;  // How many votes this player has received
    active_ability: Ability_Base;
    last_aim_direction: v2;

    active_tasks : List(Task_Base);

    Notify :: proc(using this: Player, message: string) {
        if this->is_local_or_server() {
            Notifier.notify(message);
        }
    }
    
    //Server Only!
    ao_start :: proc(using this: Player) {
        append(&players, this);

        if game_state == Game_State.LOBBY {
            world_references->teleport_near_lobby(this);
        } else if game_state == Game_State.INGAME {
            on_player_go_dead(this);
        } else if game_state == Game_State.VOTING {
            on_player_go_dead(this);
            world_references->teleport_to_voting(this);
        }

        register_ability(this, Kill_Ability);
        register_ability(this, Report_Ability);
        register_ability(this, Vote_Ability);
        register_ability(this, Shoot_Ability);
        register_ability(this, Black_Flag_Ability);
    }

    ao_end :: proc(using this: Player) {
        unordered_remove_by_value(&players, this);
    }

    ao_update :: proc(using this: Player, delta_time: float) {
        if this->is_local_or_server() {
            this->setup_player_colors();
            update_tasks_ui(this);
        }
        update_tasks(this);
    }

    ao_late_update :: proc(using this: Player, delta_time: float) {
        if this->is_local_or_server() && this.player_state == Player_State.ALIVE {
            abilityIndex := 0;
            
            if game_state == Game_State.VOTING {
                // During voting, only show the vote ability
                draw_ability_button(this, Vote_Ability, abilityIndex);
            } else if game_state == Game_State.INGAME {
                // During gameplay, show abilities based on type and role
                if player_type == Player_Type.TRAITOR {
                    draw_ability_button(this, Kill_Ability, abilityIndex);
                    abilityIndex += 1;
                    
                    // Pirate gets Shoot and Black Flag abilities
                    if player_role == Player_Role.PIRATE {
                        draw_ability_button(this, Shoot_Ability, abilityIndex);
                        abilityIndex += 1;
                        draw_ability_button(this, Black_Flag_Ability, abilityIndex);
                        abilityIndex += 1;
                    }
                }
                if player_type == Player_Type.CIVILIAN && player_role == Player_Role.SHERIFF {
                    draw_ability_button(this, Shoot_Ability, abilityIndex);
                    abilityIndex += 1;
                }
                draw_ability_button(this, Report_Ability, abilityIndex);
            }
        }
    }

    setup_player_colors :: proc(using this: Player) {
        if player_type != Player_Type.TRAITOR || player_state != Player_State.ALIVE {
            //Non Traitors & dead / lobby / spectators don't know who is who, no colors to set!
            foreach player: component_iterator(Player) {
                player.do_name_color_override = false;
            }
            return;
        }
        foreach player: component_iterator(Player) {
            if player != this {
                player.do_name_color_override = true;
                if(this.player_type == player.player_type) {
                    player.name_color_override = .{0, 1, 0, 1};
                } else {
                    player.name_color_override = .{1, 0, 0, 1};
                }
            }
        }
    }

    kill :: proc(using this: Player) {
        //freeze_player = true;
        on_player_go_dead(this);
        world_references->spawn_corpse(this);
        log(format_string("Player % killed", .{this.entity.id}));
    }

    revive :: proc(using this: Player) {
        //freeze_player = false;
        this->set_trigger("RESET");
    }

    set_trigger :: proc(using this: Player, trigger: string) {
        if this.animator.instance != null {
            this.animator.instance.state_machine->set_trigger(trigger);
        }
    }
}

Task_Interactable :: class : Component {
    interactable: Interactable @ao_serialize;

    ao_start :: proc(using this: Task_Interactable) {
        interactable.listener = this;
    }

    on_interact :: proc(using this: Task_Interactable, player: Player) {
        for i: 0..player.active_tasks.elements.count-1 {
            if player.active_tasks.elements[i].id == get_name(this.entity) {
                player.active_tasks.elements[i]->start_attempt(player);
                break;
            }
        }
    }

    can_use :: proc(using this: Task_Interactable, player: Player) -> bool {
        can_use_base := player.player_state == Player_State.ALIVE && player.player_type == Player_Type.CIVILIAN;
        if !can_use_base {
            return false;
        }
        for i: 0..player.active_tasks.elements.count-1 {
            if player.active_tasks.elements[i].id == get_name(this.entity) && !player.active_tasks.elements[i].started {
                return true;
            }
        }
        return false;
    }
}

Call_Meeting_Interactable :: class : Component {
    interactable: Interactable @ao_serialize;
    
    ao_start :: proc(using this: Call_Meeting_Interactable) {
        interactable.listener = this;
    }

    on_interact :: proc(using this: Call_Meeting_Interactable, player: Player) {
        start_meeting(false);
    }

    can_use :: proc(using this: Call_Meeting_Interactable, player: Player) -> bool {
        return player.player_state == Player_State.ALIVE;
    }
}

Corpse :: class : Component {
    has_been_reported: bool;
}