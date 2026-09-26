# Buffadin — Agent Instructions

Shared instructions for AI coding agents (Claude Code, Gemini CLI, etc.). `CLAUDE.md` and `GEMINI.md` import this file — edit **this** file, not those.

## What this is

Buffadin is a **World of Warcraft addon** (Lua 5.1, WoW FrameXML API) that manages Paladin blessings and auras for **WoW: Forever** (game version 1.60.x, interface `16001`/`16000`). Forever serves vanilla-era *content* on the modern **Retail/Mainline API**, including `C_*` namespaces and "secret value" combat restrictions. Don't assume Classic Era API behavior; see [WoW API reference](#wow-api-reference). It is a modern successor to PallyPower: an assignment matrix synced across the group, a floating secure-button bar for one-click casting, and a priority "auto-buff" solver.

- No build step, no dependencies, no embedded libraries (no Ace3/LibStub). Everything is hand-written against the raw WoW API.
- No automated test suite. Testing happens in-game (see [Testing](#testing)).
- Released to CurseForge + GitHub Releases by the BigWigs packager on tag push.

## Repository layout

```
Buffadin.toc          Addon manifest: metadata, SavedVariables, and FILE LOAD ORDER
Init.lua              Slash commands, event frame, DB init/migration, callback connectors (loads LAST)
Core/
  Compat.lua          Global namespace, Print/Debug, API compat layer, mock-aware unit adapters, combat queue
  Constants.lua       Classes, spell tables (blessings/auras/seals/RF), durations, DEFAULT_CONFIG
  Roster.lua          Group scan -> units/classes/paladins; CanEditAssignments() permission check
  BuffScanner.lua     Computes per-class/per-unit buff status; in-combat countdown; GetNextAutoBuff() solver
  Assignments.lua     Assignment data model, setters, AutoAssign, chat Report, addon-message sync protocol
UI/
  Theme.lua           Colors, time formatting, window/button/backdrop styling helpers
  BlessingsBar.lua    Floating bar of SecureActionButtons (class buttons + Auto/Aura/RF utility buttons)
  PlayerPopups.lua    Per-player secure popup buttons shown when hovering a class button
  ManagerFrame.lua    Assignment matrix window (paladin x class grid, aura row, overrides drawer)
  OptionsFrame.lua    Settings window
  MinimapButton.lua   Minimap icon
Dev/
  MockHarness.lua     In-game simulated party/raid + control panel (debug builds only)
pkgmeta.yaml          Packager ignore list
.github/workflows/publish.yml   Tag-triggered BigWigsMods/packager release
```

## Architecture

### Namespace and load order
- Every file starts with `local addonName, Buffadin = ...` — the private addon table shared by all files. `Compat.lua` also exposes it as the global `_G.Buffadin`.
- Modules are sub-tables: `Buffadin.Roster`, `Buffadin.BuffScanner`, `Buffadin.Assignments`, `Buffadin.Theme`, and frames `Buffadin.BlessingsBar`, `Buffadin.ManagerFrame`, etc. UI modules alias themselves locally (`local Bar = Buffadin.BlessingsBar`) and define methods with `function Bar:Method()`.
- **Load order is defined in `Buffadin.toc` and matters.** Files may reference earlier modules at file scope (e.g. `Roster.lua` iterates `Buffadin.CLASSES` at load). Later modules may only be referenced inside functions. When adding a file, add it to the `.toc` in the right position (paths use backslashes).
- `Init.lua` loads last and wires everything together.

### Lifecycle (`Init.lua`)
1. `ADDON_LOADED` → `InitDB()`, register comm prefixes.
2. `PLAYER_LOGIN` → `InitDB()` again (realm name is final), `Initialize()` every UI module, first roster/buff scan, request group sync, start a **1-second ticker** that runs `BuffScanner:Scan()` + `BlessingsBar:RefreshDisplay()`.
3. `GROUP_ROSTER_UPDATE`, `UNIT_AURA`, `SPELLS_CHANGED`, `PLAYER_REGEN_ENABLED/DISABLED`, `CHAT_MSG_ADDON` drive rescans and redraws.

Cross-module notification goes through two connector callbacks in `Init.lua`: `Buffadin:OnRosterUpdated()` and `Buffadin:OnAssignmentsChanged()`. Data modules call these; they don't reach into UI modules directly.

### Data flow
```
Roster:Update()  --(units/classes/paladins)-->  BuffScanner:Scan()  --(classStatus/unitStatus/selfStatus)-->  BlessingsBar / ManagerFrame / PlayerPopups
                                                     ^
Assignments (data / normalData / auraData) ----------+   <-- synced via addon messages
```

### SavedVariables (`BuffadinDB`)
- Per-character: `BuffadinDB.characters["Name - Realm"]` holds the profile. Runtime access is always `Buffadin.db.profile`.
- `BuffadinDB.profile` is a backwards-compat alias to the current character's profile. Migrations exist from legacy `PallyPowerForeverDB` and from the old unscoped `profile` — **don't break them**.
- Defaults come from `Buffadin.DEFAULT_CONFIG` in `Constants.lua` and are applied only when a key is `nil` (explicit `false` is preserved). **Add every new setting there.** Note that `debug` and `showPets` are read but currently have no default.
- Assignment tables are shared by reference between `Buffadin.Assignments.*` and the profile.

### Assignment data model
Keyed by paladin name, then class id (1–10 from `Buffadin.CLASSES`; 10 = pets):
- `data[pally][classId] = greaterIndex` (index into `GREATER_BLESSINGS`, 0 = none)
- `normalData[pally][classId][unitName] = normalIndex` (single-target override; into `NORMAL_BLESSINGS`)
- `auraData[pally] = auraIndex` (into `AURAS`)

Paladin names go through `Assignments:NormalizePaladinName()` so the local player is always the bare `UnitName("player")`; remote players may be `Name-Realm`. Always use the getters/setters rather than indexing the tables directly — they call `EnsurePaladin`, clamp ranges, check permissions, persist, broadcast, and fire `OnAssignmentsChanged`.

Setters take a trailing `skipSync` flag. Pass `true` when applying data received from the network or during bulk operations (then call `BroadcastFullSync()` once at the end, as `AutoAssign` does). `skipSync` also bypasses the permission check.

### Sync protocol (`Assignments.lua`)
Addon messages on prefix `BUFFADIN` (the legacy `PLPWR` prefix is registered but not handled). `;`-delimited:

| Message | Meaning |
| :--- | :--- |
| `REQ` | Request full sync; answered only by someone who `CanEditAssignments()` |
| `ASSIGN;pally;classId;idx` | Greater blessing for a class |
| `NORMAL;pally;classId;unitName;idx` | Single-target override |
| `AURA;pally;idx` | Aura assignment |
| `SYNC;pally;cid=idx,cid=idx,...;auraIdx` | Full state for one paladin |
| `FREEASSIGN;0\|1` | Toggle raid Free Assign mode |

Changing a message format breaks compatibility with other group members running older versions — add new commands instead of changing existing ones.

### Permissions
`Roster:CanEditAssignments()`: always true solo/party/mock; in raid true only if Free Assign is on, or the player is leader, assist, or tank. User-initiated setters and `Cycle*`/`ClearAll`/`AutoAssign` must respect this.

## Critical WoW constraints

These are the source of most bugs in this addon. Read before touching UI or scanning code.

1. **Combat lockdown / taint.** Secure frames (`SecureActionButtonTemplate`) can't be shown/hidden/moved/resized or have attributes changed via insecure code during combat. Rules:
   - Wrap layout or attribute changes in `Buffadin:RunOutOfCombat(fn, key)`. It runs immediately out of combat, otherwise queues until `PLAYER_REGEN_ENABLED`. Pass a stable `key` to de-duplicate (e.g. `"BlessingsBar_UpdateLayout"`).
   - `RefreshDisplay()` runs every second, in combat too. Only update textures, text, and colors there. Guard any `SetAttribute` with an in-combat check.
   - The Auto-Buff button uses a secure state driver (`RegisterStateDriver(..., "combat", ...)`) to clear its attributes when combat starts. Keep that pattern.
   - Close popups on `PLAYER_REGEN_DISABLED`.
2. **Auras can't be queried in combat on WoW: Forever**, and may return "secret" values. `BuffScanner:Scan()` switches to `UpdateInCombat()`, which counts down cached timers and tracks deaths/battle-rezzes without calling the aura API. All aura reads go through `Compat.lua` (`GetUnitBuffs`/`FindUnitBuff`), which wraps calls in `pcall` and checks `issecretvalue`. Don't call `C_UnitAuras`/`UnitAura` directly elsewhere.
3. **API differences.** Always call the compat wrappers (`Buffadin:GetSpellInfo/GetSpellName/GetSpellTexture/IsSpellKnown/IsUnitInRange/SendComm/RegisterComm/CreateBackdropFrame`). They try modern `C_*` APIs first and fall back to legacy globals. Check new calls against the `forever` branch docs (see [WoW API reference](#wow-api-reference)) before adding them.
4. **Lua 5.1.** No `goto`, no integer division `//`, no `utf8` lib, no bitwise operators. Use WoW-provided helpers (`strsplit`, `string.trim`, `CopyTable`, `C_Timer`) where the code already does.
5. **Localization.** Spells are matched by spell ID *and* by localized name. Casting attributes use the spell *name* from `GetSpellName`. Keep both paths working when adding spells.

## WoW API reference

Look up the real API before writing or changing a call. Don't guess signatures from memory. Forever's API differs from both Classic Era and current Retail.

### 1. Blizzard's UI source, `forever` branch (authoritative)
[Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) mirrors the UI code Blizzard ships with each client. The **`forever` branch** matches the WoW: Forever client (other branches like `live` and `classic_era` are different games). Key directories:
- `Interface/AddOns/Blizzard_APIDocumentationGenerated/*Documentation.lua`: machine-readable definitions for every API function, event, and enum: arguments, return values, nilability, and restriction flags such as `SecretWhenUnitAuraRestricted`, `RequiresUnitAuraAccess`, and `SecretArguments`. These flags tell you whether a call works in combat or returns secret values. Files are named by system (`UnitAuraDocumentation.lua`, `SpellDocumentation.lua`, `SpellBookDocumentation.lua`, `ChatInfoDocumentation.lua`, `Secret*Documentation.lua`, …).
- The rest of `Interface/AddOns/Blizzard_*`: Blizzard's own FrameXML Lua/XML. Use it to see how templates (`SecureActionButtonTemplate`, `ButtonFrameTemplate`, `BackdropTemplate`) and mixins actually behave.

Quick lookup of one system (no clone):
```sh
curl -s https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua \
  | grep -n -A15 'Name = "GetAuraDataByIndex"'
```

For repeated lookups, keep a sparse shallow clone **outside this repo** (about 7 MB) and grep it:
```sh
git clone --depth 1 --filter=blob:none --sparse -b forever https://github.com/Gethe/wow-ui-source.git ~/.cache/wow-ui-source
git -C ~/.cache/wow-ui-source sparse-checkout set Interface/AddOns/Blizzard_APIDocumentationGenerated
# add more Interface/AddOns/Blizzard_* dirs to the sparse set when you need FrameXML source
git -C ~/.cache/wow-ui-source pull   # refresh after a client patch
grep -rn 'Name = "IsSpellInRange"' ~/.cache/wow-ui-source/Interface
```
GitHub code search only indexes the default branch, so it **won't** find `forever`-only content. Use raw URLs or the local clone.

In-game, `/api` (Blizzard_APIDocumentation) browses the same data, e.g. `/api search aura`.

### 2. Warcraft Wiki (explanations and history)
[warcraft.wiki.gg/wiki/World_of_Warcraft_API](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) is the community reference (the successor to Wowpedia's API pages). Function pages are `https://warcraft.wiki.gg/wiki/API_<FunctionName>` (e.g. `API_C_UnitAuras.GetAuraDataByIndex`), events are `https://warcraft.wiki.gg/wiki/<EVENT_NAME>`, and widget methods are under `Widget_API`. Use it for prose explanations, usage examples, patch history, and concepts like [secure execution and tainting](https://warcraft.wiki.gg/wiki/Secure_Execution_and_Tainting). It documents Retail and Classic flavors, not Forever specifically, so check any Forever-sensitive detail against the `forever` branch.

### 3. Editor annotations (optional)
[Ketho/vscode-wow-api](https://github.com/Ketho/vscode-wow-api) supplies LuaLS type annotations generated from Blizzard's docs, giving autocomplete and diagnostics for the WoW API. It targets Mainline/Classic flavors, so treat it as a convenience, not the authority for Forever.

### Spell IDs
Spell IDs in `Constants.lua` must exist on the Forever client. Confirm with `SpellDocumentation.lua` (API shape) and in-game (`/dump C_Spell.GetSpellInfo(<id>)`). Database sites like Wowhead are useful for finding candidate IDs, but a Classic ID may not match Forever.

When the docs and the client disagree, the client wins. Keep the `pcall` + `issecretvalue` guards in `Compat.lua` and tell the user what to verify in-game.

## Mock harness (the test system)

`Dev/MockHarness.lua` simulates a SOLO/PARTY/RAID25/RAID40 group, buff states, combat, deaths and battle-rezzes, plus a control panel and event log. It's wrapped in `#@debug@ ... #@end-debug@` in the `.toc`, so the packager **strips it from releases**, and `Dev/` is ignored in `pkgmeta.yaml`/`.gitattributes`.

It works via an **adapter pattern**: the unit/aura/combat wrappers in `Compat.lua` check `Buffadin.MockHarness and Buffadin.MockHarness.active` and redirect to mock data. Consequences:
- **Production code must go through the `Buffadin:` wrappers** (`GetGroupMembers`, `GetUnitInfo`, `UnitExists`, `IsUnitDead`, `IsUnitConnected`, `IsUnitPlayer`, `IsInRaid`, `IsInGroup`, `InCombat`, `FindUnitBuff`, `IsSpellKnown`, `IsUnitInRange`). If you call raw `UnitExists`/`InCombatLockdown`/`IsInRaid`, the harness won't see it.
- Always guard harness references with `if Buffadin.MockHarness then` — it won't exist in release builds.
- In mock mode, secure buttons get `type = nil` (`isMock and nil or "spell"`) so no real casts happen; `Mock:HookButton` intercepts `PreClick` to simulate casts instead.
- If you add a new wrapper, button, or buff behavior, extend the harness too (`HookInteractiveButtons`, `GetUnitAura`, etc.).

## Testing

There is no headless test runner. The WoW API isn't available outside the client.

1. **Syntax check (always do this):**
   ```sh
   for f in $(git ls-files '*.lua'); do luac5.1 -p "$f" || echo "FAIL $f"; done
   ```
   (`luac5.1` is installed locally. Don't use `luac` 5.4+, which accepts syntax WoW rejects.)
2. **In-game (the user does this):** copy or symlink the repo to `Interface/AddOns/Buffadin`, `/reload`, then `/bf mock` (or `/bf mock party|raid25|raid|off`) to open the harness. Use its control panel to toggle combat, randomize missing buffs, expire buffs, simulate death/rez, and check the bar, popups, and manager. Enable Lua errors with `/console scriptErrors 1`.
3. When you can't verify behavior in-game, say so clearly and list what the user should check (especially combat transitions and taint).

## Conventions

- 4-space indent, `PascalCase` methods with `:` syntax, `camelCase` locals/fields, `UPPER_SNAKE` constants on `Buffadin`.
- Section headers use the `-- ====...` banner style found throughout. Match it.
- Named global frames use the `Buffadin_` / `Buffadin` prefix (e.g. `Buffadin_ClassBtn3`, `BuffadinBlessingsBar`).
- User-facing output goes through `Buffadin:Print()`; debug output uses `Buffadin:Debug()` (only shown when `db.profile.debug` is set).
- Color codes: `|cffRRGGBB...|r`; brand pink is `F58CBA`. Status colors live in `Theme.Colors` (`Good`/`Some`/`All`/`Special`/`Disabled`), and these names also appear as `BuffScanner.classStatus[].status`.
- Spell/blessing tables are 0-indexed with `[0] = None`; `MAX_*` constants bound the cycling.
- Keep slash commands in `Init.lua` in sync with the help text there and with the table in `README.md`.

## Versioning and release

- Version appears in **two places**: `## Version:` in `Buffadin.toc` and `Buffadin.version` in `Core/Compat.lua`. Bump both together (commit style: `chore: bump version to X.Y.Z`).
- Release = push an annotated tag `vX.Y.Z`. CI runs `BigWigsMods/packager@v2` and uploads to CurseForge (project `1710274`) and GitHub Releases. Only tag when the user asks.
- Anything dev-only must be excluded from the package: add it to `pkgmeta.yaml` `ignore:` and `.gitattributes` `export-ignore`, or wrap `.toc` entries in `#@debug@`.

## Git workflow

- Commit messages use Conventional Commits: `feat:`, `fix:`, `chore:`, `ci:`, `docs:`, `refactor:`, optional scope (`feat(mock):`, `fix(ui):`).
- Work on a feature branch and merge via PR into `main` (e.g. `fix/combat-buff-status`).
- The working tree often has uncommitted in-progress changes. Don't revert or reformat files you weren't asked to touch.

## Pitfalls checklist

- [ ] New file added to `Buffadin.toc` in the correct order?
- [ ] New setting added to `DEFAULT_CONFIG`?
- [ ] Any new or changed WoW API call checked against the `forever` branch of wow-ui-source (signature, nilability, combat/secret restrictions)?
- [ ] Secure-frame layout/attribute change guarded for combat (`RunOutOfCombat` / `InCombat()` check)?
- [ ] Used `Buffadin:` wrappers instead of raw unit/aura/combat APIs, so mock mode works?
- [ ] `MockHarness` references nil-guarded?
- [ ] Assignment change goes through a setter, with correct `skipSync` usage?
- [ ] Sync message format stays backward compatible?
- [ ] Every `.lua` file passes `luac5.1 -p`?
- [ ] Slash command help text and README updated if commands changed?
