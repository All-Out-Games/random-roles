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