# OneDayGames Agent Specification  
Location: `AGENTS.md`  
Applies to: all AI-assisted generation tasks for OneDayGames.

This document defines how agentic AI tools must interpret requirements, generate assets, produce code, and structure both Godot and AWS projects for the OneDayGames ecosystem. It distinguishes between:

- Godot tasks (games and shared Godot systems)
- AWS tasks (backend services, leaderboards, matchmaking, and other shared infrastructure)

It also defines shared rules that apply to all tasks.

---

## 1. General Behaviour Requirements (Shared)

- The agent must always follow:
  - `AGENTS.md` (this file)
  - `shared/shared_systems_spec.md`
  - particular game or aws project spec in the project folder.
  - Any game-specific spec files under `games/<GameName>/` that are explicitly referenced in the task.
  - Any AWS spec files under `aws/<ServiceName>/` that are explicitly referenced in the task.
- The agent must treat these specifications as authoritative. If code and spec disagree, the spec wins.
- The agent must not invent new architectures or patterns when clear guidance exists in the specs.
- The agent must always output deterministic, reproducible file structures.
- The agent must always separate reusable shared code from game-specific or service-specific code.
- The agent must not modify or overwrite shared systems unless explicitly instructed to do so.
- The agent must avoid introducing unnecessary dependencies.
- The agent must prefer modular, readable, well-commented code.
- The agent must not degrade existing behaviour without explicit instruction.

---

## 2. Shared Output Rules (All Tasks)

- All file changes must be returned as complete file contents, not diffs.
- Each file must be wrapped in a fenced code block.
- The first line inside the code block must be the repository-relative path in the form:

  `# File: <relative/path/from/repo/root>`

  Example:

  ```text
  # File: games/MyGame/scenes/gameplay.tscn
  <contents>
  ```

