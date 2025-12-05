import "core:core.ss"
import "gamemanager.ss"
import "tools.ss"

Kill_Ability :: class : Ability {
    NAME :: "Kill";
    ICON :: "sprites/icons/kill_ability.png";

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
                closest_alive_player.player_state = Player_State.DEAD;
                //For now: Immediate passive, later will do death animation first!
                on_player_go_passive(closest_alive_player);
            }
        }
    }
}

Report_Ability :: class : Ability {
    NAME :: "Report";
    ICON :: "sprites/icons/report_ability.png";

    get_closest_dead_player :: proc(instance: Report_Ability, player: Player) -> Player {
        finder := make_finder(Player, player.entity.world_position, 5.0);
        for i: 0..players.elements.count-1 {
            if(players.elements[i].player_state == Player_State.DEAD && players.elements[i] != player) {
                finder->check(players.elements[i], players.elements[i].entity.world_position);
            }
        }
        return finder.closest;
    }

    can_use :: proc(instance: Report_Ability, player: Player) -> bool {
        return instance->get_closest_dead_player(player) != null;
    }

    on_update :: proc(instance: Report_Ability, player: Player, params: Ability_Update_Params) {
        if params.clicked && params.can_use {
            closest_dead_player := instance->get_closest_dead_player(player);
            if closest_dead_player != null {
                //Start meeting
            }
        }
    }
}