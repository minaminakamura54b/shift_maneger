# 勤怠（実際の出退勤打刻）を表すモデル。
#
# 設計メモ:
# - 「予定」を表す Assignment とは独立したモデルにしている。
#   将来的にシフト予定と実際の打刻を突き合わせる機能を作る場合は assignment_id を使う。
# - 月次・日次の労働時間集計は、データ量が少ないうちは都度SQLで計算する方針とする
#   （DailyAttendanceSummary のような集計専用テーブルは今のところ不要）。
# - deleted_at は将来の論理削除のための余地。現状は削除機能自体を実装していないため
#   クエリの絞り込みには使っていない（= 通常のActiveRecordクエリで見える）。
class AttendanceRecord < ApplicationRecord
  belongs_to :employee
  belongs_to :assignment, optional: true

  validates :clocked_in_at, presence: true
  validates :clocked_out_at,
            comparison: { greater_than: :clocked_in_at, message: "は出勤時刻より後の値にしてください" },
            allow_nil: true
  validate :only_one_open_record_per_employee

  # 退勤していない（＝勤務中の）レコード。日付では絞り込まない。
  # 夜勤など日をまたぐ勤務でも「出勤日」ではなく「未退勤かどうか」だけで判定するため、
  # for_today のような日付ベースのscopeはあえて用意しない。
  scope :open_records, -> { where(clocked_out_at: nil) }
  scope :closed, -> { where.not(clocked_out_at: nil) }
  scope :recent_first, -> { order(clocked_in_at: :desc) }

  # 出勤打刻。
  # 同一社員に未退勤レコードが既にあればそれをそのまま返し、新規レコードは作らない
  # （出勤ボタンの連打・複数タブ操作による二重出勤を防ぐ）。
  # トランザクション内で SELECT FOR UPDATE 相当のロックを取ったうえで確認するが、
  # それでも競合した場合はDB側の部分ユニークインデックスが最終防衛線として働くため、
  # ActiveRecord::RecordNotUnique を rescue して先勝ちしたレコードを返す。
  def self.clock_in_for(employee)
    transaction do
      existing = employee.attendance_records.open_records.lock.first
      next existing if existing

      employee.attendance_records.create!(clocked_in_at: Time.current)
    end
  rescue ActiveRecord::RecordNotUnique
    employee.attendance_records.open_records.first
  end

  # 退勤打刻。未退勤の最新レコードに対して行う（対象社員に未退勤レコードが無ければ何もしない）。
  def self.clock_out_for(employee)
    transaction do
      open_record = employee.attendance_records.open_records.lock.first
      next nil unless open_record

      open_record.update!(clocked_out_at: Time.current)
      open_record
    end
  end

  # 実働時間（退勤済みの場合のみ）
  def worked_duration
    return nil unless clocked_out_at
    clocked_out_at - clocked_in_at
  end

  private

  # 管理者による手動編集で clocked_out_at を空にした場合など、DB の部分ユニークインデックス
  # （未退勤レコードは社員ごとに1件まで）に違反しそうなケースを、生のDBエラーではなく
  # 通常のバリデーションエラーとして検知する
  def only_one_open_record_per_employee
    return if clocked_out_at.present? || employee_id.blank?

    conflict = self.class.open_records.where(employee_id: employee_id).where.not(id: id).exists?
    errors.add(:clocked_out_at, "を空にできません（この社員には他に未退勤の記録があります）") if conflict
  end
end
