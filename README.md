# Buffadin

**Buffadin** is a modern Paladin blessing and aura manager built from the ground up for **World of Warcraft: Forever** (and modern Classic+ clients running on engine 1.60.x / Dragonflight / The War Within).

Inspired by classic blessing management workflows, Buffadin brings full assignment coordination, intuitive single-target overrides, and one-click buffing into a sleek, retail-inspired interface using native Blizzard UI templates.

---

## Features

- **Retail Aesthetic with Blizzard Native Templates**: Clean `ButtonFrameTemplate` windows with crisp borders, authentic circular spell portraits (`Interface\Icons\Spell_Magic_GreaterBlessingofKings`), and subtle dark backdrops.
- **Raid & Party Assignment Matrix**: Full Paladin assignment grid supporting all 10 classes and pets. Click cells to cycle assignments (Left-click forward, Right-click backward).
- **Single-Target Player Overrides**:
  - Slide-out **Overrides Drawer** in the manager (`/buffadin`) with **Quick Tank Presets** (`[Sanctuary]`, `[Might]`, `[Kings]`) to exempt tanks from Greater Salvation with a single click.
  - Interactive override buttons on the floating Buff Bar flyout for on-the-fly adjustment.
- **Smart Target & Auto-Buff Solver**:
  - Automatically casts class blessings first, and applies single-target overrides (e.g. Blessing of Sanctuary on the tank) directly after.
  - Automatically skips override units when casting class Greater Blessings so tanks don't get unwanted Salvation.
- **Dual Blessing Detection**:
  - Detects both **Greater Blessings** and **Normal Blessings**. In 5-man parties and lower levels where players cast 10-minute normal blessings, Buffadin tracks buff status and resets missing counters seamlessly.
- **Modern WoW Engine Architecture**:
  - Uses modern `C_Spell` and `C_UnitAuras` APIs with clean legacy fallbacks.
  - Full `InCombatLockdown()` protection: queues assignments and roster changes received in combat and applies them safely the instant combat drops (`PLAYER_REGEN_ENABLED`).
- **Flexible Permission Control**:
  - **Party & Solo**: Defaults to Free Assign mode so anyone can configure their own buffs without requiring party lead.
  - **Raid**: Enforces Raid Leader / Raid Assistant editing by default, with a toggleable Free Assign checkbox.

---

## Slash Commands

You can use either `/buffadin` or `/bf`:

| Command | Action |
| :--- | :--- |
| `/buffadin` or `/bf` | Toggle the Blessing Manager window |
| `/buffadin bar` | Toggle the floating Buff Bar |
| `/buffadin opt` | Open Settings & Options |
| `/buffadin auto` | Run the Auto-Assign algorithm |
| `/buffadin clear` | Clear all blessing assignments |
| `/buffadin report` | Broadcast current assignments to Raid/Party chat |
| `/buffadin reset` | Reset the Buff Bar position to screen center |

---

## Installation

Clone or download this repository directly into your World of Warcraft AddOns folder:

```bash
cd "World of Warcraft/_classic_beta_/Interface/AddOns"
git clone https://github.com/<your-username>/buffadin.git Buffadin
```

Ensure the folder is named `Buffadin` (or `buffadin`).

---

## License

MIT License. See `LICENSE` for details.
