# Random Roles — Hub

This branch contains the hub project for **Random Roles**, the multiplayer social-deduction game on [All Out](https://allout.game/). Players explore roles, choose their loadout, access role unlocks, and enter matches through the hub's portals.

You are on **`hub`**. The match itself—tasks, role abilities, sabotage, voting, and win conditions—lives on **[main](https://github.com/All-Out-Games/random-roles/tree/main)**. See the [main README](https://github.com/All-Out-Games/random-roles/blob/main/README.md) for the game's architecture.

## Script architecture

| Start here | Responsibility |
| --- | --- |
| [scripts/main.csl](scripts/main.csl) | Core and hub imports, startup, and shared world behavior. |
| [scripts/player.csl](scripts/player.csl) | Hub player behavior and presentation. |
| [scripts/hub/hub_constants.csl](scripts/hub/hub_constants.csl), [hub_portals.csl](scripts/hub/hub_portals.csl) | Destination configuration and transferring players into matches. |
| [scripts/hub/loadout.csl](scripts/hub/loadout.csl) | Loadout selection. |
| [scripts/hub/roles_guide.csl](scripts/hub/roles_guide.csl), [roles_new.csl](scripts/hub/roles_new.csl) | Role information and presentation. |
| [scripts/hub/ninja_claim.csl](scripts/hub/ninja_claim.csl), [ggg_pedestal.csl](scripts/hub/ggg_pedestal.csl) | Role-specific claim and unlock interactions. |
| [scripts/hub/transferring_screen.csl](scripts/hub/transferring_screen.csl) | Presentation while joining a match. |

[scene/](scene/) contains the hub world and component settings; [res/](res/) holds its assets. This is a separate All Out project from the match, with its own `ao.project` identities.

## How CSL works here

CSL is All Out's statically typed scripting language, compiled by the All Out editor. [ao.project](ao.project) enables CSL with `"csl": true`.

`main.csl` imports `core:ao`, `core:global_leaderboard`, and the `hub` folder. The engine calls startup and frame callbacks on the game's player and world components. Serialized fields connect those components to the scene. All Out handles client prediction and authoritative server reconciliation; each player's loadout and interactions belong to that player's state. Portals use the configured destination game IDs to connect this hub to the match project.

The `scripts/.ao_core/` and `api_references/` folders provide engine references. Start hub changes in `scripts/hub/` and match changes on `main`.

## Open and remix

1. Set up the [Windows All Out editor](https://docs.allout.game/getting-started/first-game).
2. Clone the hub into its own folder:

   ```sh
   git clone --branch hub https://github.com/All-Out-Games/random-roles.git random-roles-hub
   ```

3. Use **Open project** on the folder containing `ao.project`. Wait for compilation and asset preparation, then **Play** to inspect the hub.
4. For a published remix, create your own hub and match games in the Creator Portal. Associate each working copy with its own identity, and update the hub's destination and product IDs for your games before using the portals.

Requires the All Out editor/runtime and referenced platform assets. Saving scripts triggers compilation; restart play mode for startup or scene changes. See [CSL syntax](https://docs.allout.game/scripting/syntax), [networking](https://docs.allout.game/scripting/networking-fundamentals), and [playtesting](https://docs.allout.game/getting-started/playtesting-your-game).

## License

The code, documentation, and original assets contributed by All Out Games in this repository's `main` and `hub` branches are available under the [MIT License](LICENSE). You may copy, modify, remix, distribute, and use them in commercial games, including games published on All Out. Keep the copyright and license notice with copies or substantial portions.

Separately licensed third-party material retains its own terms. References to platform-provided assets, such as `$AO/...`, do not transfer ownership of those assets or license the All Out engine and services.
