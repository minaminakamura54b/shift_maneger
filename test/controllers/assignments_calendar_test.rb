require "test_helper"

class AssignmentsCalendarTest < ActionDispatch::IntegrationTest
  test "管理者はカレンダーを閲覧できる" do
    sign_in users(:admin)
    get calendar_assignments_path
    assert_response :success
  end

  test "一般ユーザーもカレンダーで全社員の配置を閲覧できる" do
    sign_in users(:alice)
    get calendar_assignments_path
    assert_response :success
  end

  test "週表示でもエラーなく描画できる" do
    sign_in users(:alice)
    get calendar_assignments_path(view: "week")
    assert_response :success
  end

  test "日表示でもエラーなく描画できる" do
    sign_in users(:alice)
    get calendar_assignments_path(view: "day")
    assert_response :success
  end
end
