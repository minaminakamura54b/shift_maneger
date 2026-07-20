class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # 新規登録直後（メール確認待ちで未ログイン状態）の遷移先。
  # デフォルトの root_path は認証必須のため、そこへ飛ばすと authenticate_user! に
  # よって即座にログイン画面へ再リダイレクトされ、「確認メールを送信しました」という
  # フラッシュメッセージが表示される前に失われてしまう。ログイン画面は未認証でも
  # 表示できるため、直接そちらへ遷移させることでメッセージを確実に見せる。
  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end
end
