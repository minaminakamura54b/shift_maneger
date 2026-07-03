class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  # 登録フォームから受け取る仮想属性（DBカラムなし）
  attr_accessor :name, :phone

  # after_create + throw :abort はレコード挿入後の中断が保証されないため before_create で行う
  before_create :sync_to_employee

  private

  def sync_to_employee
    Employee.find_or_create_by!(email: email) do |e|
      e.name  = name.presence || email.split("@").first
      e.phone = phone.presence
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    # 社員レコードが作れないままユーザーだけ作成されると current_employee が
    # 永久に nil になり配置作成などができなくなるため、登録自体を失敗させる
    Rails.logger.error "社員レコード作成失敗: #{e.message}"
    errors.add(:base, "社員情報の登録に失敗しました。お手数ですが管理者にお問い合わせください")
    throw :abort
  end
end
