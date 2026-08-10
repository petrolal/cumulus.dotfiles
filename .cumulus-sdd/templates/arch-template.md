---
type: arch
id: ARCH-001
status: draft
created: YYYY-MM-DD
source: docs/sdd/prd.md
---

# Architecture: <TITLE>

## Overview
<One paragraph. The shape of the solution.>

## Components
### <ComponentName>
- **Responsibility:** <single responsibility>
- **Inputs:** <data / calls in>
- **Outputs:** <data / calls out>
- **Depends on:** <other components>

## Contracts
- `<interface / signature / message shape>` — <what it guarantees>

## Data Model
- **<Entity>** — <field: type, field: type>

## Requirement Traceability
| Requirement | Component(s) |
|-------------|--------------|
| FR-1        | <Component>  |

## Component Impact
- **New:** <component>
- **Modified:** <component>
- **Removed:** <component>

## Constraints
- <non-negotiable that bends the design>

## Acceptance Criteria
- [ ] Every PRD requirement maps to at least one component
- [ ] Each component has a single responsibility
- [ ] Contracts define interfaces, not implementations
- [ ] New/Modified/Removed components are explicit
