class DashboardController < ApplicationController
  def index
    # サマリー情報を取得
    @sites_count = Site.count
    @employees_count = Employee.count
    @assignments_count = Assignment.count

    # 直近の現場（開始日が近い順）
    @recent_sites = Site.order(start_date: :asc).limit(5)

    # 直近の配置
    @recent_assignments = Assignment.includes(:site, :employee)
                                    .order(start_date: :asc)
                                    .limit(5)
  end
end
