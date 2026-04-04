# Requirements Document

## Introduction

This feature redesigns the "Latest Blocks" table on the Monetarium Explorer home page to introduce a clear visual data hierarchy between parent block rows and their per-token sub-rows (VAR and SKA-n). The existing accordion expand/collapse mechanism is already in place; this feature focuses on the visual affordances, structural nesting cues, badge-based asset identification, and typographic subordination that make the hierarchy immediately scannable — without adding new columns or breaking the responsive layout.

## Glossary

- **Block_Table**: The "Latest Blocks" `<table>` rendered by `home_latest_blocks.tmpl` and managed by `blocklist_controller.js` and `ska_accordion_controller.js`.
- **Parent_Row**: A `<tr>` representing a single block height; carries `data-ska-accordion-target="blockRow"` and the CSS class `block-row-expandable`.
- **Sub_Row**: A `<tr>` representing per-token data for a single block; carries `data-ska-accordion-target="subRow"` and the CSS class `ska-sub-row`.
- **Chevron**: A CSS border-trick triangle placed in the first column of a Parent_Row to signal expand/collapse affordance.
- **VAR_Label**: A styled `<span class="coin-label coin-label--var">` with a colored dot used to label the VAR primary-coin Sub_Row.
- **SKA_Label**: A styled `<span class="coin-label coin-label--ska">` with a colored dot used to label any SKA-type token Sub_Row.
- **Vertical_Anchor**: A persistent inset box-shadow on the first cell of each visible Sub_Row that visually connects Sub_Rows to their Parent_Row without affecting layout.
- **ska_accordion_controller**: The Stimulus 3 controller (`ska_accordion_controller.js`) that toggles Sub_Row visibility.
- **blocklist_controller**: The Stimulus 3 controller (`blocklist_controller.js`) that injects new block rows on WebSocket `BLOCK_RECEIVED` events.
- **SCSS_Variables**: The project's SCSS custom properties defined in `_variables.scss`, used as the single source of truth for colors and spacing.
- **VAR_Label_Color**: The SCSS variable `$coin-var-primary` that defines the VAR dot color.
- **SKA_Label_Color**: The SCSS variable `$coin-ska-primary` that defines the SKA dot color.

---

## Requirements

### Requirement 1: Chevron Expand/Collapse Indicator

**User Story:** As a user viewing the Latest Blocks table, I want a clear visual indicator on each block row so that I can immediately understand that the row is expandable and see its current state.

#### Acceptance Criteria

1. THE Block_Table SHALL render a Chevron in the first column of every Parent_Row.
2. WHEN a Parent_Row is in the collapsed state, THE Block_Table SHALL display the Chevron pointing to the right (or downward-pointing when expanded), clearly differentiating the two states.
3. WHEN a Parent_Row is in the expanded state (CSS class `is-expanded` is present), THE Block_Table SHALL display the Chevron in the rotated/alternate orientation to indicate the expanded state.
4. THE Chevron SHALL have a minimum hit target of 24 × 24 CSS pixels to support both mouse and touch interactions.
5. THE Block_Table SHALL position the Chevron at the leading (left) edge of the first column, before the block height link.
6. WHEN the blocklist_controller injects a new Parent_Row via a `BLOCK_RECEIVED` event, THE Block_Table SHALL include the Chevron in the injected row's first column.

---

### Requirement 2: Sub-Row Vertical Anchor (Left Border)

**User Story:** As a user who has expanded a block row, I want a visual guide that connects the sub-rows to their parent block so that I can immediately understand the parent–child relationship.

#### Acceptance Criteria

1. WHEN a Sub_Row is visible, THE Block_Table SHALL render a Vertical_Anchor — a continuous left border on the first cell of each Sub_Row — for the full height of that cell.
2. THE Vertical_Anchor SHALL use a color defined by a dedicated SCSS variable `$sub-row-anchor-color` in `_variables.scss`, with a dark-theme override in `themes.scss`, so that it is visually distinct from the cell border but does not compete with data content.
3. THE Vertical_Anchor SHALL be present on both VAR Sub_Rows and SKA Sub_Rows belonging to the same Parent_Row.
4. WHEN the blocklist_controller injects Sub_Rows via a `BLOCK_RECEIVED` event, THE Block_Table SHALL include the Vertical_Anchor styling on the injected Sub_Rows' first cells.

---

### Requirement 3: Left-Aligned Asset Label Positioning

**User Story:** As a user scanning the expanded sub-rows, I want the asset labels (VAR, SKA-1, etc.) to be clearly positioned within the first column so that they are visually separated from the block height link above and easy to scan.

#### Acceptance Criteria

