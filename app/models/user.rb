class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # 登録フォームから受け取る仮想属性（DBカラムなし）
  attr_accessor :name, :phone

  after_create :sync_to_employee

  private

  def sync_to_employee
    Employee.find_or_create_by!(email: email) do |e|
      e.name  = name.presence || email.split("@").first
      e.phone = phone.presence
    end
  rescue => e
    Rails.logger.error "社員レコード作成失敗: #{e.message}"
  end
end
