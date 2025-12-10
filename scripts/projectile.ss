import "core:core.ss"

RR_Projectile :: class : Component {
    sprite: Sprite_Renderer @ao_serialize;
    velocity: v2;
    lifetime: float;
    damage: int;

    spawn_time: float;
    owner: Entity;
    hit_radius: float;

    start_rotation: float;

    ao_start :: proc(using this: RR_Projectile) {
        spawn_time = get_time();
        if hit_radius == 0 {
            hit_radius = 0.5;
        }

        rng := rng_seed(entity.id);
        start_rotation = rng_range_float(&rng, 0, 360);
    }

    ao_update :: proc(using this: RR_Projectile, dt: float) {
        time_alive := get_time() - spawn_time;
        sprite.entity->set_local_rotation(start_rotation + time_alive * 1440);

        // Move RR_Projectile
        entity->add_local_position(velocity * dt);

        destroy_self := false;

		// Check for player collisions
        if !destroy_self {
            foreach player: component_iterator(Player) {
                if player.player_state == Player_State.DEAD continue;
                if alive(owner) && owner == player.entity continue;
                if in_range(player.entity.world_position - entity.world_position, hit_radius) {
                    player->kill();
                    destroy_self = true;
                    {
                        sfx := default_sfx_desc();
                        sfx->set_position(player.entity.world_position);
                        sfx.volume = 0.75;
                        sfx.volume_perturb = 0.1;
                        sfx.speed_perturb = 0.2;
                        SFX.play(get_asset(SFX_Asset, "sfx/stabbed.wav"), sfx);
                    }
                    break;
                }
            }
        }

        if time_alive >= lifetime {
            destroy_self = true;
        }

        if !destroy_self {
            point: v2;
            // todo(josh): this crashes!!!:
            // if Game_Manager.bullet_navmesh->try_find_closest_point_on_navmesh(entity.world_position, &point) {
            if try_find_closest_point_on_navmesh(entity.world_position, &point) {
                if !in_range(point - entity.world_position, 0.01) {
                    destroy_self = true;
                }
            }
        }

        if destroy_self {
            hit_effect := get_asset(Prefab_Asset, "prefabs/hit_effect.prefab");
            effect := instantiate(hit_effect);
            rng := rng_seed(entity.id);
            effect.first_child->set_local_rotation(rng_range_float(&rng, 0, 360));
            effect->set_local_position(entity.world_position);
            effect->queue_for_destruction(0.5);
            destroy_entity(entity);
        }
    }
}