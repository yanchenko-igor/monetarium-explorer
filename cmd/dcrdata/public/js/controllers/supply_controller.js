import { Controller } from '@hotwired/stimulus'
import humanize from '../helpers/humanize_helper'

export default class extends Controller {
  static get targets() {
    return ['varCirculating', 'exchangeRate']
  }

  handleBlock({ detail: blockData }) {
    const ex = blockData.extra

    if (ex.var_coin_supply && this.hasVarCirculatingTarget) {
      this.varCirculatingTarget.innerHTML = humanize.decimalParts(
        ex.var_coin_supply.circulating / 1e8,
        true,
        0
      )
    }

    if (ex.exchange_rate && this.hasExchangeRateTarget) {
      this.exchangeRateTarget.textContent = humanize.twoDecimals(ex.exchange_rate.value)
    }
  }
}
