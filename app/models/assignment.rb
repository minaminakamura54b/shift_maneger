class Assignment < ApplicationRecord
  belongs_to :site, optional: true
  belongs_to :employee

  validates :start_date, presence: true
  validates :site_name,  presence: { message: "を入力してください" }, if: -> { site.nil? }
  validate :end_date_after_start_date
  validate :end_time_after_start_time

  # 現場名を返す（site が未紐づけの場合は自由入力テキストを使用）
  def display_site_name
    site&.name || site_name || "（現場未設定）"
  end

  # 時間指定があるか
  def timed?
    start_time.present?
  end

  private

  def end_date_after_start_date
    return unless end_date && start_date
    errors.add(:end_date, "は開始日より後の日付にしてください") if end_date < start_date
  end

  def end_time_after_start_time
    return unless start_time && end_time
    errors.add(:end_time, "は開始時刻より後の時刻にしてください") if end_time <= start_time
  end
end
