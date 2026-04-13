# Implementation Plan: Home Block Table Hierarchy

## Overview

Add visual hierarchy affordances to the "Latest Blocks" table: a CSS chevron on parent rows, badge-styled asset labels on sub-rows, a vertical anchor left-border, and typographic subordination — all within the existing 9-column structure. Changes touch exactly 5 files; no new files are created.

## Tasks

- [x] 1. Add SCSS variables to `_variables.scss`
  - Append the 5 new variables after the existing `$block-row-hover-dark` block:
    `$coin-var-primary`, `$var-badge-color`, `$coin-ska-primary`, `$ska-badge-color`, `$sub-row-anchor-color`
  - `$coin-var-primary` MUST reuse `$regular-light` to create the semantic link required by Requirement 4.3
  - _Requirements: 2.2, 4.3, 4.4, 4.6_

- [x] 2. Add dark-theme overrides to `themes.scss`
  - Inside the existing `body.darkBG { … }` block, append overrides for `.badge-var`, `.badge-ska`, and `.ska-sub-row td:first-child` (border-left-color)
  - Follow the same selector pattern as the existing `.bg-white` and `.text-secondary` overrides
  - _Requirements: 4.6, 6.2, 6.3, 6.6_

- [x] 3. Add component styles to `home.scss`
  - [x] 3.1 Add `.chevron` rule (CSS-only triangle via border trick) and the `.is-expanded .chevron` rotation rule
    - _Requirements: 1.2, 1.3, 1.4_
  - [x] 3.2 Add `.ska-sub-row td:first-child` rule for the vertical anchor left-border using `$sub-row-anchor-color`
    - _Requirements: 2.1, 2.3_
  - [x] 3.3 Add `.badge-var` and `.badge-ska` light-theme rules using the new variables
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - [x] 3.4 Add typographic subordination rules on `.ska-sub-row` (font-size, color) and the `body.darkBG` override
    - Font size MUST stay at or above 11px (0.85em at 14px base ≈ 11.9px)
    - Dark color MUST be consistent with `#c1c1c1` used for `.text-secondary` in `themes.scss`
    - _Requirements: 5.1, 5.2, 5.3, 6.4_

- [x] 4. Update `home_latest_blocks.tmpl`
  - [x] 4.1 Add `<span class="chevron me-1"></span>` before the height `<a>` in every Parent_Row first cell
    - _Requirements: 1.1, 1.5_
  - [x] 4.2 Replace `<span class="sub-row-label">VAR</span>` with `<span class="badge badge-var">VAR</span>` in the VAR sub-row first cell, and change the cell class from `text-start` to `text-end`
    - _Requirements: 3.1, 4.1_
  - [x] 4.3 Replace `<span class="sub-row-label">{{.TokenType}}</span>` with `<span class="badge badge-ska">{{.TokenType}}</span>` in the SKA sub-row first cell, and change the cell class from `text-start` to `text-end`
    - _Requirements: 3.1, 4.2, 4.5_

- [x] 5. Update `blocklist_controller.js` injection logic
  - [x] 5.1 In the `height` case of `_processBlock`, prepend a `<span class="chevron me-1">` before the height `<a>` link
    - _Requirements: 1.6_
  - [x] 5.2 In `insertVARSubRow`, replace the `sub-row-label` span with `<span class="badge badge-var">VAR</span>` and change the label cell class from `text-start` to `text-end`
    - _Requirements: 2.4, 3.1, 4.7_
  - [x] 5.3 In `insertSKASubRows`, replace the `sub-row-label` span with `<span class="badge badge-ska">` and change the label cell class from `text-start` to `text-end`
    - _Requirements: 2.4, 3.1, 4.7_

