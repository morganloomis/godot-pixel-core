## ADDED Requirements

### Requirement: Project context document stays concise and accurate

The `openspec/project.md` file SHALL remain the primary OpenSpec project brief. It SHALL present an accurate overview of Pixel Core, tech stack, repository layout, and domain concepts in a form that is noticeably more concise than a prose-heavy alternative: short paragraphs, scannable lists, and a domain summary that fits essential distinctions without redundant explanation.

#### Scenario: Reader scans for facts

- **WHEN** a contributor opens `openspec/project.md`
- **THEN** they can identify engine version, language, rendering mode, addon root path, test vs deployable layout, and the meaning of presenter vs body within a single read-through without wading through duplicate paragraphs

### Requirement: Godot research before implementation

The `openspec/project.md` file SHALL explicitly instruct authors and agents to search the web for current Godot documentation and reputable community guidance when choosing APIs, patterns, or workarounds, especially when unsure or when Godot’s APIs have evolved.

#### Scenario: Unclear best practice

- **WHEN** implementation work might be done in more than one way in Godot
- **THEN** `openspec/project.md` states that searching official docs and current best-practice discussions is expected before settling on an approach

### Requirement: Native Godot workflows before custom systems

The `openspec/project.md` file SHALL explicitly instruct authors and agents to prefer built-in nodes, signals, resources, scenes, and editor workflows over ad-hoc frameworks or fully custom solutions unless a documented limitation of the engine or addon requirements makes native approaches insufficient.

#### Scenario: New subsystem design

- **WHEN** someone designs a new feature that could be implemented with standard Godot building blocks
- **THEN** `openspec/project.md` directs them to try those building blocks first and to justify custom layers only when necessary
