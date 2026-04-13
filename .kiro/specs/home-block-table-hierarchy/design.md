# Design Document: Home Block Table Hierarchy

## Overview

This feature adds visual hierarchy affordances to the "Latest Blocks" table on the Monetarium Explorer home page. The accordion expand/collapse mechanism already exists; this design specifies the exact markup, styles, and JS changes needed to make the parent–child relationship between block rows and their per-token sub-rows immediately scannable.

The changes are purely presentational and structural — no new columns, no new API endpoints, no backend changes. All work is confined to:

- `_variables.scss` — new SCSS variables
- `themes.scss` — dark-theme overrides
- `home.scss` — new component styles
- `home_latest_blocks.tmpl` — chevron and coin label markup
- `ska_accordion_controller.js` — chevron state toggling (already handled via `is-expanded`)
- `blocklist_controller.js` — chevron and coin label elements in dynamically injected rows

---

## Architecture

The feature follows the existing Stimulus + SCSS + Go template pattern already established in the codebase. No new controllers or template files are introduced.

```
┌─────────────────────────────────────────────────────────┐
│  home_latest_blocks.tmpl                                │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Parent_Row  [chevron] [height link]  …         │   │
│  │  Sub_Row     [│ ● VAR]  …                       │   │
│  │  Sub_Row     [│ ● SKA-1]  …                     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
         │ toggle click                │ BLOCK_RECEIVED
         ▼                             ▼
┌──────────────────────┐   ┌──────────────────────────────┐
│ ska_accordion_       │   │ blocklist_controller.js       │
│ controller.js        │   │ injects rows with chevron +  │
│ toggles is-expanded  │   │ badges matching template      │
│ on parent row        │   │ structure                     │
└──────────────────────┘   └──────────────────────────────┘
         │
         ▼
┌──────────────────────┐
│ home.scss            │
│ .chevron rotates on  │
│ .is-expanded         │
│ .ska-sub-row--visible│
│ td:first-child gets  │
│ inset box-shadow     │
│ .coin-label--var/ska │
│ dot colors           │
└──────────────────────┘
```

---

## Components and Interfaces

### 1. Chevron element

A CSS border-trick triangle rendered as an inline `<span>` inside the first `<td>` of every Parent_Row, before the height `<a>` link.

```html
<td class="text-start ps-1" data-type="height">
  <span class="chevron me-1"></span>
  <a href="/block/{{.Height}}" class="fs18">{{.Height}}</a>
</td>
```

The chevron is drawn with CSS borders and rotates 90° when the parent row has `is-expanded`. The `ska_accordion_controller.js` already adds/removes `is-expanded` on the parent row — no JS change is needed for the chevron rotation itself.

### 2. Coin label spans in Sub_Rows

The existing `<span class="sub-row-label">` is replaced with coin label markup using a colored dot via CSS `::before`:

```html
<!-- VAR sub-row first cell -->
<td class="text-end ps-2 ps-sm-4" data-type="sub-label">
  <span class="coin-label coin-label--var">VAR</span>
</td>

<!-- SKA sub-row first cell -->
<td class="text-end ps-2 ps-sm-4" data-type="sub-label">
  <span class="coin-label coin-label--ska">{{.TokenType}}</span>
</td>
```

The label cell uses `text-start` with responsive padding (`ps-2` on mobile, `ps-sm-4` at ≥540px) to create visual indentation. The dot is rendered via `.coin-label::before` as a small circle using `inline-flex` + `align-items: center` for reliable vertical alignment.

### 3. Vertical anchor

Applied via an inset `box-shadow` on `.ska-sub-row--visible td:first-child` — avoids layout shift since box-shadow is paint-only. The second shadow layer preserves Bootstrap's `--bs-table-accent-bg` hover tint.

### 4. SCSS variables (new additions to `_variables.scss`)

