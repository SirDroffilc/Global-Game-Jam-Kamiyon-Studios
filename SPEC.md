# Game Design Specification: Global Game Jam Project

## 1. Overview
*   **Title:** Global Game Jam (Project Name)
*   **Engine:** Godot 4.6 (Forward Plus)
*   **Genre:** 2D Action Platformer
*   **Core Theme:** Duality (Light vs. Dark)
*   **Language:** GDScript

## 2. Core Mechanics

### 2.1. Duality System
The game revolves around a duality mechanic where the player and the world have two states: **Light** and **Dark**.

*   **Player Elements:**
    *   **Light State:** Ranged Attack (Arrow), Collides with Light Objects (Layer 4) + Neutral.
    *   **Dark State:** Melee Attack, Collides with Dark Objects (Layer 3) + Neutral.
    *   **Toggle:** Controlled by Input `skill1` (default: Right Mouse Button).
*   **World Elements:**
    *   **Tile Swapping:** The world terrain can shift between Light and Dark variations.
    *   **Toggle:** Controlled by Input `skill2` (default: E key).
    *   **Implementation:** `TileMapLayer` iterates used cells and swaps tiles based on Custom Data (`element_type`).

### 2.2. Player System
*   **Architecture:** Finite State Machine (FSM).
*   **Script:** `scripts/players/player.gd`
*   **Global Manager:** `PlayerManager` (Autoload) handles persistence of stats (Health, Speed, Damage).
*   **Attributes:**
    *   Health: 100
    *   Speed: 170.0
    *   Jump Velocity: -300.0
    *   Base Damage: 10
*   **Physics Layers:**
    *   **Layer 1:** Dark Player
    *   **Layer 2:** Light Player
    *   **Layer 3:** Dark Object (Terrain/Platforms)
    *   **Layer 4:** Light Object (Terrain/Platforms)
    *   **Layer 5:** Neutral Object (Shared Terrain)
    *   **Layer 6:** Enemy Hurtbox

#### States
The player controller delegates logic to individual State nodes (`scripts/players/`):
*   **Idle**
*   **Run**
*   **Jump**
*   **Double Jump**
*   **Attack** (Melee - Dark Mode)
*   **Shoot** (Ranged - Light Mode)

### 2.3. Combat System
*   **Melee:** Active in Dark Mode. Uses an `Area2D` hitbox to detect `Enemy Hurtbox` (Layer 6).
*   **Ranged:** Active in Light Mode. Spawns `LightArrow` projectile (`scripts/light_arrow.gd`) towards mouse position.
*   **Damage:** Defined in `PlayerManager.base_damage`.
*   **Health:** `PlayerManager` emits `health_changed` and `player_died` signals.

### 2.4. Enemy System
*   **Script:** `scenes/enemies/enemy_1.gd`
*   **Behavior:** Basic gravity and physics processing.
*   **Interaction:**
    *   `take_damage(amount)`: Reduces health.
    *   `die()`: Called when health <= 0 (queues free).
*   **Attributes:**
    *   Base Health: 15

## 3. Input Map
| Action | Key/Button | Function |
| :--- | :--- | :--- |
| `move_left` | A / Left | Move Left |
| `move_right` | D / Right | Move Right |
| `jump` | Space / W | Jump |
| `attack` | Left Mouse | Melee (Dark) or Shoot (Light) |
| `skill1` | Right Mouse | Toggle Player Element (Light/Dark) |
| `skill2` | E | Toggle World Tiles (Light/Dark) |

## 4. Project Structure
*   **`assets/`**: Art and audio resources.
*   **`scenes/`**: `.tscn` files.
    *   `enemies/`: Enemy prefabs.
    *   `players/`: Player-related scenes.
    *   `stages/`: Level scenes.
    *   `MainScene.tscn`: Primary game loop entry.
    *   `SplashScreen.tscn`: Intro screen.
*   **`scripts/`**: `.gd` source files.
    *   `globals/`: Autoloads (`player_manager.gd`).
    *   `players/`: Player controller and states.
    *   `levels/`: Level logic (`tile_map_layer.gd`).

## 5. Development Guidelines
*   **Scripting:** All scripts must be written in **GDScript**.
*   **Code Style:**
    *   Use type hinting (`func foo() -> void:`, `var x: int`).
    *   Signals for decoupled events (e.g., Health changes).
    *   Composition over Inheritance (State Machine pattern).

## 6. Action Items / Missing Features
*   **Splash Screen:** Logic incomplete in `splash_screen.gd` (needs scene transition).
*   **Enemy AI:** Currently stationary/passive. Needs movement logic (patrol, chase).
*   **UI:** HUD for health/ammo is not yet fully defined in the file listing analysis.
