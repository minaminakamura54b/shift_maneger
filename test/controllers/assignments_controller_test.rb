require "test_helper"

# 参考: https://railsguides.jp/security.html
# 「権限（authorization）」の章にある通り、IDを直接指定した強制ブラウジング（forceful browsing）や
# パラメータ改ざんによる権限昇格（マスアサインメント）を防げているかを確認する。
class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice_assignment = assignments(:alice_assignment)
    @bob_assignment    = assignments(:bob_assignment)
  end

  # --- 強制ブラウジング対策：他人の配置IDを直接指定してもアクセスできない ---

  test "一般ユーザーは他人の配置の編集画面にアクセスできない" do
    sign_in users(:alice)
    get edit_assignment_path(@bob_assignment)
    assert_redirected_to assignments_path
  end

  test "一般ユーザーは他人の配置を更新できない" do
    sign_in users(:alice)
    original_start_date = @bob_assignment.start_date

    patch assignment_path(@bob_assignment), params: { assignment: { start_date: "2026-07-01" } }

    assert_redirected_to assignments_path
    assert_equal original_start_date, @bob_assignment.reload.start_date
  end

  test "一般ユーザーは他人の配置をJSON経由（ドラッグ&ドロップ）でも更新できない" do
    sign_in users(:alice)
    original_start_date = @bob_assignment.start_date

    patch assignment_path(@bob_assignment),
          params: { assignment: { start_date: "2026-07-01" } }.to_json,
          headers: { "Content-Type" => "application/json", "Accept" => "application/json" }

    assert_response :forbidden
    assert_equal original_start_date, @bob_assignment.reload.start_date
  end

  test "一般ユーザーは他人の配置を削除できない" do
    sign_in users(:alice)

    assert_no_difference("Assignment.count") do
      delete assignment_path(@bob_assignment)
    end
    assert_redirected_to assignments_path
  end

  # --- 自分の配置は操作できる ---

  test "一般ユーザーは自分の配置を更新できる" do
    sign_in users(:alice)

    patch assignment_path(@alice_assignment), params: { assignment: { start_date: "2026-07-01", end_date: "2026-07-01" } }

    assert_redirected_to @alice_assignment
    assert_equal Date.new(2026, 7, 1), @alice_assignment.reload.start_date
  end

  test "一般ユーザーは自分の配置を削除できる" do
    sign_in users(:alice)

    assert_difference("Assignment.count", -1) do
      delete assignment_path(@alice_assignment)
    end
  end

  # --- マスアサインメント対策：employee_id を書き換えて他人の配置に付け替えられない ---

  test "一般ユーザーは自分の配置のemployee_idを他人に書き換えられない" do
    sign_in users(:alice)

    patch assignment_path(@alice_assignment),
          params: { assignment: { start_date: "2026-07-01", employee_id: employees(:bob).id } }

    assert_equal employees(:alice).id, @alice_assignment.reload.employee_id
  end

  # --- 管理者は全件操作できる ---

  test "管理者は他人の配置も更新・削除できる" do
    sign_in users(:admin)

    patch assignment_path(@bob_assignment), params: { assignment: { start_date: "2026-07-01", end_date: "2026-07-01" } }
    assert_redirected_to @bob_assignment
    assert_equal Date.new(2026, 7, 1), @bob_assignment.reload.start_date

    assert_difference("Assignment.count", -1) do
      delete assignment_path(@alice_assignment)
    end
  end

  # --- 閲覧は全員に許可（一覧・カレンダーで他社員の予定を確認できる仕様） ---

  test "一般ユーザーは他人の配置の詳細を閲覧できる" do
    sign_in users(:alice)
    get assignment_path(@bob_assignment)
    assert_response :success
  end

  test "一般ユーザーの詳細画面には他人の配置に編集・削除リンクが出ない" do
    sign_in users(:alice)
    get assignment_path(@bob_assignment)
    assert_not_includes @response.body, "編集"
    assert_not_includes @response.body, "削除"
  end
end
