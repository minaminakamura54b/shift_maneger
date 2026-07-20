class AttendanceRecordsController < ApplicationController
  before_action :require_employee!, only: %i[index clock_in clock_out]
  before_action :require_admin!, only: %i[all edit update]
  before_action :set_attendance_record, only: %i[edit update]

  # 自分の勤怠状況（出勤中かどうか）と打刻履歴
  def index
    # current_employee.attendance_records の時点で対象は自分1人分に絞られており、
    # ビューも employee を参照しないため includes(:employee) は不要（全社員分を横断して
    # 見る #all アクションでは includes(:employee) を使っている）
    @open_record = current_employee.attendance_records.open_records.first
    @records = current_employee.attendance_records.recent_first.limit(30)
  end

  # 管理者向け：全社員分の勤怠一覧（社員での絞り込み可）。
  # データが多いと見づらいため、フラットな一覧ではなく社員ごとにグループ化して表示する。
  def all
    @employees   = Employee.order(:name)
    @employee_id = params[:employee_id].presence

    scope = AttendanceRecord.includes(:employee).recent_first
    scope = scope.where(employee_id: @employee_id) if @employee_id
    # 社員を絞り込んでいない場合は全体の件数に上限を設ける（特定の1人だけ絞り込んだ場合はその人の全件を出す）
    records = @employee_id ? scope.limit(50) : scope.limit(200)

    @grouped_records = records.group_by(&:employee).sort_by { |employee, _| employee.name }
  end

  def edit; end

  def update
    if @attendance_record.update(attendance_record_params)
      redirect_to all_attendance_records_path, notice: "勤怠記録を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def clock_in
    AttendanceRecord.clock_in_for(current_employee)
    redirect_to attendance_records_path, notice: "出勤を記録しました"
  end

  def clock_out
    record = AttendanceRecord.clock_out_for(current_employee)
    if record
      redirect_to attendance_records_path, notice: "退勤を記録しました"
    else
      redirect_to attendance_records_path, alert: "出勤中の記録が見つかりません"
    end
  rescue ActiveRecord::RecordInvalid => e
    # サーバー時刻がNTP補正等で巻き戻り、退勤時刻が出勤時刻より前になった場合の保険
    redirect_to attendance_records_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_attendance_record
    @attendance_record = AttendanceRecord.includes(:employee).find(params[:id])
  end

  def attendance_record_params
    params.require(:attendance_record).permit(:clocked_in_at, :clocked_out_at)
  end

  # current_employee が存在しない（社員レコード未紐づけの）ユーザーは打刻できない
  def require_employee!
    return if current_employee

    redirect_to root_path, alert: "社員情報に紐づいていないため打刻できません。管理者にお問い合わせください"
  end
end
