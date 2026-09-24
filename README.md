<img width="150" height="150" alt="image" src="https://github.com/user-attachments/assets/4b2d31ac-559f-467b-86d8-f75f6a468494" />


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

**Smart Target & Auto-Buff Solver**

<img width="423" height="279" alt="image" src="https://github.com/user-attachments/assets/b62d8511-b900-44b6-95a7-a72a7cd938e1" />

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

Clone or download this repository directly into your World of Warcraft AddOns folder:

```bash
cd "World of Warcraft/_classic_beta_/Interface/AddOns"
git clone https://github.com/<your-username>/buffadin.git Buffadin
```

Ensure the folder is named `Buffadin` (or `buffadin`).

---

## License

MIT License. See `LICENSE` for details.
