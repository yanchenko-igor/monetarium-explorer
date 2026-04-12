# Rewards Logic Documentation

This document describes how PoW and PoS rewards are calculated and distributed for VAR and SKA coins in the Monetarium network, as well as how these values are prepared for the Explorer UI.

## Network Distribution Logic
(This section describes the actual protocol distribution)

### VAR Rewards
VAR coins are produced through a combination of Proof-of-Work (PoW) and Proof-of-Stake (PoS).

#### Distribution Split
The newly mined VAR coins for each block are split as follows:
- **PoW Miner**: Receives 50% of the block subsidy.
- **PoS Voters**: The remaining 50% is distributed among the tickets that voted in that block.

#### Calculation
The calculation is handled by the `standalone` package (accessed via `txhelpers.RewardsAtBlock`).
- **PoW Reward**: Calculated as `CalcWorkSubsidyV3`.
- **PoS Reward (per vote)**: Calculated as `CalcStakeVoteSubsidyV3`.
- **Total PoS Reward**: `PoS reward per vote * number of voters`.

*Note: The Explorer UI displays the absolute reward per vote (`NextBlockSubsidy.PoS / TicketsPerBlock`) rather than the profitability ratio.*

---

### SKA Rewards
SKA coins are not mined. They are issued once and then distributed.

#### Reward Source
Rewards for SKA coins are derived exclusively from transaction fees. These fees are generated when SKA outputs are spent in a block. The collected fees are then distributed to PoS voters via special transactions of type `TxTypeSSFee` (Stake Submission Fee) included in the same block.

#### Distribution
The SKA fees collected in a block are distributed among the PoS voters. Miners also receive a portion of these fees as standard transaction fees.

#### Calculation logic
1. **Collect Fees**: The system sums the `SKAValue` of all `TxTypeSSFee` transactions in a block.
2. **Per-Vote Reward**: The total SKA fee for a specific coin type is divided by the number of voters in that block.
   - $\text{Reward per Vote} = \frac{\text{Total SKA Fees in Block}}{\text{Number of Voters}}$
3. **Historical Averages**: For 30-day and yearly projections, the reward is computed by dividing each block's fees by the maximum possible voters (`TicketsPerBlock`) rather than actual voters, ensuring a consistent theoretical maximum.
4. **No Reward Condition**: `TxTypeSSFee` transactions are only created if SKA outputs are spent in the block. If no SKA outputs are spent, no fees are generated, no `TxTypeSSFee` transaction is created, and no SKA rewards are distributed for that block.

#### Implementation Details
- **Fee Summation**: Performed by `txhelpers.BlockSSFeeTotals`.
- **Average Rate**: The `txhelpers.AvgSSFeeRate` function computes the average reward rate over a period by averaging the per-vote rewards (using `TicketsPerBlock`) across blocks that had SKA fees.

---

## Explorer UI Calculation Logic
(This section describes how data is prepared for the Home Page "Mining" and "Voting" cards)

### Mining Section
- **PoW VAR Reward**: Displays the subsidy for the *next* block (`NBlockSubsidy.PoW`).
- **PoW SKA Reward**: Displays the actual SKA amounts awarded in the *last* block's coinbase transaction.
- **VAR Reward Reduction**: A progress bar showing the current block's position within the subsidy reduction window (`IdxInRewardWindow` / `RewardWindowSize`).

### Voting Section
- **Vote VAR Reward**:
    - **Per Block**: The absolute VAR reward per vote for the next block (`NextBlockSubsidy.PoS / TicketsPerBlock`).
    - **Per 30 Days**: A linear projection of the current per-vote reward expressed as a profitability percentage.
    - **Per Year (ASR)**: The Annual Staking Rate computed via `simulateASR`, which runs a simulation of buying and reinvesting tickets over 365 days (accounting for `TicketMaturity` and `CoinbaseMaturity` delays).
- **Vote SKA Reward**:
    - **Per Block**: Based on **Actuals**. The total SKA fees in the *last* block divided by the *actual* number of voters in that block, displayed as `SKA-n / Vote`.
    - **Per 30 Days / Per Year**: Based on **Theoretical Maximums**. The average SKA coins distributed per staked VAR over the period, computed by `txhelpers.AvgSSFeeRate` using `TicketsPerBlock` as the divisor.
- **Ticket Price**: Displays the current stake difficulty and the predicted difficulty for the next window.

### Formatting & Implementation
- **Precision**: VAR values are displayed with 8 decimal places; SKA values with 18 decimal places.
- **Formatting Helpers**:
    - `float64AsDecimalParts`: Used for most UI decimal displays.
    - `FormatSKAPerVAR`: Formats the SKA/VAR profitability ratio.
    - `FormatSKAAtoms`: Formats raw SKA atoms into a human-readable decimal string.
- **Live Updates**: The same calculation logic is performed in `pubsub/pubsubhub.go` to provide real-time updates via websockets.
