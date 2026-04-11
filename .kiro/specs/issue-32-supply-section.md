# Issue #32 — Frontend: Replace Distribution Section with Supply Section

## Status

Renames complete. Implementation pending.

## What was already done (renames)

- `distribution_controller.js` → `supply_controller.js`
- `data-controller="...distribution..."` → `...supply...` in `home.tmpl`
- `data-action="...distribution#handleBlock..."` → `...supply#handleBlock...` in `home.tmpl`
- `data-distribution-target="..."` → `data-supply-target="..."` in `home.tmpl`

## Backend contract (commit 0ed5dc2, on `develop`)

The `HomeInfo` struct now carries:

```go
VARCoinSupply  *VARCoinSupply       // nil when unavailable
SKACoinSupply  []SKACoinSupplyEntry // empty slice when unavailable
```

```go
type VARCoinSupply struct {
    Circulating string // big-number atom string, 8 decimal places
    Target      string // from chain params.MaxSupply
}

type SKACoinSupplyEntry struct {
    CoinType      uint8  // SKA-n identifier (1, 2, …)
    InCirculation string // big-number atom string, 18 decimal places
    TotalIssued   string // big-number atom string, 18 decimal places
    TotalBurned   string // big-number atom string, 18 decimal places
}
```

All string values are raw atom counts (integers as strings). The template helper
`formatCoinAtoms <value> <coinType>` handles decimal formatting:

- coinType `0` → 8 decimal places (VAR)
- coinType `1–255` → 18 decimal places (SKA)

## Implementation tasks

### 1. Rebase / merge `develop` into `feature/supply-frontend`

The backend types and route changes live on `develop` (merged via PR #66).
The current branch is one commit ahead of `bugfix/mining-frontend`, not yet
rebased onto `develop`. Rebase first so the template has access to
`VARCoinSupply` and `SKACoinSupply`.

```sh
git fetch origin
git rebase origin/develop
```

### 2. Rewrite the Supply section in `home.tmpl`

Replace the current compact inline SKA rows with the layout described in the
issue:

**VAR Coin Supply subsection**

- Label: "VAR Coin Supply"
- Primary value: `formatCoinAtoms .VARCoinSupply.Circulating 0` + "VAR" unit
- Sub-label: `(of ~47M)` target hint (static copy; exact value from
  `formatCoinAtoms .VARCoinSupply.Target 0` can be used if preferred)
- Live-update target: `data-supply-target="varCirculating"` (already in place)

**SKA Coin Supply subsection**

- Label: "SKA Coin Supply"
- `{{range .SKACoinSupply}}` — one block per SKA type
  - Header: "SKA-{{.CoinType}}"
  - Row: "In Circulation" → `formatCoinAtoms .InCirculation .CoinType`
  - Row: "Total Issued" → `formatCoinAtoms .TotalIssued .CoinType`
  - Row: "Total Burned" → `formatCoinAtoms .TotalBurned .CoinType`
  - Values formatted to 18 decimal places (handled by `formatCoinAtoms`)

Guard both subsections with `{{if}}` (already present) so the section degrades
gracefully when data is unavailable.

### 3. Update `supply_controller.js`

The old controller body is inherited from the Decred `distribution` controller
and references fields that no longer exist in this project
(`coin_supply`, `mixed_percent`, `subsidy.dev`, `dev_fund`, `treasury_bal`).

Replace the `handleBlock` body with logic relevant to the Supply section:

- Remove all dead target references (`coinSupply`, `mixedPct`, `devFund`,
  `bsubsidyDev`, `convertedDev`, `convertedSupply`, `convertedDevSub`).
- Keep `exchangeRate` target update (already wired in template).
- Add `varCirculating` target update using `blockData.extra.var_coin_supply`
  if present (live refresh of VAR circulating supply on new block).
- SKA supply rows are server-rendered on page load; no live WebSocket update
  is required for SKA in this issue.

Minimal updated targets list:

```js
static get targets() {
  return ['varCirculating', 'exchangeRate']
}
```

### 4. SCSS — no new rules needed

The Supply section uses only existing utility classes (`fs13`, `fs14-decimal`,
`fs24`, `mono`, `lh1rem`, `p03rem0`, `text-secondary`, `text-black-50`,
Bootstrap grid/spacing). No new SCSS variables or rules are required.

If a visual separator between VAR and SKA subsections is desired, use
Bootstrap's `border-bottom` utility rather than a custom rule.

### 5. Verify

- [ ] Rebase succeeds without conflicts
- [ ] `go build ./...` passes in `cmd/dcrdata`
- [ ] Template renders with mock data (light + dark, mobile + desktop)
- [ ] No `distribution` references remain anywhere in the frontend
- [ ] `npm run lint` passes
- [ ] `npm run test` passes
