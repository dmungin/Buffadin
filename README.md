<img width="150" height="150" alt="image" src="https://github.com/user-attachments/assets/e2a049d0-b32f-470b-aa31-f7c6cc992dc0" />



**Buffadin** is a modern Paladin blessing and aura manager built for **World of Warcraft: Forever**. It provides full assignment coordination, intuitive single-target overrides, and one-click buffing.

---

## Features

**Floating Blessing Bar**

<img width="509" height="72" alt="image" src="https://github.com/user-attachments/assets/b5ef04bb-5c35-41d9-aec6-8ccd2d1f71dc" />

**Raid & Party Assignment Matrix**

<img width="762" height="599" alt="image" src="https://github.com/user-attachments/assets/c1e2957e-e3a7-46ea-86d3-063f6dec85ee" />

**Single-Target Player Overrides**

<img width="311" height="592" alt="image" src="https://github.com/user-attachments/assets/611a730f-2aa6-42d1-b3db-44c6cae60385" />
<img width="814" height="498" alt="image" src="https://github.com/user-attachments/assets/18b9ff36-c2cc-4c70-9b5e-b2a63394ecc6" />

**Smart Target & Auto-Buff Solver (Out of Combat)**

<img width="423" height="279" alt="image" src="https://github.com/user-attachments/assets/b62d8511-b900-44b6-95a7-a72a7cd938e1" />

- Priority-based one-click buffing button that dynamically calculates and targets the next player needing a blessing (missing self-aura, class with the most missing buffs, expiring buffs, or custom single-target overrides).
- **Out of Combat Only**: Due to World of Warcraft's combat lockdown restrictions on secure action buttons, smart auto-targeting is strictly out of combat. During combat, the button is automatically disabled and greyed out to prevent mis-targeting. As soon as combat drops, the button immediately reactivates with the next optimal target.

**Flexible Permission Control**
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

### Option 1: CurseForge (Recommended)

Install and automatically manage updates via the CurseForge App or download directly from the web:
- **CurseForge**: [Buffadin on CurseForge](https://www.curseforge.com/wow/addons/buffadin)

### Option 2: Manual Installation

1. Download the latest release `.zip` from [GitHub Releases](https://github.com/dmungin/Buffadin/releases), or clone the repository:
   ```bash
   cd "World of Warcraft/_classic_beta_/Interface/AddOns"
   git clone https://github.com/dmungin/Buffadin.git Buffadin
   ```
2. Extract the archive into your `Interface/AddOns/` directory.
3. Ensure the folder is named `Buffadin` (e.g., `Interface/AddOns/Buffadin`).
4. Launch or restart World of Warcraft.

---

## License

MIT License. See `LICENSE` for details.
