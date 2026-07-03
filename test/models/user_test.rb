require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "登録時に社員レコードが正常に作成される" do
    user = User.create(email: "new-user@example.com", password: "password", name: "新規太郎", phone: "090-0000-9999")

    assert user.persisted?
    employee = Employee.find_by(email: "new-user@example.com")
    assert_equal "新規太郎", employee.name
  end

  test "社員レコード作成に失敗した場合はユーザー登録ごと失敗する" do
    original = Employee.method(:find_or_create_by!)
    Employee.define_singleton_method(:find_or_create_by!) do |*args|
      raise ActiveRecord::RecordInvalid, Employee.new
    end

    begin
      user = User.new(email: "broken-sync@example.com", password: "password")
      result = user.save

      assert_not result
      assert_not user.persisted?
      assert_includes user.errors[:base], "社員情報の登録に失敗しました。お手数ですが管理者にお問い合わせください"
    ensure
      Employee.define_singleton_method(:find_or_create_by!, original)
    end

    assert_nil User.find_by(email: "broken-sync@example.com")
  end
end
