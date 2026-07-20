class CreateAttendanceRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :attendance_records do |t|
      t.references :employee, null: false, foreign_key: true
      # 将来「シフト予定」と「実際の打刻」を突き合わせる機能のための余地（現時点では未使用・nullable）
      t.references :assignment, null: true, foreign_key: true

      t.datetime :clocked_in_at, null: false
      t.datetime :clocked_out_at

      # 論理削除用（給与計算・労務監査の観点から物理削除はしない方針にするための余地）。
      # 現時点では削除UIは実装しないため、通常のクエリでは特に絞り込みを行わない
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :attendance_records, :clocked_in_at
    add_index :attendance_records, :deleted_at

    # 同一社員が「未退勤」のレコードを複数同時に持てないようにする部分ユニークインデックス。
    # 出勤ボタンの連打・複数タブ操作による二重出勤レコード作成を、DBレベルで防ぐ
    add_index :attendance_records, :employee_id, unique: true,
      where: "clocked_out_at IS NULL AND deleted_at IS NULL",
      name: "index_attendance_records_on_employee_open_record"
  end
end
