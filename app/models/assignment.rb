class Assignment < ApplicationRecord
  belongs_to :site
  belongs_to :employee

  validates :start_date, presence: true
  validate :end_date_after_start_date

  private

  def end_date_after_start_date
    return unless end_date && start_date
    errors.add(:end_date, "は開始日より後の日付にしてください") if end_date < start_date
  end
end
