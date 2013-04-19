module AlertManager

	def self.get_alerts(beg_val, end_val)
		Alert.where("(threshold > ? AND threshold < ? AND alert_when = ?) OR \
			(threshold < ? AND threshold > ? AND alert_when = ?)",
			beg_val, end_val, "OVER", beg_val, end_val, "UNDER")		
	end

end
