import "core:core.ss"
import "gamemanager.ss"
import "kill_ability.ss"

players: List(Player);
button_green: Texture_Asset;

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

        button_green = get_asset(Texture_Asset, "$AO/white.png");
        
        register_ability(this, Kill_Ability);
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
        if this->is_local_or_server() && this.player_state == Player_State.ALIVE && player_type == Player_Type.TRAITOR {
            draw_ability_button(this, Kill_Ability, 0);
        }
    }
}