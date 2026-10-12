# Random Roles

A multiplayer social-deduction game for [All Out](https://allout.game/). Players receive roles with different allegiances, abilities, and win conditions. Complete tasks, investigate suspicious behavior, use role-specific powers, and vote while traitors and other roles pursue their own objectives.

## Game and hub branches

- **[main](https://github.com/All-Out-Games/random-roles/tree/main)** contains the actual match: roles, tasks, combat, sabotage, voting, and victory conditions. This README's architecture table describes `main`.
- **[hub](https://github.com/All-Out-Games/random-roles/tree/hub)** contains the separate entry/lobby project: role guides, loadout and unlock presentation, and portals into matches. Start with its `scripts/main.csl`, `scripts/player.csl`, and `scripts/hub/` folder.

Each branch has its own scene and `ao.project` identities. Keep them in separate folders if you want to work on both, and configure the hub's destinations for your own game when remixing.

## Script architecture

| Start here on `main` | Responsibility |
| --- | --- |
| [scripts/main.csl](scripts/main.csl) | Imports, shared startup, and world components such as doors. |
| [scripts/gamemanager.csl](scripts/gamemanager.csl) | Game phases, player types and roles, round setup, voting flow, and win conditions. |
| [scripts/player.csl](scripts/player.csl) | Per-player state, role integration, movement/combat behavior, and UI. |
| [scripts/role_pools.csl](scripts/role_pools.csl) | Role selection pools and purchase-related weighting. |
| [scripts/role_modules.csl](scripts/role_modules.csl) | Role-specific state components attached to players for the round. |
| [scripts/abilities.csl](scripts/abilities.csl) and role files such as [ninja.csl](scripts/ninja.csl), [mech.csl](scripts/mech.csl), [hacker.csl](scripts/hacker.csl), [werewolf.csl](scripts/werewolf.csl) | Shared actions and individual role mechanics. The `ninja_*.csl` files split out the Ninja's abilities and presentation. |
| [scripts/tasks.csl](scripts/tasks.csl), [sabotage.csl](scripts/sabotage.csl), [voting_ui.csl](scripts/voting_ui.csl) | Objectives, disruptions, and voting presentation. |
| [scripts/loadout.csl](scripts/loadout.csl), [popups.csl](scripts/popups.csl) | Loadout handling and round/player feedback. |

The manager establishes the round and assigns roles. Each player receives the state and abilities for that role; task progress, sabotage, eliminations, and votes feed back into the manager's win conditions. Role modules are added for the round and removed when it ends.

## How CSL works here

CSL is All Out's statically typed scripting language. The editor compiles `.csl` files and runs them in the All Out engine; [ao.project](ao.project) selects CSL with `"csl": true`.

- `main.csl` imports `core:ao` and `reusable_weapons`. Source files in the root scripts folder supply the game and role definitions; folder imports bring in additional modules.
- `Player` extends `Player_Base`. Role modules extend `Component`, letting each player carry only the role-specific state they need. Abilities and effects integrate those roles with the engine's action system.
- Lifecycle callbacks such as `ao_start`, `ao_update`, and `ao_late_update` connect startup, gameplay, and UI to the engine's frame loop. Serialized component fields connect scripts to the authored scene.
- Client prediction and authoritative server reconciliation synchronize the shared simulation. Keep role state on the relevant player/component and keep presentation-only state separate when adding new powers.

[scene/](scene/) stores the world and component settings; [res/](res/) stores project assets. `scripts/.ao_core/` and `api_references/` are engine reference material. Begin changes in the game or role files above.

## Open and remix

1. Set up the [Windows All Out editor](https://docs.allout.game/getting-started/first-game).
2. Clone the match project:

   ```sh
   git clone --branch main https://github.com/All-Out-Games/random-roles.git
   ```

   For a separate hub checkout:

   ```sh
   git clone --branch hub https://github.com/All-Out-Games/random-roles.git random-roles-hub
   ```

3. Open the desired folder containing `ao.project` in the editor. Wait for compilation and asset preparation, then **Play** with multiple clients to exercise role assignment, voting, and opposing teams.
4. Create your own Creator Portal game identities before publishing a remix. Update the project association, hub-to-match destinations, and game-specific product IDs together so your hub sends players to your matches.

Requires the All Out editor/runtime and referenced platform assets. Saving scripts triggers compilation; restart tests after changing startup or scene data. Read the [CSL guide](https://docs.allout.game/scripting/syntax), [networking guide](https://docs.allout.game/scripting/networking-fundamentals), and [playtesting guide](https://docs.allout.game/getting-started/playtesting-your-game).

## License

The code, documentation, and original assets contributed by All Out Games in this repository's `main` and `hub` branches are available under the [MIT License](LICENSE). You may copy, modify, remix, distribute, and use them in commercial games, including games published on All Out. Keep the copyright and license notice with copies or substantial portions.

Separately licensed third-party material retains its own terms. References to platform-provided assets, such as `$AO/...`, do not transfer ownership of those assets or license the All Out engine and services.
