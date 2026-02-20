# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

---

## Project Overview

**Random Roles** is an Among Us-style multiplayer game where players are assigned secret roles each round. Civilians complete tasks to win; Traitors sabotage and kill; Anarchists pursue their own objectives.

## Building

After making any code changes, **always** run the MCP compile tool:
```
mcp__allout__compile()
```
This is the only build step. There are no tests or linters.

## Architecture

### Game State Machine

The game cycles through states managed in `gamemanager.csl`. The global `game_state` variable drives all logic:

- `LOBBY` → players wait, lobby timer counts down → `INGAME`
- `INGAME` → gameplay, tasks, killing → `BODY_FOUND` / `MEETING_CALLED`
- `VOTING` → players vote → `VOTE_EJECT` cinematic → back to `INGAME` or end game
- `JESTER_WIN` / `PYRO_WIN` / `VICTORY` → end cinematics → `LOBBY`

Key setup procs: `setup_lobby()`, `setup_ingame()`, `setup_voting()`, `finalize_voting()`.

### Player Roles & Types

Every player has both a **type** and a **role**:

| Type | Roles |
|------|-------|
| `CIVILIAN` | Sheriff, Doctor, President, Movie Star, Coroner, Portal Maker |
| `ANARCHIST` | Prankster, Pyromaniac |
| `TRAITOR` | Pirate, Hitman, Werewolf |

Roles are assigned via a **bag system** (no duplicates per round, maximizes variety). See `assign_players_to_types()` in `gamemanager.csl`.

Win conditions (in `ao_update_ingame`):
- **Civilians**: all traitors dead, or all tasks complete
- **Traitors**: equal or outnumber non-traitors, or all non-traitors infected
- **Anarchists** (Prankster/Pyromaniac): unique win conditions per role

### Key Files

| File | Purpose |
|------|---------|
| `player.csl` | `Player` class (extends `Player_Base`), all per-player fields, HUD drawing, voice chat, LOS vision, minimap, corpse dragging |
| `gamemanager.csl` | Game state machine, round flow, voting, sabotages, role assignment, win conditions, admin chat commands |
| `abilities.csl` | All ability implementations (Kill, Shoot, Resurrect, DNA Sample/Match, Werewolf abilities, Hitman abilities, Pirate abilities, Prankster abilities, Pyromaniac abilities, Portal abilities, Movie Star) |
| `tasks.csl` | All task minigames (Repair Laptop, Jail Codes, Reroute Power, Guide the Electron, Catching Butterflies, Signal Sync, Anagram Puzzle, Calibrate Teleporter, Cypher) + task list UI |
| `main.csl` | Entry point with all imports; also contains `Door`, `Door_Unlock_Interactable`, and `World_References` components |
| `pyromaniac.csl` | Pyromaniac fire system (fire spreading, room burn tracking, player-on-fire status) |
| `portal_maker.csl` | Portal teleportation logic |
| `voting_ui.csl` | Voting screen UI |
| `popups.csl` | Popups: body found, meeting called, intro, victory |
| `sabotage.csl` | Sabotage system (power outage, comms outage, lockdown) |
| `tools.csl` | Shared utilities: `Finder<T>` helper, navmesh helpers, UI kit helpers, SFX wrapper |
| `projectile.csl` | `RR_Projectile` component for Sheriff/Hitman Sniper shots |

### The `Player` Class

`player.csl:45` — All per-player state lives on the `Player` class fields (never global variables). This is critical for multiplayer correctness. Fields are grouped by system (Pyromaniac, Doctor, Sheriff, Coroner, Portal Maker, Hitman, Pirate, Werewolf, etc.).

Key Player methods:
- `ao_update` — runs on server + local player; handles freeze logic, ghost/speed, werewolf transform, portal teleport, door unlock interactable
- `ao_late_update` — draws all HUD (role HUD, task list, minimap, sabotage buttons, ability buttons, cinematics)
- `kill_with_killer_and_corpse()` — spawns corpse prefab, triggers death animation
- `apply_voice_chat_masks_for_current_state()` — routes voice to alive/dead channels

### `World_References` (Singleton Component)

`main.csl:177` — A scene-placed component that holds references to key scene entities: lobby spawn, voting spawn, navmeshes, map bounds, sabotage interactables. Accessed globally via `world_references`.

### Ability Pattern

Abilities follow a consistent struct pattern in `abilities.csl`:
- `on_init` — called once at setup
- `can_use` — returns bool gating usage
- `on_update` — handles tap/hold input and applies effect
- `on_draw_button` — renders the ability button

Abilities are registered per-role in `Player.ensure_anim_state_machine()` (`player.csl`).

### Task Pattern

Tasks in `tasks.csl` extend `Task_Base` and implement:
- `start_attempt` / `cancel_attempt` — called when player opens/closes task
- `update_task` — renders interactive minigame UI and checks for completion

Tasks are assigned randomly via `get_random_task_list()`. Sabotage injects special tasks (`Task_Restart_Generator`, `Task_Enable_Communications`) directly into `player.active_tasks`.

### Finder Utility

`tools.csl:3` — Use `make_finder(T, position, range)` + iterate + `finder.check(item)` to find the closest component within range. Used throughout abilities for targeting.

```csl
finder := make_finder(Player, player.entity.world_position, 5.0);
foreach p: component_iterator(Player) {
    finder->check(p);
}
target := finder.closest;
```

### Admin Chat Commands

`gamemanager.csl:2061` — Registered via `Chat.register_command`. Available commands: `start`, `r <role>`, `traitors <count>`, `end`, `restart`, `pause`, `unpause`, `kill`, `cd` (reset cooldowns), `unstuck`.

## Important Conventions

- **`is_local_or_server()`** for gameplay logic; **`is_local()`** for cosmetics/UI only
- **`Game.is_server()`** for long SFX, one-time server events (avoid double-play)
- Role-specific player fields use a prefix: `hitman_`, `werewolf_`, `pirate_`, `pyro_`, `doctor_`, `coroner_`, `portal_maker_`, `prankster_`
- `rr_` prefix on global procs indicates "Random Roles" module-level helpers
- The `rr_rng_state` global is always refreshed with `rr_refresh_rng_state()` before use—never cache it
- Navmesh must be rebuilt after door state changes: call `rebuild_game_world_navmesh()`
