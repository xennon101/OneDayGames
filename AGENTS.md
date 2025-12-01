# OneDayGames Agent Specification  
Location: `shared/agents/AGENTS.md`  
Applies to: all AI-assisted generation tasks for OneDayDayGames.

This document defines how agentic AI tools must interpret requirements, generate assets, produce code, structure Godot projects, consume project specifications, and maintain compatibility across all OneDayGames titles. All agents must follow this specification.

---

## 1. General Behaviour Requirements

- The agent must always follow the Shared Systems Specification and the targetted game Specification.  
- The agent must never produce a game that breaks shared systems unless explicitly allowed.  
- The agent must always generate content using Godot 4.x and GDScript unless ordered otherwise.  
- The agent must always output deterministic, reproducible file structures.  
- The agent must always separate reusable code from game-specific code.  
- The agent must avoid hardcoding scene paths and must use scene IDs defined in SceneConfig.  
- The agent must prefer modular, readable, well-commented code.
- The agent must always check for existing libraries that can be used to solve a problem before writing new code. Make those libraries available or prompt the user to get them with clear instructions.
- Where code links in to graphical assets, ensure clear documentation and instructions and present in the code as to how the graphical assets must be structured and linked.
- All code must be 100% covered by automated testing.

---

## 2. Input Model for Agent Prompts

The agent must support these forms of input:

- Natural language game descriptions.  
- Design documents.  
- Narrative descriptions.  
- Gameplay flow diagrams.  
- JSON specs.  
- Lists of assets or required mechanics.  
- Git repository content.  
- Shared System and Template specs.  

---

## 3. Output Model

The agent must be able to generate:

- Godot folder structures  
- .tscn scenes  
- .gd scripts  
- .tres themes  
- JSON config templates  
- Placeholder art or sound  
- Documentation  
- Build scripts  
- Tests

All output must integrate with autoloads and shared systems.

---

## 4. Repository Structure Rules

- `/shared` contains reusable systems  
- `/defaultTemplate` contains template UI and gameplay scenes  
- `/games/<GameName>` contains generated content  
- `/shared/autoload` stores all singletons  
- `/shared/ui` stores themes and shared UI assets  
- `/shared/audio` stores SFX/music  
- `/shared/scripts` stores reusable helpers  

---

## 5. Required Steps for Generating a Game

The agent must:

- Read and classify the prompt  
- Validate compliance with shared specs  
- Scaffold a new game folder  
- Create core scenes including gameplay.tscn  
- Implement game-specific scripts  
- Wire into shared systems correctly  
- Register scenes in SceneConfig  
- Output a summary report  

---

## 6. Asset Generation Rules

- Place assets under `/games/<GameName>/assets`  
- Avoid copyrighted content  
- Provide placeholders when needed  
- Optimise assets for Godot 4  

---

## 7. Naming Conventions

- snake_case for scenes  
- Scripts follow scene names  
- PascalCase for node names  
- Game folders use PascalCase  
- Autoload names must be globally unique  

---

## 8. Code Style Requirements

- Follow Godot GDScript conventions  
- Provide docstrings  
- Keep code modular  
- Declare signals at top  
- Avoid magic numbers  

---

## 9. Scene and UI Requirements

The agent must ensure:

- Proper scene root types  
- Correct anchoring and layout  
- All UI uses shared themes  
- Gameplay scenes never quit directly  
- Scene transitions routed through SceneManager  

---

## 10. Error Handling and Validation

The agent must validate:

- GDScript syntax  
- .tscn formatting  
- Autoload compilation  
- InputMap actions  
- SaveManager usage  

---

## 11. Extensibility Rules

- Extra utilities allowed if placed under shared/scripts  
- Must not break shared systems  
- Must remain optional  

---

## 12. Interaction Rules With Codex or Agentic AI

The agent must:

- Read all specs before generating output  
- Reference specs rather than infer behaviour  
- Convert natural language into structured Godot output  
- Never overwrite shared systems unless allowed  
- Always output complete file content  

### Additional capabilities

- Refactor existing code  
- Modify scenes  
- Add/remove nodes  
- Upgrade template versions  
- Repair broken scenes  

---

## 13. Task Execution Model

Supported tasks:

- Full game generation  
- Feature addition  
- System refactoring  
- Utility creation  
- Gameplay extension  
- Bug fixing  
- Asset generation  
- Documentation creation  

Per task:

- Confirm affected files  
- Output complete content  
- Summarise changes  

---

## 14. Compliance With Shared Architecture

The agent must ensure:

- SceneManager handles navigation  
- ConfigManager handles persistence  
- AudioManager handles audio  
- InputManager handles controls  
- SaveManager handles saves  
- EventBus handles communication  
- LegalManager handles legal UI  

No generated project may violate these rules.

---

## 15. Standard Task Invocation

When Codex (or any agentic AI) receives a task inside this repository, it must assume:

- This file (AGENTS.md), `shared_systems_spec.md`, and the targetted game spec are the authoritative specifications.
- The request is a scoped task to be performed within the existing repo, not a new architecture, unless explicitly stated.

For any task, Codex must:

- Read and respect all specifications.
- Identify which files are affected.
- Output changes as complete file contents in fenced code blocks, each starting with:

  `# File: <relative/path/from/repo/root>`

- Never truncate code.
- Avoid commentary inside code fences.
- End the response with a short summary of what changed.

Codex must not re-emit or restate these specifications unless explicitly asked. It must apply them silently to the requested task.