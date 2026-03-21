// home_mock.go provides mock SKA data for the home page block table.
// Isolated in its own file so the entire mock can be replaced by a real
// database call by editing only this file — home_viewmodel.go and
// explorerroutes.go remain untouched.

package explorer

var mockSKATokens = []struct {
	name   string
	txs    float64
	amount float64
	size   float64
}{
	{"SKA-1", 42, 1_250_000, 8_400},
	{"SKA-2", 17, 450_000, 3_200},
	{"SKA-3", 5, 2_100_000_000, 1_100},
}

// mockSKAData returns pre-formatted SKA aggregate values and sub-rows.
// When height % 9 == 0, it returns an empty sub-row slice to simulate a block
// with no SKA activity, exercising the accordion-disabled state.
func mockSKAData(height int64) (txCount, amount, size string, subRows []SKASubRow) {
	if height%9 == 0 {
		return "0", "0", "0", nil
	}
	offset := float64(height % 10)
	var aggTx, aggAmt, aggSz float64
	subRows = make([]SKASubRow, 0, len(mockSKATokens))
	for _, tok := range mockSKATokens {
		tx := tok.txs + offset
		amt := tok.amount * (1 + offset/100)
		sz := tok.size + offset*10
		aggTx += tx
		aggAmt += amt
		aggSz += sz
		subRows = append(subRows, SKASubRow{
			TokenType: tok.name,
			TxCount:   threeSigFigs(tx),
			Amount:    threeSigFigs(amt),
			Size:      threeSigFigs(sz),
		})
	}
	return threeSigFigs(aggTx), threeSigFigs(aggAmt), threeSigFigs(aggSz), subRows
}
