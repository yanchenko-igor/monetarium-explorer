import { Controller } from '@hotwired/stimulus'
import humanize from '../helpers/humanize_helper'
import globalEventBus from '../services/event_bus_service'

const mockSKATokens = [
  { name: 'SKA-1', txs: 42, amount: 1_250_000, size: 8_400 },
  { name: 'SKA-2', txs: 17, amount: 450_000, size: 3_200 },
  { name: 'SKA-3', txs: 5, amount: 2_100_000_000, size: 1_100 }
]

function mockSKAData (height) {
  if (height % 9 === 0) {
    return { skaTx: '0', skaAmt: '0', skaSz: '0', subRows: [] }
  }
  const offset = height % 10
  let aggTx = 0
  let aggAmt = 0
  let aggSz = 0
  const subRows = []
  for (const tok of mockSKATokens) {
    const tx = tok.txs + offset
    const amt = tok.amount * (1 + offset / 100)
    const sz = tok.size + offset * 10
    aggTx += tx
    aggAmt += amt
    aggSz += sz
    subRows.push({
      tokenType: tok.name,
      txCount: String(tx),
      amount: humanize.threeSigFigs(amt),
      size: humanize.threeSigFigs(sz)
    })
  }
  const skaTx = String(aggTx)
  const skaAmt = humanize.threeSigFigs(aggAmt)
  const skaSz = humanize.threeSigFigs(aggSz)
  return { skaTx, skaAmt, skaSz, subRows }
}

function buildSKACell (newTd, value, hasSKAData) {
  if (hasSKAData) {
    newTd.classList.add('ska-clickable')
    newTd.dataset.action = 'click->ska-accordion#toggle'
    const btn = document.createElement('button')
    btn.type = 'button'
    btn.className = 'link-button'
    btn.textContent = value
    newTd.appendChild(btn)
  } else {
    newTd.textContent = value
  }
}

function insertSKASubRows (tbody, newRow, subRows, blockHeight) {
  let insertRef = newRow.nextSibling
  for (const sub of subRows) {
    const tr = document.createElement('tr')
    tr.className = 'ska-sub-row'
    tr.dataset.skaAccordionTarget = 'subRow'
    tr.dataset.blockId = String(blockHeight)

    // 7 spacer cells (sticky-col, tx, votes, tickets, rev, size, age)
    for (let i = 0; i < 7; i++) {
      const spacer = document.createElement('td')
      if (i === 0) spacer.className = 'sticky-col'
      tr.appendChild(spacer)
    }

    // token label spanning VAR columns
    const labelTd = document.createElement('td')
    labelTd.colSpan = 3
    labelTd.className = 'text-end fs13 fw-medium'
    labelTd.textContent = sub.tokenType
    tr.appendChild(labelTd)

    // SKA tx count
    const txTd = document.createElement('td')
    txTd.className = 'text-center group-ska-col'
    txTd.textContent = sub.txCount
    tr.appendChild(txTd)

    // SKA amount
    const amtTd = document.createElement('td')
    amtTd.className = 'text-end'
    amtTd.textContent = sub.amount
    tr.appendChild(amtTd)

    // SKA size
    const szTd = document.createElement('td')
    szTd.className = 'text-end pe-2'
    szTd.textContent = sub.size
    tr.appendChild(szTd)

    tbody.insertBefore(tr, insertRef)
    insertRef = tr.nextSibling
  }
}

export default class extends Controller {
  static get targets () {
    return ['table']
  }

  connect () {
    this.processBlock = this._processBlock.bind(this)
    globalEventBus.on('BLOCK_RECEIVED', this.processBlock)
    this.pageOffset = this.data.get('initialOffset')
  }

  disconnect () {
    globalEventBus.off('BLOCK_RECEIVED', this.processBlock)
  }

  _processBlock (blockData) {
    if (!this.hasTableTarget) return
    const block = blockData.block
    // Grab a copy of the first row.
    const rows = this.tableTarget.querySelectorAll('tr')
    if (rows.length === 0) return
    const tr = rows[0]
    const lastHeight = parseInt(tr.dataset.height)
    // Make sure this block belongs on the top of this table.
    if (block.height === lastHeight) {
      this.tableTarget.removeChild(tr)
    } else if (block.height === lastHeight + 1) {
      this.tableTarget.removeChild(rows[rows.length - 1])
    } else return
    // Set the td contents based on the order of the existing row.
    const { skaTx, skaAmt, skaSz, subRows } = mockSKAData(block.height)
    const hasSKAData = subRows.length > 0
    const newRow = document.createElement('tr')
    newRow.dataset.height = block.height
    newRow.dataset.linkClass = tr.dataset.linkClass
    newRow.dataset.skaAccordionTarget = 'blockRow'
    newRow.dataset.blockId = String(block.height)
    const tds = tr.querySelectorAll('td')
    tds.forEach((td) => {
      const newTd = document.createElement('td')
      newTd.className = td.className
      const dataType = td.dataset.type
      newTd.dataset.type = dataType
      switch (dataType) {
        case 'age':
          newTd.dataset.age = block.unixStamp
          newTd.dataset.timeTarget = 'age'
          newTd.textContent = humanize.timeSince(block.unixStamp)
          break
        case 'height': {
          const link = document.createElement('a')
          link.href = `/block/${block.height}`
          link.textContent = block.height
          link.classList.add(tr.dataset.linkClass)
          newTd.appendChild(link)
          break
        }
        case 'size':
          newTd.textContent = humanize.bytes(block.size)
          break
        case 'value':
          newTd.textContent = humanize.threeSigFigs(block.TotalSent)
          break
        case 'time':
          newTd.textContent = humanize.date(block.time, false)
          break
        case 'var-tx':
          newTd.textContent = String(block.tx)
          break
        case 'var-amount':
          newTd.textContent = humanize.threeSigFigs(block.total)
          break
        case 'var-size':
          newTd.textContent = humanize.bytes(block.size)
          break
        case 'ska-tx':
          buildSKACell(newTd, skaTx, hasSKAData)
          break
        case 'ska-amount':
          buildSKACell(newTd, skaAmt, hasSKAData)
          break
        case 'ska-size':
          buildSKACell(newTd, skaSz, hasSKAData)
          break
        default:
          newTd.textContent = block[dataType]
      }
      newRow.appendChild(newTd)
    })
    this.tableTarget.insertBefore(newRow, this.tableTarget.firstChild)
    insertSKASubRows(this.tableTarget, newRow, subRows, block.height)
  }
}
