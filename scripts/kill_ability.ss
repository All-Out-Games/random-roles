import "core:core.ss"
import "gamemanager.ss"
import "tools.ss"

Kill_Ability :: class : Ability {
    NAME :: "Kill";
    ICON :: "sprites/icons/kill_ability.png";

    can_use :: proc(instance: Kill_Ability, player: Player) -> bool {
        return true;
    }

    on_update :: proc(instance: Kill_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked {
            finder := make_finder(Player, player.entity.world_position, 5.0);
            for i: 0..players.elements.count-1 {
                if(players.elements[i].player_state == Player_State.ALIVE && players.elements[i] != player) {
                    finder->check(players.elements[i], players.elements[i].entity.world_position);
                }
            }
            if finder.closest != null {
                finder.closest.player_state = Player_State.DEAD;
                //For now: Immediate passive, later will do death animation first!
                on_player_go_passive(finder.closest);
            }
        }
    }
}