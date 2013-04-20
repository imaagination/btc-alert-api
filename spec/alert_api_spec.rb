require 'spec_helper'
require File.dirname(__FILE__) + '/../app/alert_api.rb'
require File.dirname(__FILE__) + '/../lib/alert_manager.rb'
require 'json'
require 'pp'

set :environment, :test

def app
	App
end

describe "Alert CRUD API" do
	it "should load the health check" do
		get '/'
		last_response.should be_ok
		parsed_response = JSON.parse(last_response.body)
		parsed_response['status'].should == 'OK'
	end

	it "should reject empty alerts" do
		post '/alerts'
		last_response.should be_bad_request
		body = JSON.parse(last_response.body)
		body["status"].should == "failure"
	end

	it "should create well formed alerts" do
		post '/alerts', 'delivery_type=SMS&destination=0123456789&threshold=45.267&alert_when=OVER&user_id=test@example.com'
		result = JSON.parse(last_response.body)
		result['alerts'][0]['id'].should_not == nil
	end

	it "should return a list of alerts" do
		alert = Alert.new({:delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 70.2,
			:alert_when => "OVER",
			:user_id => "test@example.com"})
		alert.save
		get '/alerts?user_id=test@example.com'
		returned_alerts = JSON.parse(last_response.body)
		returned_alerts["alerts"].size.should == 1
	end

	it "should reject requests that do not specify a user" do
		get '/alerts'
		last_response.should be_bad_request
	end

	it "should only return alerts for the queried user" do 
		alert = Alert.new({:delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 70.2,
			:alert_when => "OVER",
			:user_id => "test@example.com"})
		alert.save
		alert2 = Alert.new({:delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 70.2,
			:alert_when => "OVER",
			:user_id => "test2@example.com"})
		alert2.save
		get '/alerts?user_id=test@example.com' 
		returned_alerts = JSON.parse(last_response.body)
		returned_alerts["alerts"].size.should == 1
		returned_alerts["alerts"][0]['user_id'].should == "test@example.com"		
	end

	it "should delete alerts" do
		alert = Alert.new({:delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 70.2,
			:alert_when => "OVER",
			:user_id => "test@example.com"})
		alert.save
		Alert.all.size.should == 1
		delete "/alerts/#{alert.id}"
		last_response.should be_ok
		Alert.all.size.should == 0
	end

	it "should update alerts" do
		alert = Alert.new({:delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 70.2,
			:alert_when => "OVER",
			:user_id => "test@example.com"})
		alert.save
		put "/alerts/#{alert.id}", 'delivery_type=SMS&destination=1234567891&threshold=45.267&alert_when=OVER&user_id=test@example.com'
		last_response.status.should == 200
		parsed_response = JSON.parse(last_response.body)
		parsed_response["alerts"][0]["destination"].should == "1234567891"
	end
end

describe "Pricing API" do
	before(:each) do
		@ironmq = IronMQ::Client.new(:token => "TEST_TOKEN", 
			:project_id => "12345678901234567890ABCD")
		response = IronMQ::ResponseBase.new({ :result => "TEST_DATA" })
		@queue = double("queue", :post => response)
		@ironmq.stub(:queue).and_return(@queue)
		IronMQ::Client.stub(:new).and_return(@ironmq)
	end

	it "should enqueue triggered alerts" do
		alert = Alert.new({ :delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 60.01,
			:alert_when => "OVER",
			:user_id => "test@example.com"})
		AlertManager.stub(:get_alerts).and_return([alert])
		@ironmq.should_receive(:queue) 
		@queue.should_receive(:post)
		post '/price', 'timestamp=1366255439000&market=MTGOX&price=45.123'
		post '/price', 'timestamp=1366255539000&market=MTGOX&price=89.223'
		last_response.status.should == 200
	end

	it "should record prices posted to the API" do
		post '/price', 'timestamp=1366255439000&market=MTGOX&price=70.5'
		puts last_response.body
		last_response.should be_ok
		Price.all.size.should == 1
		post '/price', 'timestamp=1366255539000&market=MTGOX&price=70.5'
		last_response.should be_ok
		Price.all.size.should == 2
	end

	it "should reject poorly formed prices" do
		post '/price', 'timestamp=garbage'
		last_response.should be_bad_request
	end
end

