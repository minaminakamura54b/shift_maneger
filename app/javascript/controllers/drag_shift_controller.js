import { Controller } from "@hotwired/stimulus"

// ドラッグ&ドロップでシフトの日付・社員を変更するコントローラー
export default class extends Controller {
  // ドラッグ開始：配置データをDataTransferに保存
  dragstart(event) {
    const el = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", JSON.stringify({
      id:         el.dataset.dragId,
      startDate:  el.dataset.dragStartDate,
      endDate:    el.dataset.dragEndDate || "",
      employeeId: el.dataset.dragEmployeeId
    }))
    // 少し遅らせてから半透明にする（即時だとdragImageに影響する）
    setTimeout(() => { el.style.opacity = "0.35" }, 0)
  }

  dragend(event) {
    event.currentTarget.style.opacity = ""
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.style.outline = "2px solid #3b82f6"
    event.currentTarget.style.outlineOffset = "-2px"
  }

  dragleave(event) {
    this.#clearOutline(event.currentTarget)
  }

  async drop(event) {
    event.preventDefault()
    const cell = event.currentTarget
    this.#clearOutline(cell)

    let payload
    try {
      payload = JSON.parse(event.dataTransfer.getData("text/plain"))
    } catch { return }

    const newEmployeeId = cell.dataset.dragEmployeeId
    const newDate       = cell.dataset.dragDate

    // 同じセルへのドロップは何もしない
    if (payload.startDate === newDate && String(payload.employeeId) === String(newEmployeeId)) return

    const body = { assignment: { start_date: newDate, employee_id: newEmployeeId } }

    // 複数日配置の場合は end_date も同じ日数だけシフト
    if (payload.endDate) {
      const diff = Math.round(
        (new Date(payload.endDate) - new Date(payload.startDate)) / 86400000
      )
      const newEnd = new Date(newDate)
      newEnd.setDate(newEnd.getDate() + diff)
      body.assignment.end_date = newEnd.toISOString().slice(0, 10)
    }

    try {
      const res = await fetch(`/assignments/${payload.id}`, {
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

  // --- private ---

  #clearOutline(el) {
    el.style.outline      = ""
    el.style.outlineOffset = ""
  }
}
