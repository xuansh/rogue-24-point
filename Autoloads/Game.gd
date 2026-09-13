extends Node

enum GameState {
	MENU,
	MAP,
	BATTLE,
	REWARD,
	SHOP,
	EVENT,
	GAME_OVER,
	VICTORY
}

var state : GameState = GameState.MENU

signal state_changed(old_state : GameState, new_state : GameState)

func change_state(new_state : GameState):
	if new_state == state:
		return
	
	var old_state := state
	state = new_state
	state_changed.emit(old_state, new_state)
