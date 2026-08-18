# Human Labs Raid
Human labs is a place where players can enter a secured parameter and gather blue liquid named `PX41` at a lab inside the building. The players either force their way through and face a horde of enemies or do it (RP friendly) in stealth. Being stealthy requires a `labpermit` to enter the perimeter and inside the building, scientists must be avoided. Both ways lead to the human labs laboratory in which players can perform 3 minigames and gather `PX41`

Trailer: [https://youtu.be/T853gK63evE](https://youtu.be/T853gK63evE)

## Gameplay
Players can either approach the raid stealthy, loudly or choose both.

### Stealth
Stealthy has the benefit to be more RP, be easier, be more strategic, and does not require many players. But the stealthy approach requires a `labpermit`:
1. The `labpermit` is shown in the entry to the security
1. The players can then enter but must watch their steps. Too much suspicious activity will be noticed and leads to security alert
1. The difficulty of staying stealthy increases the further you get in the building
1. The lab area will be safe if no alarm was raised
1. The players can gather as much `PX41` as they can carry by themselves
1. Exiting stealthy is more challenging but possible

### Loudly
Players just shoot their way through and must protect the lab, because enemies are spawning regularly

### Labpermit
The `labpermit` item can be gained by robbing human labs vehicles that are driving in and out (configurable). It is durable for 6 hours (duration specified in `data/items.lua`)

### PX41 laboratory
The `PX41` item can be stolen from the human labs laboratory. It comes with a quality attribute to it: low, moderate, high, and perfect quality. The following 3 minigames are designed to immerse the players into the raid:
- **Extraction**: A pipe is modified to allow for extraction. A spectrometer is put in series to constantly measure the quality. It will alternate between pure and contaminated. The minigame is designed as a timing minigame. The quicker you want to extract, the more precise your timing must be.
- **Stabilization**: A non failable little minigame with fancy animations to turn the precursor into its stable form.
- **Packaging**: A failable minigame in which bottles must be filled without spilling much liquid. Spilling all the liquid would lead to no packaged precursor. The minigame is not hard if you take it slow.

### Balancing
| Property | Stealth | Loudly | Loudly sewers escape |
| --- | --- | --- | --- |
| **Time** | Slow and steady | Rushed and chaotic | Strategic and Controlled |
| **Amount** | Car, inventory | Car, inventory | Only inventory |
| **Difficulty** | Constant high | Increasing | Controlled increase |

## Configurations
Configurations are highly valuable to tweak and balance this raid. You can configure:
1. `Config.triggers` e.g. useful for police dispatches
1. `Config.frameworks` for non [ox] based use
1. `Config.scientist.patrolling` important to balance the difficulty of stealth mode (by default tuned perfectly)
1. `Config.security.player_ignored_by_security` e.g. to make police, medics or admins untouchable. BUT recommended to disable alarm first using the listener, because imagine you are a police who is not attacked and you handcuff a person who is actively attacked :/
1. `Config.security.disable_alarm` e.g. police sirens as a way to disable alarm
1. `Config.security` the locations for enemies could be reduced or increased depending on how much the server can handle. Invisible enemies indicates the server cannot handle this many peds
1. `Config.crafting.crafting_possible` e.g. disable after 10 minutes, police sirens trigger, 50 extractions, etc
1. `Config.crafting.crafting_speed` makes minigames faster and easier
1. `Config.transporter` can be turned off fully, adjusted spawn rate. They are also robbable/lootable for items
1. It is recommended to put a garage near coordinates `Config.reconnect_location` for anyone who might reconnect

## Download
1. Add into server.cfg the line `ensure human-labs-raid` under all other ensures
1. Modify data/items.lua weight (IMPORTANT balancing) such that
    - Player can carry at most 20 PX-41 gas (Default 30kg => weight = 1500)
    - Player can carry at most 20 PX-41 compressed gas (Default 30kg => weight = 1500)
    - Player can carry at most 100 PX-41 (Default 30kg => weight = 300)
1. Integrate the data/items.lua (into e.g. ox_inventory/data/items.lua)
1. Add the images from data/images/** (into e.g. ox_inventory/web/images/**)
1. Set lab coat outfit:
    - Start the script and create an outfit NOT CLOSE to the human labs
    - Inside the server console restart the script: `restart human-labs-raid`
    - In your F8 Player console you see your current outfit as a string, something like `components = { [0] ...`
    - Copy by double clicking the WHOLE string
    - Paste it into the curly brackets inside the file `shared/config.lua` at the attribute `Config.outfits.lab_coat_m`
    - Do the same thing again for female outfits `Config.outfits.lab_coat_f`
    - Set the property `Config.print_current_outfit = false` back in `shared/config.lua`
    - Inside the server console restart the script: `restart human-labs-raid`
1. The item 'labpermit' is required for a stealthy approach to this mission. The item is acquirable through transporters driving there. If the item should not be acquirable through those transportert, then inside `shared/config.lua` set `Config.transporter.enabled = false`

## Future Features
- On transporter task lost, still wait for no players to be around
- Notification not through [ox] but see here [https://zsx-development.gitbook.io/docs/resources/user-interface-v2/exports/interfaces/default-notifications]
- Per player cooldown, additionally to the global cooldown
- Player based scaling
- Job whitelist for who can raid

## License
Beware of the custom license that applies. Use is unrestricted, including commercially, but forking or distributing modified versions is prohibited; see the LICENSE file for the full terms.