- [x] 6. Checkpoint — verify structural correctness
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Write property-based tests for `blocklist_controller.js` injection logic
  - Create `cmd/dcrdata/public/js/controllers/blocklist_controller.test.js` (new file)
  - Use Vitest + jsdom + fast-check (already a dev dependency)
  - Stub `@hotwired/stimulus`, `../helpers/humanize_helper`, and `../services/event_bus_service` with `vi.mock` following the same pattern as `ska_accordion_controller.test.js`
  - Each property test MUST be tagged: `// Feature: home-block-table-hierarchy, Property N: <text>`
  - [x] 7.1 Write unit tests for `insertVARSubRow` and `insertSKASubRows` structural output
    - Assert: label cell has class `text-end`, contains a `<span>` with `badge badge-var` / `badge badge-ska`, 9 `<td>` elements per row, responsive classes on cols 5 and 8
    - _Requirements: 2.4, 3.1, 4.7, 7.1, 7.3_
  - [ ]\* 7.2 Write property test for Property 4: injected rows are structurally complete
    - **Property 4: Injected rows are structurally complete**
    - **Validates: Requirements 1.6, 2.4, 4.7**
    - Use `fc.record` to generate arbitrary block data with 0, 1, and N coin_rows; assert chevron in parent row first cell, `badge-var` in VAR sub-row, `badge-ska` in each SKA sub-row
  - [ ]\* 7.3 Write property test for Property 7: column count invariant
    - **Property 7: Column count invariant**
    - **Validates: Requirements 3.3, 7.1**
    - For any generated block data, assert every injected row (parent + sub-rows) has exactly 9 `<td>` elements
  - [ ]\* 7.4 Write property test for Property 8: VAR sub-rows use badge-var
    - **Property 8: VAR sub-rows use badge-var**
    - **Validates: Requirements 4.1**
    - For any block data, assert the VAR sub-row first cell contains `<span class="badge badge-var">`
  - [ ]\* 7.5 Write property test for Property 9: all SKA sub-rows use badge-ska regardless of token index
    - **Property 9: All SKA sub-rows use badge-ska regardless of token index**
    - **Validates: Requirements 4.2, 4.5**
    - Use `fc.array(fc.record({ symbol: fc.constantFrom('SKA-1','SKA-2','SKA-255'), ... }))` to generate varying SKA coin_rows; assert every SKA sub-row first cell contains `<span class="badge badge-ska">`
  - [ ]\* 7.6 Write property test for Property 1: chevron presence in all injected parent rows
    - **Property 1: Chevron presence in all parent rows**
    - **Validates: Requirements 1.1**
    - For any block data, assert the injected parent row's first cell contains an element with class `chevron`
  - [ ]\* 7.7 Write property test for Property 3: chevron precedes height link in DOM
    - **Property 3: Chevron precedes height link in DOM**
    - **Validates: Requirements 1.5**
    - For any block data, assert the chevron span's `nextElementSibling` is the height `<a>` link
  - [ ]\* 7.8 Write property test for Property 5: sub-row first cell carries anchor class
    - **Property 5: Sub-row first cell carries anchor class**
    - **Validates: Requirements 2.1, 2.3**
    - For any block data with ≥1 sub-row, assert every sub-row's first cell has `data-type="sub-label"` (the selector targeted by the anchor border CSS rule)
  - [ ]\* 7.9 Write property test for Property 6: sub-row first cell is right-aligned
    - **Property 6: Sub-row first cell is right-aligned**
    - **Validates: Requirements 3.1**
    - For any block data, assert every sub-row's first cell has class `text-end`
  - [ ]\* 7.10 Write property test for Property 10: all sub-rows carry subordination class
    - **Property 10: All sub-rows carry subordination class**
    - **Validates: Requirements 5.1, 5.3**
    - For any block data, assert every injected sub-row has class `ska-sub-row`
  - [ ]\* 7.11 Write property test for Property 11: responsive classes preserved on size and rev cells
    - **Property 11: Responsive classes preserved on size and rev cells**
    - **Validates: Requirements 7.3**
    - For any block data, assert col-5 and col-8 cells in every injected row carry `d-none d-sm-table-cell d-md-none d-lg-table-cell`

- [x] 8. Update property-based tests in `ska_accordion_controller.test.js`
  - [x] 8.1 Write unit tests for Property 2: chevron state reflects expansion
    - Assert that after `toggle()` the parent row gains `is-expanded`; after a second `toggle()` it loses it
    - _Requirements: 1.2, 1.3_
  - [ ]\* 8.2 Write property test for Property 2: chevron state reflects expansion (round-trip)
    - **Property 2: Chevron state reflects expansion**
    - **Validates: Requirements 1.2, 1.3**
    - Extend the existing round-trip property test to also assert `is-expanded` is absent after two toggles for any `blockId`

- [x] 9. Final checkpoint — ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- `ska_accordion_controller.js` requires NO code changes — chevron rotation is handled entirely by CSS on `.is-expanded .chevron`
- Property tests run a minimum of 100 iterations via fast-check's default configuration
- Each property test must include the tag comment `// Feature: home-block-table-hierarchy, Property N: <text>`
- The existing `ska_accordion_controller.test.js` already covers Properties 7 and 8 from the prior spec; the new tests in task 8 target Properties 2 from this spec
