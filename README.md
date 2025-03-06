# Rotwood Modloader

## API v1 branch

This is the (WIP) updated documentation for Rotwood's new modloader implementation (mod API version 1). This applies to Rotwood REV 657187 and above (Delicious Beta).

There's still a lot of untested stuff, so please submit issues if you encounter any bugs or crashes.

Please read through the updated instructions thoroughly and see [Breaking Changes](#breaking-changes).

## Introduction

**Rotwood currently does not officially support modding and Klei will not provide support for modded installs, please back up your save files and use/create mods at your own risk. [Read more here](https://support.klei.com/hc/en-us/articles/28992668677140-Rotwood-Client-Mods)**

**(Outdated) Original post on Klei forums:** <https://forums.kleientertainment.com/forums/topic/155849-unofficial-modding-support/>

Rotwood manages and loads mods using a few different components (mainly ModIndex and ModWrangler). At the time, these parts are not fully functional and are disabled by default, but with some modifications to game scripts they can work just fine.

Please note that this is still very experimenetal and some modding API features may not work correctly or at all.

Heres a rough list of things that are possible with modding right now (might be incomplete):

- Working:
  - General modding (globals, players, entities, components. events, inputs, classes, tunings, strings, etc)
  - `modimport`, `require` for other mod scripts (working searchpaths).
  - `modinfo` (using the same structure as DST)
  - Mod icons (should work without issues, though support for it depends on the [Mod Menu](#mod-menu) mod)
  - Mod configuration options
  - `modsettings.lua`
  - Upvalue
  - `AddClassPostConstruct`
  - Widgets, Screens and general UI
  - Stategraphs
  - Components
  - ImGui panels
  - Add*PostInit (tested: `AddGamePostInit`, `AddSimPostInit`, `AddComponentPostInit`, `AddPrefabPostInit`, `AddPrefabPostInit`, `AddPrefabPostInitAny`, `AddPlayerPostInit`)
  - Texture assets (TEX/XML and PNG)
  - Powers
  - Gems
  - *Weapons
- Known issues / not tested:
  - *Networking (communicating with remote clients and sending data back and forth) (reason: not implemented and/or not enough info about Rotwood networking systems)
    - You can use serialization to sync data in components on network tho.
  - Loading modded anim builds/banks
  - (TEX/XML) Loading tex/atlas in nested paths (like `images/color_cubes/identity_cc.tex`) will cause errors.
    - e.g: The game will try to load `images/color_cubes.tex` ?????

## Installation

### Diff Patches (Recommended)

For making said modifications to game scripts, I've made diff patches for the most recent builds and will try to continue providing these patches for future versions, you can find them in the `patches/` folder in this repo, just pick one with the build revision number you need and apply it with **GNU Patch**.

If there isn't one for the build you need (maybe I haven't uploaded the latest patches yet), you can either:

- Follow manual instructions below to edit the scripts yourself
  - And maybe contribute new patch files to the repository if you can <3 (see [Note For Contributors](#note-for-contributors))
- Submit an issue on this GitHub repo to notify me (provide your revision number)

**Linux:** The `patch` utility should be included in most Linux distros, if you have GNU utils, you probably have it already. If not, it's most likely available from your distro's package repos.

**Windows:** Install [Git](git-scm.com) (`patch` is included in Git Bash), then open a Bash terminal by right clicking in a File Explorer window and select "Git Bash Here", and follow the same steps below.

To apply a patch, have your `data_scripts.zip` extracted and navigate to the directory that contains `scripts/` (e.g: `data/`), then run this:

```shell
patch -p0 < patchfile
```

Where `patchfile` would be the patch file you're applying, for example: `637216.patch`.  Your scripts should be automatically patched with the necessary modifications to load mods.

You should be getting output like this

```shell
patching file scripts/entityscript.lua
patching file scripts/gamelogic.lua
patching file scripts/mainfunctions.lua
patching file scripts/main.lua
patching file scripts/modindex.lua
patching file scripts/mods.lua
patching file scripts/modutil.lua
patching file scripts/screens/modwarningscreen.lua
patching file scripts/strings/strings.lua
patching file scripts/util.lua
```

### Manual Patching

**NOTE:** You need to extract game scripts to edit them, read `data/scripts_readme.txt` in Rotwood's game files directory for Klei's instructions to extract and load said extracted scripts for Rotwood.

You will be modifying, commenting and adding some code in the game scripts, if you're not familiar with lua's comment syntax, read [here](https://www.lua.org/pil/1.3.html) first. There's quite a few files to edit, so it may be a lengthy process, this should take 5-10 minutes of your time.

#### Allow mods to be loaded

In `main.lua`, add the following line in the `--defines` area, preferably right below the `--defines` line

**NOTE (apiv1):** `MODS_ENABLED` is already enabled, but now you need to enable `GAMEPLAY_MODS_ENABLED` instead.

```lua
GAMEPLAY_MODS_ENABLED = true
```

Uncomment this line below `--#V2C no mods for now... deal with this later T_T` in the `ModSafeStartup` function

```lua
--ModManager:LoadMods()
```

#### modutil

In `modutil.lua`, comment these lines

```lua
env.Ingredient = Ingredient
```

```lua
env.MOD_RPC = MOD_RPC --legacy, mods should use GetModRPC below
```

#### ModIndex

In `modindex.lua`, edit the `ModType` enum as follow

```diff
local ModType = Enum{
    "translation",
+   "gameplay",
}
```

In the `_LoadModInfo` function, uncomment this whole section (remove the `~` too)

```lua
--~ local print_atlas_warning = true
--~ if info.icon_atlas ~= nil and info.icon ~= nil and info.icon_atlas ~= "" and info.icon ~= "" then
--~ 	local atlaspath = MODS_ROOT .. modname .. "/" .. info.icon_atlas
--~ 	local iconpath = string.gsub(atlaspath, "/[^/]*$", "") .. "/" .. info.icon
--~ 	if softresolvefilepath(atlaspath) and softresolvefilepath(iconpath) then
--~ 		info.icon_atlas = atlaspath
--~ 		info.iconpath = iconpath
--~ 	else
--~ 		-- This prevents malformed icon paths from crashing the game.
--~ 		if print_atlas_warning then
--~ 			TheLog.ch.Mods:print(
--~ 				string.format(
--~ 					'WARNING: icon paths for mod %s are not valid. Got icon_atlas="%s" and icon="%s".\nPlease ensure that these point to valid files in your mod folder, or else comment out those lines from your modinfo.lua.',
--~ 					self:GetModLogName(modname),
--~ 					info.icon_atlas,
--~ 					info.icon
--~ 				)
--~ 			)
--~ 			print_atlas_warning = false
--~ 		end
--~ 		info.icon_atlas = nil
--~ 		info.iconpath = nil
--~ 		info.icon = nil
--~ 	end
--~ else
--~ 	info.icon_atlas = nil
--~ 	info.iconpath = nil
--~ 	info.icon = nil
--~ end
```

Modify `IsModCompatibleWithMode` like shown below

```diff
function ModIndex:IsModCompatibleWithMode(modname, dlcmode)
+   dlcmode = "rotwood"
    local known_mod = self.savedata.known_mods[modname]
    if known_mod and known_mod.modinfo then
        return known_mod.modinfo.supports_mode[dlcmode]
    end
    return false
end
```

**NOTE:** I just made up that mode name because it works, definitely should not be a permanent solution.

Modify `IsModInitPrintEnabled`

```diff
function ModIndex:IsModInitPrintEnabled()
-   return self.modsettings.initdebugprint
+   return false -- prevent odd crash in modutil initprint
end
```

The modsettings section in ModIndex was removed, so let's add that back, first insert this function

```lua
function ModIndex:UpdateModSettings()

    self.modsettings = {
        forceenable = {},
        disablemods = true,
        localmodwarning = true
    }

    local function ForceEnableMod(modname)
        print("WARNING: Force-enabling mod '"..modname.."' from modsettings.lua! If you are not developing a mod, please use the in-game menu instead.")
        self.modsettings.forceenable[modname] = true
    end
    local function EnableModDebugPrint()
        self.modsettings.initdebugprint = true
    end
    local function EnableModError()
        self.modsettings.moderror = true
    end
    local function DisableModDisabling()
        self.modsettings.disablemods = false
    end
    local function DisableLocalModWarning()
        self.modsettings.localmodwarning = false
    end
    
    local env = {
        ForceEnableMod = ForceEnableMod,
        EnableModDebugPrint = EnableModDebugPrint,
        EnableModError = EnableModError,
        DisableModDisabling = DisableModDisabling,
        DisableLocalModWarning = DisableLocalModWarning,
        print = print,
    }

    local filename = MODS_ROOT.."modsettings.lua"
    local fn = kleiloadlua( filename )
    if fn == nil then
        print("could not load modsettings: "..filename)
        print("Warning: You may want to try reinstalling the game if you need access to forcing mods on.")
    else    
        if type(fn)=="string" then
            error("Error loading modsettings:\n"..fn)
        end
        setfenv(fn, env)
        fn()
    end
end
```

Then add this line to the start of the `Load` function

```diff
function ModIndex:Load(cb)
+   self:UpdateModSettings()

    local filename = self:_GetModIndexFileName("config")
...
```

#### ModWrangler

In `mods.lua`, comment these lines from the `CreateEnvironment` function

```lua
require("map/lockandkey")
```

```lua
GROUND = GROUND,
LOCKS = LOCKS,
KEYS = KEYS,
```

Then also comment this line from the `LoadMods` function

```lua
self:DisableAllServerMods()
```

Modify `runmodfn` like shown below

```diff
local runmodfn = function(fn, mod, modtype)
    return function(...)
+       local args = {...}
        if fn then
            local status, r = xpcall(function()
-               return fn(table.unpack(arg))
+               return fn(table.unpack(args))
            end, debug.traceback)
            if not status then
                TheLog.ch.Mods:print("error calling " .. modtype .. " in mod " .. ModInfoname(mod.modname) .. ": \n" .. r)
                ModManager:RemoveBadMod(mod.modname, r)
                ModManager:DisplayBadMods()
            else
                return r
            end
        end
    end
end
```

Modify this one line in `InitializeModMain` like below

```diff
...
if status == false then
-   moderror("Mod: " .. ModInfoname(modname), "  Error loading mod!\n" .. r .. "\n")
+   TheLog.ch.Mods:print("Mod: " .. ModInfoname(modname), "  Error loading mod!\n" .. r .. "\n")
    table.insert(self.failedmods, { name = modname, error = r })
    return false
else
    -- the env is an "out reference" so we're done here.
    return true
end
...
```

#### ModWarningScreen

The built-in mod warning screen that shows up when you start the game with mods is broken because most of its code was taken straight from DST and hasn't been updated to work with Rotwood.

Replace `screens/modwarningscreen.lua` with the `modwarningscreen.lua` file from the `src` folder in this repository (can also copy-paste the whole file contents).

There will be some missing strings that the screen needs, for your convenience, I made this snippet that you can just add to the end of `strings/strings.lua`

```lua
STRINGS.UI.MAINSCREEN.MODTITLE = "Mods Installed!"
STRINGS.UI.MAINSCREEN.NEWMODDETAIL = "Newly installed mods: "
STRINGS.UI.MAINSCREEN.MODDETAIL = "Installed mods: "
STRINGS.UI.MAINSCREEN.MODDETAIL2 = "Klei is not able to help you should issues arise while using mods. Use with caution!"
STRINGS.UI.MAINSCREEN.TESTINGYES = "I understand."
STRINGS.UI.MAINSCREEN.FORCEMODDETAIL = "You are force loading these mods from modsettings.lua. They will always be enabled:"
STRINGS.UI.MAINSCREEN.MODFORUMS = "Mod Forums"
STRINGS.UI.MAINSCREEN.MODSBADTITLE = "All Mods Disabled"
STRINGS.UI.MAINSCREEN.FAILEDMODS = "The following mods failed to run last time and have been disabled: "
STRINGS.UI.MAINSCREEN.MODSBADLOAD = "The game did not start correctly last time. This was likely caused by a mod, so all client mods have been disabled.\n\nYou can try re-enabling mods from the mod settings screen."
STRINGS.UI.MAINSCREEN.MODQUIT = "Disable Mods"
STRINGS.UI.MAINSCREEN.MODFAILDETAIL = "The following mod(s) have caused a failure:"
STRINGS.UI.MAINSCREEN.MODFAILDETAIL2 = "The mod will be disabled, re-enable it from the mods menu."
```

#### Implement PostInit function calls

##### SimPostInit

In `gamelogic.lua`, add this line below `if TheFrontEnd.error_widget == nil then` in the `OnAllPlayersReady` function

```lua
ModManager:SimPostInit()
```

##### ComponentPostInit

In `entityscript.lua`, add this right above `return cmp` in the `AddComponent` function

```lua
local postinitfns = ModManager:GetPostInitFns("ComponentPostInit", name)

for _, fn in ipairs(postinitfns) do
    fn(cmp, self)
end
```

##### PrefabPostInit and PrefabPostInitAny

In `mainfunctions.lua`, right above `TheGlobalInstance:PushEvent("entity_spawned", inst)` in the `SpawnPrefabFromSim` function, add this

```lua
local modfns = modprefabinitfns[inst.prefab or name]
if modfns ~= nil then
    for k,mod in pairs(modfns) do
        mod(inst)
    end
end
if inst.prefab ~= name then
    modfns = modprefabinitfns[name]
    if modfns ~= nil then
        for k,mod in pairs(modfns) do
            mod(inst)
        end
    end
end

for k,prefabpostinitany in pairs(ModManager:GetPostInitFns("PrefabPostInitAny")) do
    prefabpostinitany(inst)
end
```

#### Allow resolving file paths for .png images

In `util.lua`, modify the `GetAtlasTex` function like below

```diff
function GetAtlasTex(atlas_tex, tex)
    local istex = atlas_tex:find(".tex",1,true)
+   local ispng = atlas_tex:find(".png",1,true)
    if istex then
        local index1 = string.find(atlas_tex, "/", 1, true)
        if not index1 then
            return atlas_tex, "", true
        end
        local index2 = string.find(atlas_tex, "/", index1 + 1, true)
        if not index2 then
            return atlas_tex, "", true
        end
        local atlas = atlas_tex:sub(1,index2-1)..".xml"
        tex = atlas_tex:sub(index2+1)
        return atlas,tex,true
+   elseif ispng then
+       return atlas_tex, "", true
    else
        return atlas_tex, "", false
    end
end
```

This allows the game to find .png files from outside of default search paths (like when you load an image from your own mod's directory).

#### Note For Contributors

I'd also really appreciate if you contribute patch files to this repo, here's the general setup I use to generate them:

```txt
patch_root/
├─ scripts/
├─ scripts_modified/
```

- Have a directory containing `scripts/` (original scripts), and `scripts_modified/` (duplicated from `scripts/`)
- Make changes in `scripts_modified/`
- From `patch_root`, run `diff -ruN scripts scripts_modified > REV.patch`

## Debugging Mods

### Dev Tools

See [Enabling dev tools](https://github.com/zgibberish/rotwood-mods/blob/main/docs/enabling_devtools.md).

### modsettings.lua

Utilizing `modsettings.lua` is very helpful when debugging mods, or runnig modded Rotwood in general. Just create a file named `modsettings.lua` in your `mods/` directory.

There are a few functions you can call in `modsettings.lua`, see the snippet below (copied from DST's built in `modsettings.lua`)

```lua
--ForceEnableMod("kioskmode_dst")

-- Use "EnableModDebugPrint()" to show extra information during startup.

--EnableModDebugPrint()

-- Use "EnableModError()" to make the game more strict and crash on bad mod practices.

--EnableModError()

-- Use "DisableModDisabling()" to make the game stop disabling your mods when the game crashes

--DisableModDisabling()

-- Use "DisableLocalModWarning()" to make the game stop warning you when enabling local mods.

--DisableLocalModWarning()
```

## Mod Menu

I also made a mod that adds a "Mods" page to the game's options screen, to let you more easily see and manage installed mods without going through the console.

Although not required, I highly recommend alwayus having this mod if you play modded.

See [Mod Menu](https://github.com/zgibberish/rotwood-modmenu).

**Note:** Although advised not to by Klei in DST's `modsettings.lua`, you should actually force load Mod Menu to always have it available when using mods in Rotwood, since the game doesn't have a built-in mod settings page. Add this to your `modsettings.lua`

```lua
ForceEnableMod("rotwood-modmenu")
```

## Breaking Changes

### Migration from API v10 to API v1

#### modinfo

`modinfo` now needs to return its properties as a table, the format is roughly still the same with a few changes:

- You need to provide both `version` and `mod_version`, they can be the same value, because the new ModIndex reads version number from the updated `mod_version`, while ModWrangler still uses `version`.
- The `mod_type` property
  - Translation mods (officially supported) will use the `"translation"` mod type
  - For other mods, use the `"gameplay"` mod type
- The `supports_mode` table (see example API v1 modinfo below)
- `api_version` needs to be `1`
- `*_compatible` properties are no longer used and you can omit them completely

So for example, an older modinfo

```lua
name = "gbtestmod"
description = "gah"
author = "gibberish"
version = "dev"
api_version = 10

client_only_mod = true
all_clients_require_mod = false

icon_atlas = "modicon.png"
icon = "modicon.png"
```

Would now look like this

```lua
return {
    name = "gbtestmod",
    description = "gah",
    author = "gibberish",
    version = "dev",
    mod_version = "dev",
    api_version = 1,
    mod_type = "gameplay",
    supports_mode = {
        rotwood = true,
    },

    client_only_mod = true,
    all_clients_require_mod = false,

    icon_atlas = "modicon.png",
    icon = "modicon.png",
}
```

**NOTE:** You can see the sample translation mod now included with Rotwood's game files (samplemods.zip) for more details.

#### ModIndex functinos

If you use functions from ModIndex, you should read through the new ModIndex script for breaking changes like moved/renamed functions. There's too many changes to list here but I'll just give a few examples:

- `Enable` renamed to `EnableMod`
- `Disable` renamed to `DisableMod`
- `GetClientModNames` removed

## Thanks For Reading

If you followed all the steps above correctly, your game should be patched and ready to load mods.

Place mods in the `mods/` folder in Rotwood's save files path (`C:\Users\username\AppData/Roaming/Klei/Rotwood/steam-xxx/`), note that this is not inside the game files folder, but in `AppData`. You must create this folder yourself if it doesn't exist.

**NOTE:** Replace `Rotwood` with `Rotwood_preview` for beta save files.

```txt
AppData/
├─ Roaming/
│  ├─ Klei/
│  │  ├─ Rotwood/
│  │  │  ├─ steam-xxx/
│  │  │  │  ├─ Agreements/
│  │  │  │  ├─ cache/
│  │  │  │  ├─ backup/
│  │  │  │  ├─ feedback/
│  │  │  │  ├─ mods/
│  │  │  │  │  ├─ modmenu/
│  │  │  │  │  ├─ stackable-mammimal-howl/
│  │  │  │  ├─ saves/
│  │  │  │  ├─ client_log.txt
```

Rotwood mods are run in their own mod environments and work very similarly to DST mods.

The `mods/` directory containing your mods will persist through game updates, but edits you've made to game scripts won't, so you'll have to patch your scripts again after every update if you want to continue using mods.
