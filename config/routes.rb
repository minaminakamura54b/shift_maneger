Rails.application.routes.draw do
  # Devise 認証ルート
  devise_for :users

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

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end
