import "core:core.ss"
import "player.ss"

MIN_NUMBER_OF_PLAYERS: int : 2;

Game_State :: enum {
    LOBBY;
	INGAME;
}

game_state: Game_State;

ao_start :: proc(dt: float) {
	game_state = Game_State.LOBBY;
  }

ao_update :: proc(dt: float) {
	if(game_state == Game_State.LOBBY) {
		ao_update_lobby(dt);
	} else if(game_state == Game_State.INGAME) {
		ao_update_ingame(dt);
	}
  }

ao_update_lobby :: proc(dt: float) {
	if(players.elements.count >= MIN_NUMBER_OF_PLAYERS)
	{
		game_state = Game_State.INGAME;
	}
}

ao_update_ingame :: proc(dt: float) {
	print("Ingame");
}