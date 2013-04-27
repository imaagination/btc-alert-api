module AlertManager

	def self.get_alerts(opts = {})
		query = Alert.select("*")
		if opts[:second_last] and opts[:last]
			high = opts.slice(:second_last, :last).values.max
			low = opts.slice(:second_last, :last).values.min
			query = query.where("threshold >= ? AND threshold <= ?", low, high)
			query = query.where("alert_when = ?", 
				opts[:second_last] < opts[:last] ? "OVER" : "UNDER")
		end
		query = query.where(:delivery_type => opts["type"]) unless opts["type"].nil?
		return query
	end

end
