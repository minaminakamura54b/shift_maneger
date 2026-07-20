Rails.application.routes.draw do
  # Devise 認証ルート（登録直後の遷移先をカスタマイズするため registrations を差し替え）
  devise_for :users, controllers: { registrations: "users/registrations" }

  # ダッシュボード（ルート）
  root "dashboard#index"

  # 現場管理
  resources :sites

  # 社員管理
  resources :employees

  # 配置管理（カレンダービュー含む）
  resources :assignments do
    collection do
      get :calendar
    end
  end

  # 勤怠管理（自分の出退勤打刻・履歴／管理者は全員分の閲覧・修正も可能）
  resources :attendance_records, only: %i[index edit update] do
    collection do
      post :clock_in
      post :clock_out
      get  :all
    end
  end

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end
