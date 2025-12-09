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
    voting_spawn: Entity @ao_serialize;
    corpse_prefab: Prefab_Asset;

    ao_start :: proc(using this: World_References) {
        corpse_prefab = get_asset(Prefab_Asset, "prefabs/Corpse.prefab");
        world_references = this;
    }

    teleport_near_lobby :: proc(using this: World_References, player: Player) {
        rng := rng_seed(player.entity.id);
        random_offset :=  v2.{rng_range_float(&rng, -2.0, 2.0), rng_range_float(&rng, -2.0,2.0)};
        set_local_position(player.entity, lobby_spawn.world_position + random_offset);
    }

    teleport_to_voting :: proc(using this: World_References, player: Player) {
        // Find player index in the players array
        player_index := 0.0;
        for i: 0..players.elements.count-1 {
            if players.elements[i] == player {
                player_index = i.(f32);
                break;
            }
        }
        
        // Calculate position in circle around voting spawn
        total_players := players.elements.count.(f32);
        if total_players == 0.0 { total_players = 1.0; }
        radius := 2.0;
        angle := (player_index / total_players) * 2.0 * PI;
        offset := v2.{cos(angle) * radius, sin(angle) * radius};
        
        set_local_position(player.entity, voting_spawn.world_position + offset);
    }

    spawn_corpse :: proc(using this: World_References, player: Player) {
        corpse := instantiate(corpse_prefab);
        set_local_position(corpse, player.entity.world_position);
        set_local_rotation(corpse, player.entity.world_rotation);
        set_local_scale(corpse, player.entity.world_scale);
        spine_Animator := corpse->get_component(Spine_Animator);
        spine_Animator->set_color_replace_color(player.color_replace_color);
        spine_Animator.instance->disable_all_skins();
        player_skins := player.animator.instance->get_skins();
        for i: 0..player_skins.count-1 {
            spine_Animator.instance->enable_skin(player_skins[i]);
        }
    }
}