- The agent must:
  - Never truncate code.
  - Never write “... omitted” or similar.
  - Avoid commentary inside code fences.
  - Ensure all code fences are syntactically valid (matching ` ` ` delimiters).
- When multiple files are changed, each file must have its own block.
- At the end of the response, the agent must provide a short summary listing:
  - Each file created or modified.
  - The purpose of each change.

---

## 3. Shared Task Execution Model (All Tasks)

For any task, the agent must:

- Determine the task type:
  - Godot game feature
  - Godot shared system
  - AWS backend feature (Lambda, API, etc.)
  - AWS infrastructure or pipeline
- Identify which files are affected.
- Read relevant specs (shared, template, game-specific, or AWS-specific).
- Generate or modify files to bring the implementation into compliance with the specs.
- Preserve existing public API contracts unless explicitly instructed to change them.
- Keep changes minimal and focused on the requested task.
- Provide a summary of what was done and why at the end.

---

## 4. Godot Task Rules

Godot tasks include:

- New games under `games/<GameName>/`
- Changes to `defaultTemplate`
- Shared Godot systems under `shared/` (autoloads, managers, utilities, UI)
- Godot-side integrations with AWS (e.g. calling HTTP APIs from Godot)

### 4.1 Versions and Languages

- Use **Godot 4.x**.
- Use **GDScript** as the primary language for game logic unless explicitly told otherwise.
- Use the Godot 4 high-level multiplayer API when implementing networking.
- Use built-in Godot nodes and features wherever possible instead of custom engines.

### 4.2 Specifications and Contracts

- The agent must follow:
  - `shared/shared_systems_spec.md` for shared systems.
  - `defaultTemplate/default_template_spec.md` for the template.
  - Any game-specific spec such as `games/<GameName>/SPEC_<GameName>.md`.
- Scene navigation must go through `SceneManager` and use scene IDs from `SceneConfig`, not hardcoded paths.
- Configuration must go through `ConfigManager`.
- Audio must go through `AudioManager`.
- Input and rebinding must go through `InputManager`.
- Saving and loading must go through `SaveManager`.
- Cross-system signalling must go through `EventBus`.
- Legal, credits, and company info must go through `LegalManager`.

### 4.3 Godot Project Structure

- `shared/` holds reusable systems and UI:
  - `shared/autoload/` for autoload singletons.
  - `shared/ui/` for shared themes and widgets.
  - `shared/audio/` for shared sounds and music.
  - `shared/scripts/` for reusable helpers.
- `defaultTemplate/` holds:
  - Boot, main menu, loading, settings, and credits scenes.
  - Template placeholder gameplay scenes.
  - Any default assets used by all games.
- `games/<GameName>/` holds:
  - Game-specific scenes, scripts, and assets.
  - Game-specific specs (if present).

The agent must not store game-specific assets or logic in `shared/`.

### 4.4 Godot Code Style and Behaviour

- Follow Godot’s GDScript style guidelines.
- Use clear, descriptive names for nodes, scenes, scripts, and signals.
- Use constants instead of magic numbers.
- Place signals at the top of scripts.
- Use docstrings for important methods.
- Prefer composition and small functions over long, complex methods.
- Avoid tight coupling between scenes; use autoloads and the event bus where appropriate.
- Ensure scenes load correctly in Godot without missing dependencies.

---

## 5. Godot Testing Rules

When requested to run Godot tests or to make code testable, the agent must:

- Assume tests are executed headless.
- Prefer test entry points that can be run using:

  ```bash
  godot --headless --path . --run-tests
  ```

- In container or CI environments, use a writable `user://` directory and log path, for example:

  ```bash
  mkdir -p /tmp/godot_user /tmp/godot_logs

  godot     --headless     --user-path /tmp/godot_user     --log-file /tmp/godot_logs/godot.log     --path .     --run-tests
  ```

- Structure tests so they do not depend on editors or GUIs.
- When adjusting or adding tests, the agent must keep existing tests passing unless explicitly asked to change expected behaviour.

---

## 6. AWS Task Rules

AWS tasks include:

- Shared backend systems (leaderboards, matchmaking, telemetry, etc.).
- Game-specific backend services.
- Infrastructure-as-code projects for those services.
- Build and deployment pipelines for those services.

### 6.1 Runtimes and Languages

- For AWS Lambda functions, the default runtime is **Node.js 24.x**. citeturn0search1turn0search2
- Lambda handlers must use modern **async/await** style (no callback-based handlers for Node.js 24). citeturn0search1turn0search2
- Use **TypeScript** where reasonable for larger services, compiled to Node.js 24.x-compatible JavaScript for deployment.
- Use ECMAScript modules or CommonJS consistently within a project; do not mix styles without clear need.

### 6.2 Infrastructure as Code and Project Layout

- All AWS services must be defined using Infrastructure as Code (IaC).
- The default IaC tool is **AWS SAM** using YAML templates unless the task explicitly calls for CDK or raw CloudFormation.
- Each AWS service or bounded context must be self-contained, including:
  - Lambda code
  - IaC templates
  - CI/CD pipeline definition
  - Documentation or README

Example layout for an AWS service:

- `aws/<ServiceName>/template.yaml` (AWS SAM)
- `aws/<ServiceName>/src/` (Lambda handlers, shared code)
- `aws/<ServiceName>/tests/` (unit tests, e.g. Jest)
- `aws/<ServiceName>/.github/workflows/` or `ci/` (build pipelines)
- `aws/<ServiceName>/README.md` (how to build, test, deploy)

### 6.3 Build and Deployment Requirements

For any AWS service, the agent must:

- Include a build pipeline definition that:
  - Installs dependencies.
  - Runs unit tests.
  - Builds TypeScript (if used) to JavaScript targeting Node.js 24.x.
  - Packages and deploys via AWS SAM (or the specified IaC tool).
- Ensure IaC and pipeline definitions are consistent:
  - Function names in code match those referenced in the template.
  - Runtime in the SAM template is `nodejs24.x`.
- Document how to build and deploy in a simple README.
- The pipeline must utilise AWS services (for example but not limited to, CodePipeline, CodeBuild, CodeDeploy etc).
- The pipeline must trigger and deploy based on commits to this repository.
- The single use IAC must be produced that will provision this pipeline.
- Deltas to the pipeline IAC must be produced if the pipeline needs modification due to a development.

### 6.4 AWS Security and Configuration

- All public endpoints (API Gateway, ALB, etc.) must use HTTPS.
- Inputs must be validated in Lambda handlers:
  - Types and required fields.
  - Reasonable bounds (e.g. score ranges).
- Where a client-held shared secret is used (e.g. for leaderboards or matchmaking), the agent must:
  - Implement an HMAC (e.g. `HMAC-SHA256`) over the request body using the client secret.
  - Verify the signature in the Lambda handler and reject requests with invalid signatures.
- Rate limiting and abuse controls must be designed using:
  - API Gateway throttling and usage plans.
  - Optional AWS WAF rules for IP/country/User-Agent throttling.
- Secrets (such as HMAC keys) must not be hardcoded in the repository IaC or source code:
  - Use environment variables, AWS Secrets Manager, or AWS Systems Manager Parameter Store.

### 6.5 AWS Data and Persistence

- For data storage (e.g. leaderboards, matchmaking queues), prefer:
  - DynamoDB for simple keyed record storage.
- The agent must:
  - Define table schemas in IaC templates.
  - Configure appropriate keys and GSIs.
  - Use consistent types and naming in both code and templates.

---

## 7. Shared Rules for Godot and AWS Integration

For tasks that span both Godot and AWS (e.g. leaderboards, matchmaking, telemetry):

- Godot must call AWS services over HTTPS using JSON.
- AWS endpoints and API keys (if any) must be configurable, not hardcoded:
  - Use `ConfigManager` on the Godot side for base URLs and environment.
- Shared responsibilities:
  - Godot is responsible for collecting and sending data.
  - AWS services are responsible for validation, storage, and matching.
- The agent must ensure:
  - Payload schemas match between client and backend.
  - Error responses are handled gracefully in Godot.
  - Timeouts and retries are reasonable and documented.

---

## 8. Task Type Selection

When a task request is received, the agent must:

- Treat it as a **Godot task** if it mainly concerns:
  - Scenes, scripts, gameplay logic, UI, shared managers, or template behaviour.
- Treat it as an **AWS task** if it mainly concerns:
  - Lambdas, APIs, databases, IaC, CI/CD, or backend processes.
- Treat it as a **combined task** if it clearly involves both client and backend.

For combined tasks, the agent must:

- Respect all Godot rules for client code.
- Respect all AWS rules for backend code.
- Maintain a clear separation of responsibilities.

---

## 9. Standard Task Invocation

When a Codex-style agent is invoked within this repository, it must assume:

- This file (`AGENTS.md`), `shared/shared_systems_spec.md` are the authoritative specifications for Godot-side work.
- Any AWS-related specs (if present) under `aws/` are authoritative for backend work.
- The request is a scoped task to be performed within the existing architecture, not a new architecture, unless explicitly stated.

For any task, the agent must:

- Read and respect all relevant specifications.
- Identify which files will be created or modified.
- Output changes as complete files in fenced code blocks, prefixed with `# File: <path>`.
- Never truncate code.
- Avoid commentary inside code fences.
- End the response with a short summary of the changes.

The agent must not restate or re-emit specification documents unless explicitly asked.

---

## 10. Test Execution (Summary)

### 10.1 Godot

- Prefer headless test execution.
- Use a writable `user://` and explicit log file in container/CI environments, for example:

  ```bash
  mkdir -p /tmp/godot_user /tmp/godot_logs

  godot     --headless     --user-path /tmp/godot_user     --log-file /tmp/godot_logs/godot.log     --path .     --run-tests
  ```

- Tests must be deterministic and must not rely on editor state.

### 10.2 AWS

- For Node.js 24.x Lambda projects:
  - Use `npm` or `pnpm` to manage dependencies.
  - Use Jest or an equivalent test framework for unit tests.
  - Ensure `package.json` includes:
    - Build scripts (TypeScript compile if used).
    - Test scripts.
  - The CI pipeline must:
    - Install dependencies.
    - Run tests.
    - Build the project.
    - Package and deploy via the chosen IaC (AWS SAM by default).

- The agent must keep all existing tests passing unless explicitly instructed to change behaviour or expectations.

---

This specification must be applied silently for every task within the OneDayGames repository, for both Godot and AWS work, unless a task explicitly overrides parts of it.
