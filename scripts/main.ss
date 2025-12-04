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