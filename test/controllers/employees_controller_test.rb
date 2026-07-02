require "test_helper"

# 参考: https://railsguides.jp/security.html の「権限（authorization）」
# 社員の新規登録は管理者のみ、編集・削除は本人か管理者のみに制限されていることを確認する。
class EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = employees(:alice)
    @bob   = employees(:bob)
  end

  test "一般ユーザーは社員の新規登録画面にアクセスできない" do
    sign_in users(:alice)
    get new_employee_path
    assert_redirected_to root_path
  end

  test "一般ユーザーは社員を新規作成できない" do
    sign_in users(:alice)

    assert_no_difference("Employee.count") do
      post employees_path, params: { employee: { name: "Eve", email: "eve@example.com" } }
    end
  end

  test "一般ユーザーは他人の社員情報の編集画面にアクセスできない" do
    sign_in users(:alice)
    get edit_employee_path(@bob)
    assert_redirected_to employee_path(@alice)
  end

  test "一般ユーザーは他人の社員情報を更新できない" do
    sign_in users(:alice)
    original_name = @bob.name

    patch employee_path(@bob), params: { employee: { name: "書き換え" } }

    assert_equal original_name, @bob.reload.name
  end

  test "一般ユーザーは他人を削除できない" do
    sign_in users(:alice)

    assert_no_difference("Employee.count") do
      delete employee_path(@bob)
    end
  end

  test "一般ユーザーは自分の社員情報を更新できる" do
    sign_in users(:alice)

    patch employee_path(@alice), params: { employee: { name: "Alice改" } }

    assert_equal "Alice改", @alice.reload.name
  end

  test "管理者は社員を新規作成でき、他人の情報も更新できる" do
    sign_in users(:admin)

    assert_difference("Employee.count", 1) do
      post employees_path, params: { employee: { name: "Eve", email: "eve@example.com" } }
    end

    patch employee_path(@bob), params: { employee: { name: "Bob改" } }
    assert_equal "Bob改", @bob.reload.name
  end
end
