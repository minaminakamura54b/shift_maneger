class Employee < ApplicationRecord
  has_many :assignments, dependent: :destroy
  has_many :sites, through: :assignments
  has_many :attendance_records, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
