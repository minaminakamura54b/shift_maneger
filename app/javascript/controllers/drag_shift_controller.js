import { Controller } from "@hotwired/stimulus"

// ドラッグ&ドロップでシフトの日付・行（社員 or 現場）を変更するコントローラー
// ネイティブHTML5 DnD API（dragstart/drop等）はスマホのタッチ操作では発火しないため、
// マウス・タッチの両方で同じように動く Pointer Events を使って自前で実装する
const DRAG_THRESHOLD = 8 // px未満の移動はドラッグとみなさず、リンクのタップ扱いにする

export default class extends Controller {
  // "employee": 行=社員（employee_idを変更） / "site": 行=現場（site_idを変更）
  static values = { mode: { type: String, default: "employee" } }

  connect() {
    this.session          = null
    this.suppressNextClick = false
  }

  // 配置ブロックを押した瞬間
  start(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return

    const el = event.currentTarget
    this.session = {
      el,
      pointerId:  event.pointerId,
      id:         el.dataset.dragId,
      startDate:  el.dataset.dragStartDate,
      endDate:    el.dataset.dragEndDate || "",
      rowId:      el.dataset.dragRowId,
      originX:    event.clientX,
      originY:    event.clientY,
      dragging:   false,
      ghost:      null,
      targetCell: null
    }
    el.setPointerCapture(event.pointerId)
  }

  // 押したまま動かした（マウスの移動・指のスワイプ）
  move(event) {
    const s = this.session
    if (!s || event.pointerId !== s.pointerId) return

    if (!s.dragging) {
      const moved = Math.hypot(event.clientX - s.originX, event.clientY - s.originY)
      if (moved < DRAG_THRESHOLD) return
      // 一定距離動いたらドラッグ確定：見た目（半透明化＋追従するゴースト）を用意する
      s.dragging = true
      s.el.style.opacity = "0.35"
      s.ghost = this.#createGhost(s.el, event.clientX, event.clientY)
      document.body.appendChild(s.ghost)
    }

    event.preventDefault()
    this.#positionGhost(s.ghost, event.clientX, event.clientY)

    const cell = this.#cellUnder(event.clientX, event.clientY)
    if (cell !== s.targetCell) {
      if (s.targetCell) this.#clearOutline(s.targetCell)
      if (cell) this.#setOutline(cell)
      s.targetCell = cell
    }
  }

  // 指・マウスを離した
  async end(event) {
    const s = this.session
    if (!s || event.pointerId !== s.pointerId) return
    this.session = null
    s.el.releasePointerCapture(event.pointerId)

    if (!s.dragging) return // 動いていなければ通常のリンクタップとして扱う

    event.preventDefault()
    this.suppressNextClick = true
    this.#cleanup(s)

    const cell = s.targetCell
    if (!cell) return

    const newRowId = cell.dataset.dragRowId
    const newDate  = cell.dataset.dragDate

    // 同じセルへのドロップは何もしない
    if (s.startDate === newDate && String(s.rowId) === String(newRowId)) return

    await this.#saveMove(s, newDate, newRowId)
  }

  // ドラッグ中にキャンセルされた場合（他のタッチに割り込まれた等）
  cancel(event) {
    const s = this.session
    if (!s || event.pointerId !== s.pointerId) return
    this.session = null
    if (s.dragging) {
      this.suppressNextClick = true
      this.#cleanup(s)
    }
  }

  // ドラッグが確定した回では、pointerup の後に発火する click でのリンク遷移を止める
  click(event) {
    if (this.suppressNextClick) {
      event.preventDefault()
      this.suppressNextClick = false
    }
  }

  // --- private ---

  #cleanup(s) {
    s.el.style.opacity = ""
    s.ghost?.remove()
    if (s.targetCell) this.#clearOutline(s.targetCell)
  }

  #createGhost(el, x, y) {
    const rect  = el.getBoundingClientRect()
    const ghost = el.cloneNode(true)
    ghost.style.position     = "fixed"
    ghost.style.zIndex       = "1000"
    ghost.style.width        = `${rect.width}px`
    ghost.style.pointerEvents = "none"
    ghost.style.boxShadow    = "0 4px 12px rgba(0,0,0,0.3)"
    ghost.style.opacity      = "0.9"
    ghost.style.margin       = "0"
    this._ghostOffsetX = x - rect.left
    this._ghostOffsetY = y - rect.top
    this.#positionGhost(ghost, x, y)
    return ghost
  }

  #positionGhost(ghost, x, y) {
    ghost.style.left = `${x - this._ghostOffsetX}px`
    ghost.style.top  = `${y - this._ghostOffsetY}px`
  }

  // ゴーストは pointer-events:none なので、その下にある実際のセルを検出できる
  #cellUnder(x, y) {
    return document.elementFromPoint(x, y)?.closest("[data-drag-date]") || null
  }

  #setOutline(el) {
    el.style.outline       = "2px solid #3b82f6"
    el.style.outlineOffset = "-2px"
  }

  #clearOutline(el) {
    el.style.outline       = ""
    el.style.outlineOffset = ""
  }

  async #saveMove(s, newDate, newRowId) {
    const rowParam = this.modeValue === "site" ? "site_id" : "employee_id"
    const body = { assignment: { start_date: newDate, [rowParam]: newRowId } }

    // 複数日配置の場合は end_date も同じ日数だけシフト
    if (s.endDate) {
      const diff = Math.round(
        (new Date(s.endDate) - new Date(s.startDate)) / 86400000
      )
      const newEnd = new Date(newDate)
      newEnd.setDate(newEnd.getDate() + diff)
      body.assignment.end_date = newEnd.toISOString().slice(0, 10)
    }

    try {
      const res = await fetch(`/assignments/${s.id}`, {
        method: "PATCH",
        headers: {
          "Content-Type":  "application/json",
          "X-CSRF-Token":  document.querySelector('meta[name="csrf-token"]').content,
          "Accept":        "application/json"
        },
        body: JSON.stringify(body)
      })

      if (res.ok) {
        // カレンダーを現在の表示のまま再読み込み
        Turbo.visit(window.location.href, { action: "replace" })
      } else {
        const json = await res.json().catch(() => ({}))
        alert("移動できませんでした: " + (json.errors?.join("、") || "不明なエラー"))
      }
    } catch {
      alert("通信エラーが発生しました")
    }
  }
}
