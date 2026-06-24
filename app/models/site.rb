class Site < ApplicationRecord
  has_many :assignments, dependent: :destroy
  has_many :employees, through: :assignments

  validates :name, presence: true
  validates :start_date, presence: true
end
