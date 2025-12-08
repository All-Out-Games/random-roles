import "core:core.ss"
import "gamemanager.ss"
import "abilities.ss"

players: List(Player);

Player :: class : Player_Base {
    player_type: Player_Type;
    player_state: Player_State;
    
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
        }
        
        register_ability(this, Kill_Ability);
        register_ability(this, Report_Ability);
    }

    ao_update :: proc(using this: Player, delta_time: float) {
        if this->is_local_or_server() {
            this->setup_player_colors();
        }
    }

    ao_late_update :: proc(using this: Player, delta_time: float) {
        if this->is_local_or_server() && this.player_state == Player_State.ALIVE {
            abilityIndex := 0;
            if player_type == Player_Type.TRAITOR {
                draw_ability_button(this, Kill_Ability, abilityIndex);
                abilityIndex += 1;
            }
            draw_ability_button(this, Report_Ability, abilityIndex);
        }
    }

    setup_player_colors :: proc(using this: Player) {
        if player_type == Player_Type.CIVILIAN || player_state != Player_State.ALIVE {
            //Civilians & dead / lobby / spectators don't know who is who, no colors to set!
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
}

Task_Interactable :: class : Component {
    interactable: Interactable @ao_serialize;

    ao_start :: proc(using this: Task_Interactable) {
        interactable.listener = this;
    }

    on_interact :: proc(using this: Task_Interactable, player: Player) {
        player->Notify("You interacted with the task!");
    }

    can_use :: proc(using this: Task_Interactable, player: Player) -> bool {
        return player.player_state == Player_State.ALIVE && player.player_type == Player_Type.CIVILIAN;
    }
}