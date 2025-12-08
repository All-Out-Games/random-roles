import "core:core.ss"
import "gamemanager.ss"
import "player.ss"

//Interactables
ao_on_interactable_used :: proc(interactable: Interactable, player: Player) {
    listener_type := #object_type(interactable.listener);
    if listener_type == Task_Interactable {
        interactable.listener.(Task_Interactable)->on_interact(player);
    }
}

ao_can_use_interactable :: proc(interactable: Interactable, player: Player) -> bool {
    listener_type := #object_type(interactable.listener);
    if listener_type == Task_Interactable {
        return interactable.listener.(Task_Interactable)->can_use(player);
    }
    return true;
}

Door :: class : Component {
    force_locked: bool @ao_serialize;
    collider_entity: Entity @ao_serialize;

    is_open: bool;

    open_door :: proc(using this: Door) {
        force_locked = false;
    }

    close_door :: proc(using this: Door) {
        force_locked = true;
    }

    ao_update :: proc(using this: Door, delta_time: float) {
        if force_locked {
            collider_entity->set_local_enabled(true);
            return;
        }
        
        found_player := false;
        foreach player: component_iterator(Player) {
            if length_squared(player.entity.world_position - collider_entity.world_position) < 1.0 {
                collider_entity->set_local_enabled(false);
                found_player = true;
                break;
            }
        }

        if !found_player {
            if is_open {
                collider_entity->set_local_enabled(true);
                is_open = false;
                rebuild_all_navmeshes();
            }
        } else {
            if !is_open {
                collider_entity->set_local_enabled(false);
                is_open = true;
                rebuild_all_navmeshes();
            }
        }
    }
}

world_references: World_References;

World_References :: class : Component {
    lobby_spawn: Entity @ao_serialize;

    ao_start :: proc(using this: World_References) {
        world_references = this;
    }

    teleport_near_lobby :: proc(using this: World_References, player: Player) {
        rng := rng_seed(player.entity.id);
        random_offset :=  v2.{rng_range_float(&rng, -2.0, 2.0), rng_range_float(&rng, -2.0,2.0)};
        set_local_position(player.entity, lobby_spawn.world_position + random_offset);
    }
}