| Variable                | Light value | Purpose                    |
| ----------------------- | ----------- | -------------------------- |
| `$coin-var-primary`     | `#3374ff`   | VAR dot color              |
| `$coin-ska-primary`     | `#80868b`   | SKA dot color (muted grey) |
| `$sub-row-anchor-color` | `#c8d0d8`   | Vertical anchor box-shadow |

### 5. Dark theme overrides (new additions to `themes.scss` under `body.darkBG`)

| Selector                               | Property     | Dark value                                                              |
| -------------------------------------- | ------------ | ----------------------------------------------------------------------- |
| `.ska-sub-row--visible td:first-child` | `box-shadow` | `inset 3px 0 0 0 #4a5568, inset 0 0 0 9999px var(--bs-table-accent-bg)` |

---

## Data Models

No new data models. The feature is purely presentational. The existing view model types (`BlockBasic`, `SKASubRow`) already carry all required data.

The only structural change is that `blocklist_controller.js` must produce DOM nodes that match the updated template structure (chevron span in parent row, coin-label spans in sub-rows).

---

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property 1: Chevron presence in all parent rows

_For any_ rendered block table with one or more parent rows, every parent row's first cell SHALL contain an element with the `chevron` class.

**Validates: Requirements 1.1**

---

### Property 2: Chevron state reflects expansion

_For any_ parent row, the chevron element SHALL NOT have the rotated class when `is-expanded` is absent, and SHALL have the rotated class when `is-expanded` is present — these two states are mutually exclusive and exhaustive.

**Validates: Requirements 1.2, 1.3**

---

### Property 3: Chevron precedes height link in DOM

_For any_ parent row's first cell, the chevron element SHALL appear before the height anchor element in the cell's child node order.

**Validates: Requirements 1.5**

---

### Property 4: Injected rows are structurally complete

_For any_ block data object processed by `blocklist_controller`, the injected parent row's first cell SHALL contain a chevron element, every injected VAR sub-row's first cell SHALL contain a `coin-label--var` span, every injected SKA sub-row's first cell SHALL contain a `coin-label--ska` span, and every injected sub-row's first cell SHALL carry `data-type="sub-label"`.

**Validates: Requirements 1.6, 2.4, 4.7**

---

### Property 5: Sub-row first cell carries anchor class

_For any_ sub-row (VAR or SKA) in the rendered table, its first cell SHALL have the CSS class that applies the vertical anchor left border.

**Validates: Requirements 2.1, 2.3**

---

### Property 6: Sub-row first cell is left-aligned

_For any_ sub-row in the rendered table, its first cell SHALL have a left-alignment class (`text-start`) with responsive indentation padding.

**Validates: Requirements 3.1**

---

### Property 7: Column count invariant

_For any_ rendered state of the block table (initial render or after BLOCK_RECEIVED injection), the header row SHALL have exactly 9 `<th>` elements and every data row SHALL have exactly 9 `<td>` elements.

**Validates: Requirements 3.3, 7.1**

---

### Property 8: VAR sub-rows use coin-label--var

_For any_ VAR sub-row in the rendered table (whether server-rendered or JS-injected), its first cell SHALL contain a `<span>` with both `coin-label` and `coin-label--var` classes.

**Validates: Requirements 4.1**

---

### Property 9: All SKA sub-rows use coin-label--ska regardless of token index

_For any_ collection of SKA sub-rows with differing token indices (SKA-1, SKA-2, … SKA-n), every sub-row's first cell SHALL contain a `<span>` with both `coin-label` and `coin-label--ska` classes — the specific token index SHALL NOT affect the label class used.

**Validates: Requirements 4.2, 4.5**

---

### Property 10: All sub-rows carry subordination class

_For any_ sub-row in the rendered table, it SHALL carry the typographic subordination class that reduces visual weight relative to parent rows.

**Validates: Requirements 5.1, 5.3**

---

### Property 11: Responsive classes preserved on size and rev cells

_For any_ data row (parent or sub-row) in the rendered table, the size cell (column 5) and rev cell (column 8) SHALL retain the responsive display classes `d-none d-sm-table-cell d-md-none d-lg-table-cell`.

