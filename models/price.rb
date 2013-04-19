class Price < ActiveRecord::Base
	validates_presence_of :timestamp, :market, :price
	validates_format_of :market, :with => /MTGOX/
end
