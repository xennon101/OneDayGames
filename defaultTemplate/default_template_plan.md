# Default Template New Functionality Plan

Plan for delivering the remaining items in `default_template_spec.md` (including the new configuration-driven assets, display/keybind/audio behaviours, and credits additions), following AGENTS.md and shared_systems_spec.md. Existing scenes, theme usage, scene IDs, boot flow, and baseline settings/display/input/audio plumbing are already in place; gaps are noted below.

## Current State vs Spec
- Required scenes exist and route via SceneManager IDs; boot shows epilepsy warning when enabled and hands off to main_menu.
- Logos/game/company assets are hardcoded labels; no configurable assets for boot/loading/main_menu/credits, no fallback logic beyond text.
- Legal/copyright boilerplate is not displayed as footnotes.
- Main menu covers navigation and save gating, but no UI click SFX is triggered and logo requirements are unmet.
- Loading screen is static (label/progress set in the scene), with no status/progress updates coming from SceneManager and no configurable game logo.
- Settings menu tabs exist; Display/Audio/Keybinds persist via ConfigManager/InputManager/AudioManager, but:
  - Game tab is only a placeholder and does not persist under `ConfigManager.game` or expose an extension point.
  - Display resolutions are a fixed list and lack apply/revert confirmation.
  - Keybinds are built from code defaults, not a configuration file; spec calls for config-defined actions (blank allowed) and defaults.
  - Audio sliders use 0-1 values and AudioManager does not enforce hierarchical master/music/sfx attenuation or asset tagging.
- Credits do not use configurable company/game logos, updated text, or the OneDayGames mission note.

## Work Plan
1) Config files and asset configuration
   - Add configuration files for template assets and bindings (e.g., `defaultTemplate/config/template_assets.json` for company/game logos and legal footers; `defaultTemplate/config/input_actions.json` for bindable commands/defaults; optional audio registry for asset tags).
   - Extend ConfigManager (or a lightweight loader) to read these template configs at startup and expose them to scenes/autoloads without hardcoding paths.
   - Ensure deterministic defaults: if files are missing/empty, use text fallbacks and empty keybind lists.

2) Logo and legal presentation (boot/main menu/loading/credits)
   - Boot: load configurable company logo; fallback to "OneDayGames" text if missing; add copyright/legal footnote from config/legal manager.
   - Loading screen: show configurable game logo (fallback to game title text); keep status/progress region.
   - Main menu: reuse company logo (boot) and game logo (loading) per spec; ensure shared layout supports both.
   - Credits: reuse company/game logos; update text to new credits content and include OneDayGames mission statement as required.

3) Legal footnotes
   - Add footer areas to relevant scenes (boot, loading, main menu, credits as needed) to display copyright and legal boilerplate pulled from LegalManager/config; fall back gracefully when absent.

4) UI click SFX
   - Add placeholder UI click asset under `defaultTemplate/assets/audio/` (or reuse shared stub) and register it with AudioManager on startup.
   - Wire main menu, back/exit buttons, and other navigation buttons to invoke `AudioManager.play_sfx("ui_click")` with null-safe fallback.

5) Loading screen status/progress
   - Add script to `loading_screen.tscn` with setters for status text and progress plus optional logo swapping.
   - Extend SceneManager threaded loading loop to poll progress and push status/progress into the loading screen instance, starting with "Loading <id>..." or similar.

6) Display settings rework
   - Populate resolution dropdown dynamically from `DisplayServer` capabilities; select current resolution.
   - Add Apply button: when pressed, apply all display settings, show a 15-second confirmation popup with "Keep/Revert"; auto-revert after timeout if not kept.
   - Persist chosen settings via ConfigManager only when kept; revert uses prior cached settings.

7) Keybinds from configuration
   - Load bindable actions and default events from `defaultTemplate/config/input_actions.json`; allow the list to be empty (UI shows blank).
   - Update InputManager to build defaults from the config file and expose them to the settings menu.
   - Ensure rebind flow still saves to ConfigManager and applies immediately.

8) Audio sliders and tagging
   - Update sliders to display 0-100 handles; map to 0.0-1.0 internally.
   - Adjust AudioManager volume application to use hierarchical attenuation (master * music/sfx), so 50% master + 50% sfx yields 25% effective sfx volume.
   - Introduce tagging of audio assets (music vs sound) in the registry/config, and ensure volume updates respect the tags.

9) Game Settings tab persistence and extensibility
   - Expose Game tab container via script for downstream games to inject controls.
   - Add a placeholder control demonstrating read/write under `ConfigManager.game` to validate persistence.
   - Provide helpers to load/save game settings consistently.

10) Tests and docs
   - Expand `defaultTemplate/tests` to cover: logo/config fallbacks, UI click SFX invocation, loading screen status/progress updates, dynamic resolutions and apply/revert timer, config-driven keybind list (including empty list), audio hierarchy math and tagging, and Game tab persistence.
   - Update README/usage notes to document new configs (asset/logo, keybind definitions, audio tags), loading screen API, display apply/revert flow, and how to inject game-specific settings controls.
   - Ensure tests assert: every scene transition via SceneManager (boot -> main_menu -> settings/credits/gameplay/back), all controls wired (buttons, sliders, apply/revert dialog), expected wording/legal footers from configuration, logo fallbacks when assets missing, and config-driven defaults for keybinds/audio/display/game settings.

## Expected Touchpoints
- Scenes/scripts: `boot.tscn/.gd`, `loading_screen.tscn` (+ new script), `main_menu.tscn/.gd`, `settings_menu.tscn/.gd`, `credits.tscn/.gd`, `placeholder_game.gd` (button SFX).
- Config/assets: new JSON config files under `defaultTemplate/config/`, placeholder UI click audio under `defaultTemplate/assets/audio/`, optional sample logo placeholders.
- Shared/autoload modifications required:
  - `shared/autoload/ConfigManager.gd`: load new template config files (assets/logos/legal, input actions, audio tags) with safe defaults; expose accessors used by scenes/autoloads.
  - `shared/autoload/InputManager.gd`: consume config-defined actions/default bindings instead of hardcoded dictionary; handle empty action list gracefully.
  - `shared/autoload/AudioManager.gd`: support hierarchical master/music/sfx volume application and per-asset tagging (music vs sound) from registry/config.
  - `shared/autoload/SceneManager.gd`: emit loading status/progress into loading screen script instance while maintaining existing async behaviour.
  - `shared/autoload/LegalManager.gd` (if needed): surface footer text/legal strings if not already present, or ingest from new template config.
- Tests: additions under `defaultTemplate/tests/` to keep coverage aligned with the new behaviours and 100% mandate.
