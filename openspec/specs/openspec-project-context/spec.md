# Spec: OpenSpec project context

## Purpose

Define how project context is maintained for OpenSpec and agents: concise, accurate, and instructive for Godot implementation choices (research and native workflows first).

## Requirements

### Requirement: Project context is maintained in config.yaml

Project context SHALL live in `openspec/config.yaml` under the `context` field, which is injected into all OpenSpec artifact instructions. The context SHALL be token-efficient: essential facts only, with detailed domain and architecture deferred to `openspec/specs/` and `addons/godot-pixel-core/README.md`.

#### Scenario: Reader scans for facts

- **WHEN** a contributor inspects `openspec/config.yaml`
- **THEN** they can identify engine version, addon root path, test vs shipped layout, and presenter-vs-body model in a brief read-through

#### Scenario: OpenSpec artifact generation

- **WHEN** OpenSpec generates instructions for any artifact (proposal, specs, design, tasks)
- **THEN** the `context` field from `openspec/config.yaml` is injected and per-artifact `rules` supply artifact-specific guidance

### Requirement: Per-artifact rules guide OpenSpec output

The `openspec/config.yaml` file SHALL include a `rules` map keyed by artifact ID (`proposal`, `specs`, `design`, `tasks`) with project-specific guidance for each artifact type, including Godot research and teach-me expectations where appropriate.

#### Scenario: Spec artifact rules

- **WHEN** OpenSpec generates instructions for the `specs` artifact
- **THEN** rules from `config.yaml` direct authors to use Given/When/Then scenarios and check existing specs before creating deltas

### Requirement: Cursor rules cover non-OpenSpec coding

General coding context SHALL live in `.cursor/rules/*.mdc` (scoped by file path or always-on essentials). There SHALL NOT be a duplicate cross-tool context file such as `AGENTS.md`.

#### Scenario: Non-OpenSpec coding session

- **WHEN** an agent works on addon code without an active OpenSpec change
- **THEN** relevant `.mdc` rules provide project context without duplicating the full `config.yaml` context block

### Requirement: Godot research before implementation

Project rules or Cursor rules SHALL instruct authors and agents to search current Godot documentation when choosing APIs, patterns, or workarounds, especially when unsure or when Godot's APIs have evolved.

#### Scenario: Unclear best practice

- **WHEN** implementation work might be done in more than one way in Godot
- **THEN** design rules or Cursor rules state that verifying official docs is expected before settling on an approach

### Requirement: Native Godot workflows before custom systems

Project rules SHALL instruct authors and agents to prefer built-in nodes, signals, resources, scenes, and editor workflows over ad-hoc frameworks unless a documented limitation makes native approaches insufficient.

#### Scenario: New subsystem design

- **WHEN** someone designs a new feature that could be implemented with standard Godot building blocks
- **THEN** design rules direct them to try those building blocks first and justify custom layers only when necessary
