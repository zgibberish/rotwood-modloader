# Rotwood Modloader

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

```lua
MODS_ENABLED = true
```

Near the end of `main.lua` there are these lines

```lua
--#V2C no mods for now... deal with this later T_T
assert(false)
```

Comment the `assert(false)` line.

Add this right below `--#V2C no mods for now... deal with this later T_T` in the `ModSafeStartup` function

```lua
-- newly installed mods behave incorrectly so just go thorugh and
-- disable all new mods and save modindex so the game can properly
-- register them
for _,modname in ipairs(TheSim:GetModDirectoryNames()) do
    if KnownModIndex.savedata and KnownModIndex.savedata.known_mods and KnownModIndex.savedata.known_mods[modname] then  
        if KnownModIndex.savedata.known_mods[modname].enabled == nil then
            KnownModIndex:Disable(modname)
        end
    end
end
KnownModIndex:Save()
ModManager:LoadMods()
```

#### Fix modutil

In `modutil.lua`, comment these lines

```lua
env.Ingredient = Ingredient
```

```lua
env.MOD_RPC = MOD_RPC --legacy, mods should use GetModRPC below
```

#### Fix ModIndex

ModIndex by default will filter out all mods that don't specify `dst_compatible = true` in `modinfo.lua`. Obviously, Rotwood mods are not DST mods so this will not work.

In `modindex.lua`, modify `IsModCompatibleWithMode` like shown below

```diff
function ModIndex:IsModCompatibleWithMode(modname, dlcmode)
    local known_mod = self.savedata.known_mods[modname]
    if known_mod and known_mod.modinfo then
-       return known_mod.modinfo.dst_compatible
+       return known_mod.modinfo.rotwood_compatible
    end
    return false
end
```

The variable `rotwood_compatible` isn't actually used anywhere else in Rotwood, I just decided to use that name so Rotwood mods can be more easily differentiated from ds(t) mods.

#### Fix ModWrangler

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
local runmodfn = function(fn,mod,modtype)
    return (function(...)
+       local args = {...}
        if fn then
-           local status, r = xpcall( function() return fn(table.unpack(arg)) end, debug.traceback)
+           local status, r = xpcall( function() return fn(table.unpack(args)) end, debug.traceback)
            if not status then
                print("error calling "..modtype.." in mod "..ModInfoname(mod.modname)..": \n"..r)
                ModManager:RemoveBadMod(mod.modname,r)
                ModManager:DisplayBadMods()
            else
                return r
            end
        end
    end)
end
```

#### Fix ModWarningScreen

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

## Possible Breaking Changes

If you've just recently switched from the old modloader to this version, there are a few notable differences and some outdated mods may need to be updated to work with ModWrangler.

For example, janky hacks used to execute functions on init may not work anymore since ModWrangler initializes mods a bit differently (more similar to DST). Besides, they're no longer needed since we have post init fns now.

`GetModConfigData(name, true)` is no longer needed, that issue is fixed when switching over to ModWrangler now, just do `GetModConfigData(name)`.

You now need to have `rotwood_compatible = true` in your `modinfo.lua` so your mod doesn't get filtered out by ModIndex.

## Thanks For Reading

If you followed all the steps above correctly, your game should be patched and ready to load mods. You'll need to create a `mods/` folder in the game directory yourself.

```shell
Rotwood/
├─ bin/
│  ├─ ...
├─ data/
│  ├─ licenses/
│  ├─ scripts/
│  ├─ ...
├─ localizations/
├─ mods/
│  ├─ modmenu/
│  │  ├─ images/
│  │  ├─ img/
│  │  ├─ scripts/
│  │  ├─ LICENSE
│  │  ├─ modicon.png
│  │  ├─ modinfo.lua
│  │  ├─ modmain.lua
│  │  ├─ README.md
│  ├─ stackable-mammimal-howl/
│  │  ├─ modicon.png
│  │  ├─ modinfo.lua
│  │  ├─ modmain.lua
│  ├─ ...
├─ data.zip
├─ ...
```

Rotwood mods are run in their own mod environments and work very similarly to DST mods.

The `mods/` directory containing your mods will persist through game updates, but edits you've made to game scripts won't, so you'll have to patch your scripts again after every update if you want to continue using mods.
