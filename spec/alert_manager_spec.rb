require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/alert_manager'

describe "AlertManager" do
	before(:each) do
		alert = Alert.new({ :delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 60.01,
			:alert_when => "OVER",
			:user_id => "test@example.com" })
		alert.save
		alert2 = Alert.new({ :delivery_type => "EMAIL",
			:destination => "1234567890",
			:threshold => 80.01,
			:alert_when => "OVER",
			:user_id => "test@example.com" })
		alert2.save
	end

	it "should get \"OVER\" alerts when the price exceeds the threshold" do 
		triggered_alerts = AlertManager.get_alerts(50.1, 70.1)
		triggered_alerts.size.should == 1
	end

	it "should not get \"OVER\" alerts when the price falls below the threshold" do 
		triggered_alerts = AlertManager.get_alerts(70.1, 50.1)
		triggered_alerts.size.should == 0
	end

	it "should return an array of alerts" do
		triggered_alerts = AlertManager.get_alerts(10, 100)
		triggered_alerts.kind_of?(Array)
	end

	it "should get EMAIL alerts when they are triggered" do
		triggered_alerts = AlertManager.get_email_alerts(10, 100)
		triggered_alerts.size.should == 1
		triggered_alerts[0].delivery_type.should == "EMAIL"
	end

	it "should get SMS alerts when they are triggered" do
		triggered_alerts = AlertManager.get_sms_alerts(10, 100)
		triggered_alerts.size.should == 1
		triggered_alerts[0].delivery_type.should == "SMS"

	end
end
