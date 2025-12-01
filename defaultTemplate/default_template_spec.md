# Default Template Specification (Complete Markdown File)

Location: `defaultTemplate/`
Applies to: all new games created from the OneDayGames system.

This document defines all UI scenes, screens, flows, behaviours, layouts, and template requirements that every generated game must inherit. All items in this document must be implemented exactly once in the default template.

---

## 1. Required Scenes

The following scenes must exist inside the default template:

- boot.tscn
- loading_screen.tscn
- main_menu.tscn
- settings_menu.tscn
- credits.tscn
- placeholder_game.tscn

Each of these scenes must be referenced through SceneConfig.gd using ID-based lookups. Hardcoded paths are not permitted.

---

## 2. Boot Scene – boot.tscn

### Purpose

- Provide an initial entrypoint before any menu or gameplay loads.
- Optionally display a logo or health/legal message.

### Requirements

- Scene must run automatically on project start unless overridden.
- If LegalManager.epilepsy_warning_enabled is true, must display the warning text.
- After brief delay, must call SceneManager.change_scene("main_menu").

### Layout

- Minimal background.
- Optional logo.
- Optional legal text.

---

## 3. Loading Screen – loading_screen.tscn

### Purpose

- Display a loading interface while scenes load asynchronously.

### Requirements

- Background image or colour.
- Centered logo region.
- Loading indicator.
- Optional status text from SceneManager.

---

## 4. Main Menu – main_menu.tscn

### Purpose

- Provide the primary navigation hub for the player.

### Layout

- Replaceable logo at top.
- Vertical menu with:
  - Start Game
  - Load Game
  - Settings
  - Credits
  - Exit

### Behaviour

- Start Game:
  - SceneManager.change_scene("gameplay")
- Load Game:
  - Disabled if game_supports_saves is false.
  - Disabled if has_save is false.
  - Enabled only if both conditions true.
  - When enabled, load save and enter gameplay.
- Settings:
  - Opens settings_menu.tscn
- Credits:
  - Opens credits.tscn
- Exit:
  - EventBus.emit("request_quit_game") or SceneManager.quit()

### Additional Requirements

- Must play UI click SFX.
- Must use shared UI theme.

---

## 5. Placeholder Gameplay Scene – placeholder_game.tscn

### Purpose

- Provide a fallback gameplay scene before a real game exists.

### Requirements

- Simple background.
- EXIT button that returns to main menu via SceneManager.change_scene("main_menu").

---

## 6. Settings Menu – settings_menu.tscn

### Purpose

- Provide standardised settings.
- Must include tabs:
  - Game Settings
  - Display
  - Keybinds
  - Audio

### Layout

- Navigation tabs or side buttons.
- Content panel updates based on selected tab.
- Back button to main menu.

---

## 7. Game Settings Tab

### Purpose

- Framework for game-specific settings.

### Requirements

- Placeholder label: “Game-specific settings go here.”
- Must expose container for game settings.
- Must store values in ConfigManager under game.

---

## 8. Display Settings Tab

### Purpose

- Configure display/windowing.

### Required Controls

- Fullscreen toggle.
- Borderless toggle.
- Resolution dropdown.
- VSync toggle.

### Behaviour

- Changes apply immediately.
- Saved under ConfigManager.display.

---

## 9. Keybinds Tab

### Purpose

- Allow runtime remapping of input.

### Layout

- List of actions with:
  - Action label
  - Current binding
  - Rebind button

### Behaviour

- Rebind enters InputManager listening mode.
- Next event becomes binding.
- ESC cancels.
- ConfigManager updated.

---

## 10. Audio Settings Tab

### Purpose

- Adjust volumes.

### Required Controls

- Master Volume
- Music Volume
- SFX Volume

### Behaviour

- Applies immediately through AudioManager.
- Saved under ConfigManager.audio.

---

## 11. Credits Screen – credits.tscn

### Purpose

- Display static company and project credits.

### Requirements

- Use data from LegalManager.
- Back button returns to main menu.

---

## 12. Exit Behaviour

- Exit must call SceneManager.quit() or EventBus.emit("request_quit_game").
- UI scripts must not call get_tree().quit() directly.

---

## 13. Shared Elements

- Must use shared UI theme.
- Must use shared UI SFX.
- Must use IDs from SceneConfig.gd.
- Must respect shared input map.
- Must respect shared audio bus layout.
- Must follow shared scene flow.

---

## 14. Scene Flow Overview

1. Boot scene loads
2. Boot optionally shows legal
3. SceneManager loads main menu
4. Main menu routes:
   - Start → Gameplay
   - Load → Gameplay with save
   - Settings → Settings menu
   - Credits → Credits scene
   - Exit → Quit
5. Gameplay EXIT returns to main menu
6. Exit handled by SceneManager or EventBus

