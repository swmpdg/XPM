# XPM
Revamped AMX Mod X Experience Mod (originated from Sven Coop Experience Mod [SCXPM] redesign for Sven Co-op 5)

# Credit
I copy and pasted some of the code, and used other's code as an example for design. A lot of work was done myself and is continually being done. Silencer is the original author of SCXPM https://forums.alliedmods.net/showthread.php?t=44168, Exolent is the original author of the Shop API https://forums.alliedmods.net/showthread.php?t=44168, and to anyone else whose work I have used I thank you.

- xpm_xp_system.sma
original Sven Coop Experience Mod (SCXPM) concept and experience calculations by Silencer and others https://forums.alliedmods.net/showthread.php?t=44168

- shop_api.sma
Original Shop API concept by Exolent https://forums.alliedmods.net/showthread.php?p=1642081


# Requirements
- AMX Mod X 1.8.2 or greater
- Shop API (modified Shop API script is included in this repository for use with mods other than Counter-Strike 1.6)
- Debug Helper script (included in this repository)

# Installation
- Plugins: Make sure debug_helper.amxx is loaded first, and shop_api.amxx is loaded before any other plugins which use the "register_skill" function.
- shop_api.amxx will generate the shop.cfg and shop_gen.cfg file with the cvars in them. If you install new plugins after the initial load, you will need to delete shop.cfg and shop_gen.cfg to re-create the configuration files with the updated information.

# More information will be added over time
