import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static get targets () {
    return ['blockRow', 'subRow']
  }

  toggle (event) {
    const blockId = event.currentTarget.closest('tr').dataset.blockId
    const subRows = this.subRowTargets.filter(
      (r) => r.dataset.blockId === blockId
    )
    if (subRows.length === 0) return
    const isExpanded = subRows[0].classList.contains('ska-sub-row--visible')
    subRows.forEach((r) =>
      r.classList.toggle('ska-sub-row--visible', !isExpanded)
    )
    const row = this.blockRowTargets.find((r) => r.dataset.blockId === blockId)
    if (row) row.classList.toggle('is-expanded', !isExpanded)
  }
}
