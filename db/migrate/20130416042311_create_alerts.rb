class CreateAlerts < ActiveRecord::Migration
	def change
		create_table :alerts do |t|
			t.string :delivery_type
			t.string :destination
			t.float :threshold
			t.string :alert_when
		end
	end
end
