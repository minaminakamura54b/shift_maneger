require "test_helper"

class AssignmentTest < ActiveSupport::TestCase
  test "バリデーションエラーは属性名も含めて日本語で表示される" do
    assignment = Assignment.new
    assignment.valid?

    assert_includes assignment.errors.full_messages, "社員を入力してください"
    assert_includes assignment.errors.full_messages, "開始日を入力してください"
    assert_includes assignment.errors.full_messages, "現場名を入力してください"
  end

  test "存在しないsite_idを指定すると日本語のエラーになる" do
    assignment = Assignment.new(
      employee: employees(:alice),
      start_date: "2026-07-01",
      site_id: Site.maximum(:id).to_i + 1000
    )
    assignment.valid?

    assert_includes assignment.errors.full_messages, "現場が見つかりません"
  end
end
