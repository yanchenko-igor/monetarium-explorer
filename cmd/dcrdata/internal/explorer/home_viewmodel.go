package explorer

import "github.com/decred/dcrdata/v8/explorer/types"

// HomeBlockRow is the view model for one row in the home page block table.
// It carries all 13 column values pre-formatted so the template performs no
// numeric logic.
type HomeBlockRow struct {
	// Overview group (cols 1-7) — sourced directly from BlockBasic.
	Height         int64
	Hash           string
	Transactions   int
	Voters         uint16
	FreshStake     uint8
	Revocations    uint32
	FormattedBytes string
	BlockTime      types.TimeDef

	// VAR group (cols 8-10) — real chain data, monetary values pre-formatted.
	VARTxCount int    // same value as Transactions
	VARAmount  string // threeSigFigs(BlockBasic.Total)
	VARSize    string // BlockBasic.FormattedBytes (reused)

	// SKA group (cols 11-13) — mocked until the SKA backend is available.
	// Future: replace these string fields with a big-number type (e.g.
	// shopspring/decimal) once the real backend supplies raw SKA amounts.
	SKATxCount string // pre-formatted aggregate tx count
	SKAAmount  string // pre-formatted aggregate amount
	SKASize    string // pre-formatted aggregate size

	// Accordion control — computed once so the template needs no numeric logic.
	HasSKAData bool        // true when at least one sub-row exists
	SKASubRows []SKASubRow // per-SKA-type breakdown rows
}

// SKASubRow is one accordion detail row for a specific SKA token type.
// All numeric fields are pre-formatted strings.
// Future: replace Amount (and Size if needed) with a big-number type once the
// real SKA backend is available.
type SKASubRow struct {
	TokenType string // e.g. "SKA-1", "SKA-2", "SKA-3"
	TxCount   string // pre-formatted
	Amount    string // pre-formatted
	Size      string // pre-formatted
}

// buildHomeBlockRows converts a slice of BlockBasic pointers into HomeBlockRow
// view models, attaching mock SKA data. Nil entries are skipped.
func buildHomeBlockRows(blocks []*types.BlockBasic) []HomeBlockRow {
	rows := make([]HomeBlockRow, 0, len(blocks))
	for _, b := range blocks {
		if b == nil {
			continue
		}
		skaTx, skaAmt, skaSz, subRows := mockSKAData(b.Height)
		rows = append(rows, HomeBlockRow{
			Height:         b.Height,
			Hash:           b.Hash,
			Transactions:   b.Transactions,
			Voters:         b.Voters,
			FreshStake:     b.FreshStake,
			Revocations:    b.Revocations,
			FormattedBytes: b.FormattedBytes,
			BlockTime:      b.BlockTime,
			VARTxCount:     b.Transactions,
			VARAmount:      threeSigFigs(b.Total),
			VARSize:        b.FormattedBytes,
			SKATxCount:     skaTx,
			SKAAmount:      skaAmt,
			SKASize:        skaSz,
			HasSKAData:     len(subRows) > 0,
			SKASubRows:     subRows,
		})
	}
	return rows
}
