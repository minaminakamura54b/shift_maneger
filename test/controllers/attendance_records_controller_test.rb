require "test_helper"

class AttendanceRecordsControllerTest < ActionDispatch::IntegrationTest
  test "ログインユーザーは自分の勤怠画面を閲覧できる" do
    sign_in users(:alice)
    get attendance_records_path
    assert_response :success
  end

  test "出勤ボタンで打刻できる" do
    sign_in users(:alice)

    assert_difference "employees(:alice).attendance_records.count", 1 do
      post clock_in_attendance_records_path
    end
    assert_redirected_to attendance_records_path
    assert_equal "出勤を記録しました", flash[:notice]
  end

  test "出勤済みの状態でもう一度出勤しても二重に打刻されない" do
    sign_in users(:alice)
    post clock_in_attendance_records_path

    assert_no_difference "employees(:alice).attendance_records.count" do
      post clock_in_attendance_records_path
    end
  end

  test "退勤ボタンで打刻できる" do
    sign_in users(:alice)
    post clock_in_attendance_records_path

    post clock_out_attendance_records_path
    assert_redirected_to attendance_records_path
    assert_equal "退勤を記録しました", flash[:notice]
    assert_not_nil employees(:alice).attendance_records.closed.last.clocked_out_at
  end

  test "出勤していない状態で退勤しようとするとエラーになる" do
    sign_in users(:alice)

    post clock_out_attendance_records_path
    assert_redirected_to attendance_records_path
    assert_equal "出勤中の記録が見つかりません", flash[:alert]
  end

  test "他人の勤怠には影響しない" do
    sign_in users(:alice)
    post clock_in_attendance_records_path

    assert_equal 0, employees(:bob).attendance_records.count
  end

  test "サーバー時刻の巻き戻り等で退勤時刻が出勤時刻より前になる場合はエラーメッセージを表示する" do
    sign_in users(:alice)
    # clocked_in_at をわざと未来時刻にして、Time.currentで退勤しようとすると
    # 「退勤時刻が出勤時刻より前」の状態を再現する
    employees(:alice).attendance_records.create!(clocked_in_at: 1.hour.from_now)

    post clock_out_attendance_records_path

    assert_redirected_to attendance_records_path
    assert_match "退勤時刻は出勤時刻より後の値にしてください", flash[:alert]
  end

  # --- 管理者による全社員閲覧・編集 ---

  test "一般ユーザーは全社員の勤怠一覧にアクセスできない" do
    sign_in users(:alice)
    get all_attendance_records_path
    assert_redirected_to root_path
  end

  test "一般ユーザーは他人の勤怠記録を編集できない" do
    sign_in users(:alice)
    record = employees(:bob).attendance_records.create!(clocked_in_at: 1.hour.ago)

    get edit_attendance_record_path(record)
    assert_redirected_to root_path

    patch attendance_record_path(record), params: { attendance_record: { clocked_in_at: 2.hours.ago } }
    assert_redirected_to root_path
  end

  test "管理者は全社員の勤怠一覧を閲覧できる" do
    sign_in users(:admin)
    employees(:alice).attendance_records.create!(clocked_in_at: 1.hour.ago, clocked_out_at: Time.current)
    employees(:bob).attendance_records.create!(clocked_in_at: 2.hours.ago, clocked_out_at: 1.hour.ago)

    get all_attendance_records_path
    assert_response :success
    assert_match employees(:alice).name, @response.body
    assert_match employees(:bob).name, @response.body
  end

  test "管理者は社員で絞り込んで勤怠一覧を閲覧できる" do
    sign_in users(:admin)
    employees(:alice).attendance_records.create!(clocked_in_at: 1.hour.ago, clocked_out_at: Time.current)
    employees(:bob).attendance_records.create!(clocked_in_at: 2.hours.ago, clocked_out_at: 1.hour.ago)

    get all_attendance_records_path(employee_id: employees(:alice).id)
    assert_response :success
    # 絞り込みのselect自体には全社員が候補として出るため、グループ化された記録領域だけを見る
    assert_select ".space-y-4" do
      assert_select "h2", text: employees(:alice).name, count: 1
      assert_select "h2", text: employees(:bob).name, count: 0
    end
  end

  test "同じ社員の複数の記録は1つのグループにまとめて表示され、件数と合計時間が出る" do
    sign_in users(:admin)
    employees(:alice).attendance_records.create!(
      clocked_in_at: Time.zone.parse("2026-07-01 09:00"), clocked_out_at: Time.zone.parse("2026-07-01 12:00")
    )
    employees(:alice).attendance_records.create!(
      clocked_in_at: Time.zone.parse("2026-07-02 09:00"), clocked_out_at: Time.zone.parse("2026-07-02 11:00")
    )

    get all_attendance_records_path
    assert_response :success
    # Aliceの見出しは1つだけ（2件が同じグループにまとまっている）
    assert_select "h2", text: employees(:alice).name, count: 1
    assert_match "2件", @response.body
    assert_match "合計5時間0分", @response.body
  end

  test "管理者は勤怠記録の出退勤時刻を修正できる" do
    sign_in users(:admin)
    record = employees(:alice).attendance_records.create!(clocked_in_at: "2026-07-01 09:00", clocked_out_at: "2026-07-01 18:00")

    patch attendance_record_path(record), params: {
      attendance_record: { clocked_in_at: "2026-07-01 09:30", clocked_out_at: "2026-07-01 18:30" }
    }

    assert_redirected_to all_attendance_records_path
    record.reload
    assert_equal Time.zone.parse("2026-07-01 09:30"), record.clocked_in_at
    assert_equal Time.zone.parse("2026-07-01 18:30"), record.clocked_out_at
  end

  test "1分未満で出退勤した記録を編集フォームからそのまま保存しても秒単位が保持され失敗しない" do
    sign_in users(:admin)
    # 出勤・退勤が同じ分内（数秒差）に収まる短い記録を再現する
    record = employees(:alice).attendance_records.create!(
      clocked_in_at: Time.zone.parse("2026-07-01 09:00:10"),
      clocked_out_at: Time.zone.parse("2026-07-01 09:00:40")
    )

    # datetime_field(step: 1) はブラウザから秒付きの値（YYYY-MM-DDTHH:MM:SS）で送られてくる
    patch attendance_record_path(record), params: {
      attendance_record: {
        clocked_in_at: "2026-07-01T09:00:10",
        clocked_out_at: "2026-07-01T09:00:40"
      }
    }

    assert_redirected_to all_attendance_records_path
    record.reload
    assert_equal 30, record.worked_duration
  end

  test "退勤時刻を出勤時刻より前に修正しようとすると失敗する" do
    sign_in users(:admin)
    record = employees(:alice).attendance_records.create!(clocked_in_at: "2026-07-01 09:00", clocked_out_at: "2026-07-01 18:00")

    patch attendance_record_path(record), params: {
      attendance_record: { clocked_out_at: "2026-07-01 08:00" }
    }

    assert_response :unprocessable_entity
    assert_equal Time.zone.parse("2026-07-01 18:00"), record.reload.clocked_out_at
  end

  test "他に未退勤の記録がある社員の退勤時刻を空にしようとすると失敗する（二重オープン防止）" do
    sign_in users(:admin)
    closed_record = employees(:alice).attendance_records.create!(clocked_in_at: "2026-07-01 09:00", clocked_out_at: "2026-07-01 18:00")
    AttendanceRecord.clock_in_for(employees(:alice))

    patch attendance_record_path(closed_record), params: {
      attendance_record: { clocked_out_at: "" }
    }

    assert_response :unprocessable_entity
    assert_not_nil closed_record.reload.clocked_out_at
  end
end