**Validates: Requirements 7.3**

---

## Error Handling

This feature has no error paths of its own. The relevant failure modes are inherited:

- **Missing sub-rows**: If `SKASubRows` is empty in the template, no SKA sub-rows are rendered. The chevron is still rendered on the parent row; clicking it finds zero sub-rows and the `ska_accordion_controller` no-ops (already handled by the `if (subRows.length === 0) return` guard).
- **JS injection with no coin_rows**: `coinRowsToSKAData` already handles the VAR-only fallback. The injected VAR sub-row will still receive the `coin-label--var` span and anchor class.
- **JS injection with multiple SKA types**: `insertSKASubRows` iterates `subRows`; each gets a `coin-label--ska` span regardless of `tokenType` value.

---

## Testing Strategy

### Unit tests (Vitest + jsdom)

Target: `blocklist_controller.js` injection logic and `ska_accordion_controller.js` toggle logic.

Each property above maps to one or more test cases:

| Property | Test file                             | What varies                          |
| -------- | ------------------------------------- | ------------------------------------ |
| P1       | `blocklist_controller.test.js`        | Block data with 1, 3, 10 blocks      |
| P2       | `ska_accordion_controller.test.js`    | Toggle called 1×, 2× (round-trip)    |
| P3       | `blocklist_controller.test.js`        | Any block data                       |
| P4       | `blocklist_controller.test.js`        | Blocks with 0, 1, N SKA coin_rows    |
| P5       | Template snapshot + JS injection test | VAR and SKA sub-rows                 |
| P6       | Template snapshot + JS injection test | VAR and SKA sub-rows                 |
| P7       | Template snapshot + JS injection test | Blocks with varying coin_rows counts |
| P8       | `blocklist_controller.test.js`        | VAR sub-rows                         |
| P9       | `blocklist_controller.test.js`        | coin_rows with SKA-1, SKA-2, SKA-255 |
| P10      | Template snapshot + JS injection test | All sub-row types                    |
| P11      | Template snapshot                     | Parent rows and sub-rows             |

**Property-based testing library**: `fast-check` (already available in the JS ecosystem; add as dev dependency).

Each property test runs a minimum of 100 iterations. Tests are tagged with:

```js
// Feature: home-block-table-hierarchy, Property N: <property text>
```

### Template snapshot tests

Go template tests in `home_template_test.go` (already exists) should be extended to assert:

- Every `blockRow` `<tr>` contains a `.chevron` span before the height link
- Every `ska-sub-row` `<tr>` first cell has `text-start` and `data-type="sub-label"`
- VAR sub-rows contain `<span class="coin-label coin-label--var">`
- SKA sub-rows contain `<span class="coin-label coin-label--ska">`
- Total `<th>` count = 9; total `<td>` count per row = 9

### Manual / smoke tests

- Dark theme: activate `body.darkBG`, verify chevron contrast, anchor shadow color
- Responsive: resize below 540px, verify no horizontal overflow, verify label indentation changes
- Font size: verify sub-row text ≥ 11px in computed styles

---

## Implementation Specification

### `_variables.scss` additions

```scss
// Block table hierarchy — coin label dot colors
$coin-var-primary: #3374ff;
$coin-ska-primary: #80868b;

// Block table hierarchy — sub-row vertical anchor
$sub-row-anchor-color: #c8d0d8;
```

### `themes.scss` additions (inside `body.darkBG { … }`)

```scss
.ska-sub-row--visible td:first-child {
  box-shadow:
    inset 3px 0 0 0 #4a5568,
    inset 0 0 0 9999px var(--bs-table-accent-bg);
}
```

### `home.scss` additions

