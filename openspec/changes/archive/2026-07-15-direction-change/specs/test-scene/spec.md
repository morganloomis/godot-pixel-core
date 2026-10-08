## ADDED Requirements

### Requirement: Direction transition manual check

The test scene SHALL support manual verification of multi-step direction transitions on the `PlayerEntity` child presenter. The scene SHALL include an on-screen hint (e.g. `Label` or equivalent UI text) instructing the tester to move in one direction then quickly reverse to the **opposed** facing (e.g. **W** then **E**) so intermediate facings are observable during play. The hint SHALL be visible when the test scene runs and SHALL NOT require reading repository documentation to perform the check.

#### Scenario: Hint visible at runtime

- **WHEN** the test scene is running
- **THEN** on-screen text SHALL describe reversing direction (e.g. hold left then tap right) to observe stepped facings

#### Scenario: Sharp reversal shows stepped facings on walk

- **WHEN** the tester holds movement input for one facing (e.g. **W**), then switches to the opposed facing (**E**) while still moving
- **THEN** the child `AnimatedEntity` SHALL display **walk** frames that step through intermediate compass facings along one arc before reaching **E**, rather than snapping instantly from **W** to **E**

#### Scenario: Sharp reversal observable on idle after stop

- **WHEN** the tester requests an opposed facing during movement and then releases input before the transition completes
- **THEN** the presenter SHALL continue stepping displayed facings on the **idle** action until the target facing is reached, showing intermediate idle rows if the transition was still active