1. THE Block_Table SHALL left-align the content of the first cell in every Sub_Row (asset label area) within that cell, with responsive padding (`ps-2 ps-sm-4`) to create visual indentation.
2. THE Block_Table SHALL left-align the block height link in the first cell of every Parent_Row, maintaining the existing typographic hierarchy.
3. THE Block_Table SHALL achieve label positioning without introducing additional columns or altering the column count.

---

### Requirement 4: VAR_Label and SKA_Label Asset Identification

**User Story:** As a user reading the sub-rows, I want asset names rendered with a distinct colored dot so that I can instantly distinguish token types from numerical data.

#### Acceptance Criteria

1. THE Block_Table SHALL render the VAR label in each VAR Sub_Row as a VAR_Label using `<span class="coin-label coin-label--var">VAR</span>`.
2. THE Block_Table SHALL render each SKA token label (SKA-1, SKA-2, etc.) in its Sub_Row as a SKA_Label using `<span class="coin-label coin-label--ska">`.
3. THE VAR_Label SHALL display a colored dot using `$coin-var-primary` (`#3374ff`) via a CSS `::before` pseudo-element.
4. THE SKA_Label SHALL display a colored dot using `$coin-ska-primary` (`#80868b`) via a CSS `::before` pseudo-element, using a visually distinct neutral tone.
5. THE SKA_Label SHALL apply a consistent color treatment for all SKA-type tokens regardless of the specific token index n.
6. The dot and label text SHALL be vertically aligned using `inline-flex` with `align-items: center`.
7. WHEN the blocklist_controller injects Sub_Rows via a `BLOCK_RECEIVED` event, THE Block_Table SHALL render VAR_Label and SKA_Label elements in the injected Sub_Rows.

---

### Requirement 5: Typographic Subordination of Sub-Rows

**User Story:** As a user scanning the table, I want sub-row data to appear visually subordinate to the parent block row so that my eye is drawn to block heights first and token details second.

#### Acceptance Criteria

1. THE Block_Table SHALL render Sub_Row text at a smaller font size or reduced color contrast compared to Parent_Row text, using values from SCSS_Variables or Bootstrap utility classes.
2. THE Block_Table SHALL NOT reduce Sub_Row text to a size below 11px to preserve legibility on small screens.
3. THE Block_Table SHALL apply subordinate styling consistently to all Sub_Rows (both VAR and SKA types).

---

### Requirement 6: Dark Theme Support

**User Story:** As a user who has enabled the dark theme (`body.darkBG`), I want all visual elements of the block table hierarchy to render correctly in dark mode so that the feature is fully usable regardless of theme.

#### Acceptance Criteria

1. THE Block_Table SHALL render the Chevron with sufficient contrast against the dark background when `body.darkBG` is active, using a color consistent with the existing dark-theme text color (`#fdfdfd` or equivalent).
2. THE Vertical_Anchor SHALL use a dark-theme color override defined in `themes.scss` (via a `$sub-row-anchor-color-dark` variable or equivalent `body.darkBG` rule) that is visually distinct from the dark cell background.
3. THE VAR_Badge and SKA_Badge SHALL use dark-theme background and text color overrides defined in `themes.scss`, following the same pattern as existing `body.darkBG` rules.
4. Sub_Row typographic subordination (reduced size or contrast) SHALL remain legible under `body.darkBG`; the muted color used SHALL be derived from or consistent with the existing dark-theme secondary text color (e.g. `#c1c1c1` as used for `.text-secondary` in `themes.scss`).
5. Sub_Row background color (`$card-bg-secondary-dark`) is already defined and applied via the existing `.ska-sub-row--visible` dark override; this SHALL be preserved and not regressed by the new styles.
6. ALL new SCSS rules introduced by this feature that have a light-theme value SHALL have a corresponding `body.darkBG` override in `themes.scss`.

---

### Requirement 7: Adaptive Layout — No New Columns

**User Story:** As a user on a mobile device, I want the table hierarchy changes to fit within the existing column structure so that the table does not require horizontal scrolling.

#### Acceptance Criteria

1. THE Block_Table SHALL implement all hierarchy visual changes within the existing 9-column structure; no additional `<th>` or `<td>` columns SHALL be introduced.
2. WHILE the viewport width is below the Bootstrap `sm` breakpoint (540px), THE Block_Table SHALL remain free of horizontal overflow caused by the hierarchy changes.
3. THE Block_Table SHALL continue to hide columns 5 (Size) and 8 (Rev) on viewports below `sm` and `md` breakpoints, as defined by the existing responsive classes (`d-none d-sm-table-cell d-md-none d-lg-table-cell`).
4. THE Block_Table SHALL use existing Bootstrap 5 utility classes and SCSS_Variables for all new styles, avoiding inline styles except where dynamically required by JavaScript.
