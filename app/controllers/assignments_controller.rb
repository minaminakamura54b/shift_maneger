class AssignmentsController < ApplicationController
  before_action :set_assignment,     only: %i[show]
  before_action :set_own_assignment, only: %i[edit update destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :assignment_not_found

  # カレンダービュー（縦=社員、横=日付）
  def calendar
    @view_mode = params[:view].presence_in(%w[day week month]) || "month"
    today      = Date.today

    case @view_mode
    when "day"
      @base_date  = parse_date_param || today
      @start_date = @base_date
      @end_date   = @base_date
      wday        = %w[日 月 火 水 木 金 土][@base_date.wday]
      @title      = @base_date.strftime("%Y年%-m月%-d日（#{wday}）")
      @prev_path  = calendar_assignments_path(view: "day",   **ymd(@base_date - 1))
      @next_path  = calendar_assignments_path(view: "day",   **ymd(@base_date + 1))
      @today_path = calendar_assignments_path(view: "day",   **ymd(today))
      @prev_label = "‹ 前日"
      @next_label = "翌日 ›"

    when "week"
      @base_date  = parse_date_param || today
      @start_date = @base_date.beginning_of_week(:monday)
      @end_date   = @start_date + 6.days
      @title      = "#{@start_date.strftime('%Y年%-m月%-d日')} 〜 #{@end_date.strftime('%-m月%-d日')}"
      @prev_path  = calendar_assignments_path(view: "week",  **ymd(@start_date - 7))
      @next_path  = calendar_assignments_path(view: "week",  **ymd(@start_date + 7))
      @today_path = calendar_assignments_path(view: "week",  **ymd(today))
      @prev_label = "‹ 前週"
      @next_label = "翌週 ›"

    else # month
      year        = (params[:year]  || today.year).to_i
      month       = (params[:month] || today.month).to_i
      @start_date = Date.new(year, month, 1)
      @end_date   = @start_date.end_of_month
      @title      = @start_date.strftime("%Y年%-m月")
      prev_m      = @start_date.prev_month
      next_m      = @start_date.next_month
      @prev_path  = calendar_assignments_path(view: "month", year: prev_m.year, month: prev_m.month)
      @next_path  = calendar_assignments_path(view: "month", year: next_m.year, month: next_m.month)
      @today_path = calendar_assignments_path(view: "month")
      @prev_label = "‹ 前月"
      @next_label = "翌月 ›"
    end

    @dates     = (@start_date..@end_date).to_a
    @employees = Employee.order(:name)

    # 表示期間と重なる配置を取得
    @assignments = Assignment.includes(:site)
                             .where("start_date <= ?", @end_date)
                             .where("COALESCE(end_date, start_date) >= ?", @start_date)

    # { employee_id => { date => [assignment, ...] } } のマップを構築
    @map = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
    @assignments.each do |a|
      eff_end = a.end_date || a.start_date
      ([@start_date, a.start_date].max..[eff_end, @end_date].min).each do |d|
        @map[a.employee_id][d] << a
      end
    end
  end

  def index
    @assignments = Assignment.includes(:site, :employee).order(start_date: :desc)
  end

  def show; end

  def new
    @assignment = Assignment.new
    @assignment.employee = current_employee unless current_user.admin?
    @sites     = Site.order(:name)
    @employees = available_employees
  end

  def edit
    @sites     = Site.order(:name)
    @employees = available_employees
  end

  def create
    @assignment          = Assignment.new(assignment_params)
    @assignment.employee = current_employee unless current_user.admin?
    # 既存の現場と一致すれば site_id を紐づけ、しなければ site_name のみ保持
    @assignment.site = resolve_site(@assignment.site_name)

    if @assignment.save
      redirect_to @assignment, notice: "配置を登録しました"
    else
      @sites     = Site.order(:name)
      @employees = available_employees
      render :new, status: :unprocessable_entity
    end
  end

  def update
    params[:assignment]&.delete(:employee_id) unless current_user.admin?

    if @assignment.update(assignment_params)
      # フォームから site_name が来た場合のみ現場を解決（D&D時は無視）
      if assignment_params.key?(:site_name)
        @assignment.site = resolve_site(@assignment.site_name)
        @assignment.save
      end
      respond_to do |format|
        format.html { redirect_to @assignment, notice: "配置情報を更新しました" }
        format.json { render json: { ok: true } }
      end
    else
      respond_to do |format|
        format.html do
          @sites     = Site.order(:name)
          @employees = available_employees
          render :edit, status: :unprocessable_entity
        end
        format.json { render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @assignment.destroy
    redirect_to assignments_path, notice: "配置を削除しました"
  end

  private

  def set_assignment
    @assignment = Assignment.includes(:site, :employee).find(params[:id])
  end

  # 自分の配置のみ取得（管理者は全件）。IDを直接指定した不正な編集・削除を防ぐ
  # ref: https://railsguides.jp/security.html （認可はクエリ自体をユーザーの権限で絞り込む）
  def set_own_assignment
    scope = current_user.admin? ? Assignment.all : (current_employee&.assignments || Assignment.none)
    @assignment = scope.includes(:site, :employee).find(params[:id])
  end

  # 権限外の配置IDを指定された場合の応答
  def assignment_not_found
    respond_to do |format|
      format.html { redirect_to assignments_path, alert: "自分の配置のみ編集・削除できます" }
      format.json { render json: { errors: ["自分の配置のみ編集・削除できます"] }, status: :forbidden }
    end
  end

  # 日付パラメータを Date に変換（year/month/day が揃っている場合のみ）
  def parse_date_param
    return nil unless params[:year] && params[:month] && params[:day]
    Date.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
  rescue ArgumentError
    nil
  end

  # Date を year/month/day のハッシュに変換
  def ymd(date)
    { year: date.year, month: date.month, day: date.day }
  end

  # 管理者は全社員、一般ユーザーは自分のみ
  def available_employees
    current_user.admin? ? Employee.order(:name) : Array(current_employee)
  end

  # 現場名から既存の Site を検索（新規作成はしない）
  def resolve_site(name)
    return nil if name.blank?
    Site.find_by(name: name.strip)
  end

  def assignment_params
    params.require(:assignment).permit(
      :employee_id, :site_name,
      :start_date, :end_date,
      :start_time, :end_time
    )
  end
end
