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

  # --- 現場ごと表記（by=site） ---

  test "現場ごと表記でも日/週/月すべてエラーなく描画できる" do
    sign_in users(:admin)
    %w[day week month].each do |view|
      get calendar_assignments_path(view: view, by: "site")
      assert_response :success, "view=#{view} で失敗"
    end
  end

  test "現場ごと表記は縦軸が現場名になる" do
    sign_in users(:admin)
    get calendar_assignments_path(view: "month", by: "site")
    assert_select "td", text: sites(:one).name
    assert_select "td", text: sites(:two).name
  end

  test "現場を絞り込むと選んだ現場の配置だけが表示される" do
    sign_in users(:admin)
    get calendar_assignments_path(view: "month", by: "site", site_id: sites(:one).id, year: 2026, month: 6)
    assert_response :success
    assert_match employees(:alice).name, @response.body
    assert_no_match employees(:bob).name, @response.body
  end

  test "一般ユーザーも現場ごと表記を閲覧できる" do
    sign_in users(:alice)
    get calendar_assignments_path(view: "month", by: "site")
    assert_response :success
  end
end
