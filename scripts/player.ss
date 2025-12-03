import "core:core.ss"

players: List(Player);

Player :: class : Player_Base {
    //Server Only!
    ao_start :: proc(using this: Player) {
        print("Hello, World!");
        append(&players, this);
    }

    ao_update :: proc(using this: Player, delta_time: float) {
        bs := UI.default_button_settings();
        ts := UI.default_text_settings();
        
        screen := UI.get_safe_screen_rect();
        rect := screen->subrect(0.5, 0.5, 0.5, 0.5, -50, -100, -50, -100);
        if UI.button(rect, "Click Me", bs, ts).clicked {
            print("Button clicked!");
        }
    }
}