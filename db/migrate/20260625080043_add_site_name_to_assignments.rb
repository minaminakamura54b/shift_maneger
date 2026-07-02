class AddSiteNameToAssignments < ActiveRecord::Migration[8.1]
  def change
    add_column :assignments, :site_name, :string
    # 自由入力のテキストも保存できるよう site_id を任意に変更
    change_column_null :assignments, :site_id, true
  end
end