```scss
// SKA accordion sub-rows — typographic subordination
.ska-sub-row {
  display: none;
  font-size: 0.85em;
  color: #6c757d;

  &--visible {
    display: table-row;
    background-color: $card-bg-secondary;
  }
}

body.darkBG .ska-sub-row--visible {
  background-color: $card-bg-secondary-dark;
}

body.darkBG .ska-sub-row {
  color: #c1c1c1;
}

// Responsive column min-widths at sm breakpoint
$col-min-widths-sm: (
  1: calc(96px),
);

@media (min-width: $breakpoint-sm) {
  @each $n, $w in $col-min-widths-sm {
    .last-blocks-table th:nth-child(#{$n}) {
      min-width: $w;
    }
  }
}

// Sub-row vertical anchor — inset box-shadow avoids layout shift
.ska-sub-row--visible td:first-child {
  box-shadow:
    inset 3px 0 0 0 $sub-row-anchor-color,
    inset 0 0 0 9999px var(--bs-table-accent-bg);
}

// Chevron — CSS border-trick triangle that rotates on expand
.chevron {
  display: inline-block;
  width: 0;
  height: 0;
  border-top: 3px solid transparent;
  border-bottom: 3px solid transparent;
  border-left: 5px solid currentcolor;
  vertical-align: middle;
  transition: transform 0.15s ease;
}

.last-blocks-table .block-row-expandable.is-expanded .chevron {
  transform: rotate(90deg);
}

// Coin label dots — inline-flex for reliable dot/text alignment
.coin-label {
  display: inline-flex;
  align-items: center;
  text-align: left;

  &::before {
    content: "";
    display: block;
    width: 0.5em;
    height: 0.5em;
    border-radius: 50%;
    margin-right: 0.35em;
  }

  &--var::before {
    background-color: $coin-var-primary;
  }
  &--ska::before {
    background-color: $coin-ska-primary;
  }
}
```

### `home_latest_blocks.tmpl` changes

Parent row first cell — add chevron span before the height link:

```html
<td class="text-start ps-1" data-type="height">
  <span class="chevron me-1"></span>
  <a href="/block/{{.Height}}" class="fs18">{{.Height}}</a>
</td>
```

VAR sub-row first cell — replace `sub-row-label` span with coin label:

```html
<td class="text-end ps-2 ps-sm-4" data-type="sub-label">
  <span class="coin-label coin-label--var">VAR</span>
</td>
```

SKA sub-row first cell — replace `sub-row-label` span with coin label:

```html
<td class="text-end ps-2 ps-sm-4" data-type="sub-label">
  <span class="coin-label coin-label--ska">{{.TokenType}}</span>
</td>
```

### `ska_accordion_controller.js` changes

No changes required. The controller already adds/removes `is-expanded` on the parent row via `row.classList.toggle('is-expanded', !isExpanded)`. The chevron rotation is handled entirely by CSS on `.is-expanded .chevron`.

### `blocklist_controller.js` changes

**`insertVARSubRow`** — replace the `sub-row-label` span with a `coin-label--var` span:

```js
const labelTd = makeTd("text-end ps-2 ps-sm-4");
labelTd.dataset.type = "sub-label";
const labelSpan = document.createElement("span");
labelSpan.className = "coin-label coin-label--var";
labelSpan.textContent = "VAR";
labelTd.appendChild(labelSpan);
```

**`insertSKASubRows`** — same change for SKA label:

```js
const labelTd = makeTd("text-end ps-2 ps-sm-4");
labelTd.dataset.type = "sub-label";
const badge = document.createElement("span");
badge.className = "coin-label coin-label--ska";
badge.textContent = sub.tokenType;
labelTd.appendChild(badge);
```

**Parent row injection** — in `_processBlock`, the `height` case must append a chevron span before the link:

```js
case 'height': {
  const chevron = document.createElement('span')
  chevron.className = 'chevron me-1'
  newTd.appendChild(chevron)
  const link = document.createElement('a')
  link.href = `/block/${block.height}`
  link.textContent = block.height
  link.classList.add(firstBlockRow.dataset.linkClass)
  newTd.appendChild(link)
  break
}
```
