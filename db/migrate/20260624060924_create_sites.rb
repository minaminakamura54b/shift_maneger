class CreateSites < ActiveRecord::Migration[8.1]
  def change
    create_table :sites do |t|
      t.string :name
      t.string :address
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
