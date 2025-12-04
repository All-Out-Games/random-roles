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
        
        register_ability(this, Kill_Ability);
        register_ability(this, Report_Ability);
    }

    ao_update :: proc(using this: Player, delta_time: float) {
        // bs := UI.default_button_settings();
        // ts := UI.default_text_settings();
        
        // screen := UI.get_safe_screen_rect();
        // rect := screen->subrect(0.5, 0.5, 0.5, 0.5, -50, -100, -50, -100);
        // if UI.button(rect, "Click Me", bs, ts).clicked {
        //     print("Button clicked!");
        // }
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