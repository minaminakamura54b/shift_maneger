class AddConfirmableToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # reconfirmable 用
    add_index :users, :confirmation_token, unique: true

    # 既存ユーザーはメール確認済み扱いにする（Devise confirmable の要件）
    User.reset_column_information
    User.update_all confirmed_at: DateTime.now
  end

  def down
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end
end
