class Alert < ActiveRecord::Base
	validates_presence_of :delivery_type, :destination, :threshold, :alert_when, :user_id
	validates_format_of :delivery_type, :with => /EMAIL|SMS/
	validates_format_of :alert_when, :with => /OVER|UNDER/

end
