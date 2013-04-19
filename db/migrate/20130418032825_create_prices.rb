class CreatePrices < ActiveRecord::Migration
  def change
		create_table :prices do |t|
			t.string :market
			t.datetime :timestamp
			t.float :price
		end
  end
end
