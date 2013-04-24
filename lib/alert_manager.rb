module AlertManager

	def self.get_alerts(beg_val, end_val)
		Alert.where("(threshold >= ? AND threshold < ? AND alert_when = ?) OR \
			(threshold <= ? AND threshold > ? AND alert_when = ?)",
			beg_val, end_val, "OVER", beg_val, end_val, "UNDER")		
	end

	def self.get_email_alerts(beg_val, end_val)
		Alert.where("((threshold >= ? AND threshold < ? AND alert_when = ?) OR \
			(threshold <= ? AND threshold > ? AND alert_when = ?)) AND \
			delivery_type = ?",
			beg_val, end_val, "OVER", beg_val, end_val, "UNDER", "EMAIL")
	end

	def self.get_sms_alerts(beg_val, end_val)
		Alert.where("((threshold >= ? AND threshold < ? AND alert_when = ?) OR \
			(threshold <= ? AND threshold > ? AND alert_when = ?)) AND \
			delivery_type = 'SMS'",
			beg_val, end_val, "OVER", beg_val, end_val, "UNDER")		
	end
end
