import "core:core.ss"

Finder :: struct($T: typeid) {
    position: v2;
    closest_distance: float;
    closest: T;

    check :: proc(using f: ref Finder(T), item: T, item_position: v2, required_range: float = -1) {
        distance := length_squared(position - item_position);
        if distance > (required_range*required_range) {
            return;
        }
        if distance < closest_distance {
            closest_distance = distance;
            closest = item;
        }
    }

    check :: proc(using f: ref Finder(T), item: T, required_range: float = -1) {
        distance := length_squared(position - item.entity.world_position);
        if distance > (required_range*required_range) {
            return;
        }
        if distance < closest_distance {
            closest_distance = distance;
            closest = item;
        }
    }
}

make_finder :: proc($T: typeid, position: v2, range := 999999999.0) -> Finder(T) {
    result: Finder(T);
    result.position = position;
    result.closest_distance = range;
    return result;
}

rebuild_game_world_navmesh :: proc() {
    world_references.main_navmesh->rebuild_immediately();
    world_references.ghost_navmesh->rebuild_immediately();
}

try_find_closest_point_on_navmesh :: proc(position: v2, point: ref v2, triangle_hint: ref s64) -> bool {
    return world_references.main_navmesh->try_find_closest_point_on_navmesh(position, point, triangle_hint);
}