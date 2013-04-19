class AddUserIdToAlerts < ActiveRecord::Migration
  def change
		add_column :alerts, :user_id, :string
  end
end
