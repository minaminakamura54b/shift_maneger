class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_employee, :can_manage_employee?, :can_manage_assignment?

  protected

  # 新規登録時に name / phone を許可
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone])
  end

  # ログイン中ユーザーに紐づく社員レコード（メールで照合）
  def current_employee
    @current_employee ||= Employee.find_by(email: current_user.email)
  end

  # 管理者 or 自分自身の社員レコードならtrue
  def can_manage_employee?(employee)
    current_user.admin? || employee == current_employee
  end

  # 管理者 or 自分自身の配置ならtrue
  def can_manage_assignment?(assignment)
    current_user.admin? || assignment.employee_id == current_employee&.id
  end

  # 管理者以外をはじく
  def require_admin!
    redirect_to root_path, alert: "管理者のみ実行できます" unless current_user.admin?
  end

  # 管理者 or 自分以外をはじく
  def require_own_or_admin!
    return if current_user.admin?
    unless @employee == current_employee
      redirect_to (current_employee ? employee_path(current_employee) : root_path),
                  alert: "自分のアカウントのみ編集・削除できます"
    end
  end
end
