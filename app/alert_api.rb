require 'sinatra'
require 'sinatra/activerecord'
require File.dirname(__FILE__) + '/../config'
require File.dirname(__FILE__) + '/../models/alert'
require File.dirname(__FILE__) + '/../models/price'
require File.dirname(__FILE__) + '/../lib/alert_manager'
require 'pp'
require 'json'
require 'iron_mq'

ActiveRecord::Base.include_root_in_json = false

class App < Sinatra::Base
	use ActiveRecord::ConnectionAdapters::ConnectionManagement

	before do
		content_type :json
	end

	get '/' do
		{ status: "OK" }.to_json
	end

	post '/alerts' do
		alert = Alert.new params
		if alert.save then
			{ status: "success", alerts: [ alert ] }.to_json
		else
			status 400
			{ status: "failure", messages: alert.errors.full_messages }.to_json
		end
	end

	get '/alerts' do
		if params[:user_id].nil? 
			body({ status: "failure", messages: [ "User id required" ] }.to_json)
			halt 400
		end
		alerts = Alert.where('user_id = ?', params[:user_id])
		{ status: "success", alerts: alerts }.to_json
	end

	put '/alerts/:id' do
		alert = Alert.find_by_id(params['id'])
		params.slice!('delivery_type', 'destination', 'threshold', 'alert_when')
		if alert.nil?
			body({ status: "failure", messages: [ "Alert not found" ] }.to_json)
			halt 404
		end
		if alert.update_attributes(params)
			{ status: "success", alerts: [ alert ] }.to_json
		else
			status 400
			{ status: "failure", messages: alert.errors.full_messages }.to_json
		end
	end

	delete '/alerts/:id' do
		alert = Alert.find_by_id(params[:id])
		if alert.nil? 
			status 404
			{ status: "failure", messages: [ "Alert not found" ] }.to_json
		elsif alert.destroy
			{ status: "success" }.to_json
		else
			status 400
			{ status: "failure", messages: alert.errors.full_messages }.to_json
		end
	end

	post '/price' do
		# Save price
		params[:timestamp] = Time.at(params[:timestamp].to_f / 1000)
		price = Price.new params
		if price.save then
			# Grab last two prices
			last_prices = Price.order(:timestamp).reverse_order.limit(2)

			if last_prices.size == 2
				# Find the triggered alerts
				beg_val = last_prices[1].price
				end_val = last_prices[0].price
				alerts = AlertManager.get_alerts(beg_val, end_val).to_a

				if alerts.size > 0
					# Convert alerts to array of hashes
					alerts.map! {|i| { :body => i.attributes.merge({:price => end_val}).to_json } }

					# Initialize queue
					ironmq = IronMQ::Client.new({:token => $config['IRON_KEY'],
						:project_id => $config['IRON_PROJECT']})
					queue = ironmq.queue("email_alerts")

					# Send alerts to queue
					pp alerts
					queue.post(alerts)
				end
			end
			content_type :json
			prices_hash = price.attributes
			prices_hash["timestamp"] = price.timestamp.to_i * 1000
			{ status: "success", price: prices_hash }.to_json
		else
			status 400
			{ status: "failure", messages: price.errors.full_messages }.to_json
		end
	end
end
