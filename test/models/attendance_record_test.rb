require "test_helper"

class AttendanceRecordTest < ActiveSupport::TestCase
  setup do
    @employee = employees(:alice)
  end

  test "clock_in_for は未退勤レコードが無ければ新規に出勤打刻を作成する" do
    assert_difference "AttendanceRecord.count", 1 do
      record = AttendanceRecord.clock_in_for(@employee)
      assert_not_nil record.clocked_in_at
      assert_nil record.clocked_out_at
    end
  end

  test "clock_in_for を連続で呼んでも二重に出勤レコードは作られない（連打対策）" do
    first  = AttendanceRecord.clock_in_for(@employee)

    assert_no_difference "AttendanceRecord.count" do
      second = AttendanceRecord.clock_in_for(@employee)
      assert_equal first.id, second.id
    end
  end

  test "複数タブ相当の同時アクセスでも出勤レコードは1件しか作られない（レースコンディション対策）" do
    threads = 8.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          AttendanceRecord.clock_in_for(@employee)
        end
      end
    end
    threads.each(&:join)

    assert_equal 1, @employee.attendance_records.count
    assert_equal 1, @employee.attendance_records.open_records.count
  end

  test "clock_out_for は未退勤レコードに退勤時刻を記録する" do
    AttendanceRecord.clock_in_for(@employee)

    record = AttendanceRecord.clock_out_for(@employee)

    assert_not_nil record.clocked_out_at
    assert_equal 0, @employee.attendance_records.open_records.count
  end

  test "clock_out_for は未退勤レコードが無ければ何もせずnilを返す" do
    assert_nil AttendanceRecord.clock_out_for(@employee)
  end

  test "日をまたぐ勤務（夜勤）でも日付に関係なく未退勤レコードを退勤できる" do
    yesterday_night = 1.day.ago.change(hour: 23)
    record = @employee.attendance_records.create!(clocked_in_at: yesterday_night)

    closed = AttendanceRecord.clock_out_for(@employee)

    assert_equal record.id, closed.id
    assert closed.clocked_out_at > closed.clocked_in_at
  end

  test "退勤時刻が出勤時刻より前だとバリデーションエラーになる" do
    record = @employee.attendance_records.build(
      clocked_in_at: Time.current,
      clocked_out_at: 1.hour.ago
    )

    assert_not record.valid?
    assert_includes record.errors.full_messages, "退勤時刻は出勤時刻より後の値にしてください"
  end

  test "打刻時刻はTokyoタイムゾーンで記録される" do
    record = AttendanceRecord.clock_in_for(@employee)
    assert_equal "Tokyo", record.clocked_in_at.time_zone.name
  end

  test "worked_duration は退勤済みの場合のみ実働時間（秒）を返す" do
    record = @employee.attendance_records.create!(
      clocked_in_at: Time.zone.parse("2026-07-01 09:00"),
      clocked_out_at: Time.zone.parse("2026-07-01 18:00")
    )
    assert_equal 9.hours.to_i, record.worked_duration

    open_record = AttendanceRecord.clock_in_for(employees(:bob))
    assert_nil open_record.worked_duration
  end
end
