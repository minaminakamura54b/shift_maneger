class ApplicationController < ActionController::Base
  # モダンブラウザのみ許可
  allow_browser versions: :modern

  # importmap 変更時にキャッシュ無効化
  stale_when_importmap_changes

  # ログイン必須
  before_action :authenticate_user!
end
