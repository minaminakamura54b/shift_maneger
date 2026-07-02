require "test_helper"

# 新規登録時のメール確認（confirmable）とパスワード再設定（recoverable）の一連の流れを確認する
class DeviseRegistrationTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "新規登録すると確認メールが送信され、確認するまでログインできない" do
    post user_registration_path, params: {
      user: {
        name: "新規太郎",
        email: "shinki@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    user = User.find_by(email: "shinki@example.com")
    assert user.present?
    assert_not user.confirmed?

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "shinki@example.com" ], mail.to

    # 確認前はログインできない
    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_redirected_to new_user_session_path

    # メール内のリンクから確認するとログインできるようになる
    get user_confirmation_path(confirmation_token: user.confirmation_token)
    assert user.reload.confirmed?

    post user_session_path, params: { user: { email: user.email, password: "password" } }
    assert_redirected_to root_path
  end

  test "パスワードを忘れた場合、再設定メールのリンクから新しいパスワードを設定できる" do
    user = users(:alice)

    post user_password_path, params: { user: { email: user.email } }
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ user.email ], mail.to

    put user_password_path, params: {
      user: {
        reset_password_token: user.reload.send(:set_reset_password_token),
        password: "new-password",
        password_confirmation: "new-password"
      }
    }
    assert_redirected_to root_path

    post destroy_user_session_path
    post user_session_path, params: { user: { email: user.email, password: "new-password" } }
    assert_redirected_to root_path
  end

  test "ログイン中のユーザーは編集画面から自分のパスワードを変更できる" do
    sign_in users(:alice)
    get edit_user_registration_path
    assert_response :success

    put user_registration_path, params: {
      user: {
        current_password: "password",
        password: "new-password",
        password_confirmation: "new-password"
      }
    }
    assert_redirected_to root_path
  end
end
