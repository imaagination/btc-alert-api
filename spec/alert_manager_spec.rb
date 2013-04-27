require 'spec_helper'
require File.dirname(__FILE__) + '/../lib/alert_manager'

describe "AlertManager" do
	before(:each) do
		@alert = Alert.new({ :delivery_type => "SMS",
			:destination => "1234567890",
			:threshold => 60.01,
			:alert_when => "OVER",
			:user_id => "test@example.com" })
		@alert.save
		@alert2 = Alert.new({ :delivery_type => "EMAIL",
			:destination => "test@example.com",
			:threshold => 80.01,
			:alert_when => "OVER",
			:user_id => "test@example.com" })
		@alert2.save
		@alert3 = Alert.new({ :delivery_type => "EMAIL",
			:destination => "test@example.com",
			:threshold => 80.01,
			:alert_when => "UNDER",
			:user_id => "test@example.com" })
		@alert3.save
	end

	it "should get \"OVER\" alerts when the price exceeds the threshold" do 
		triggered_alerts = AlertManager.get_alerts({ second_last: 50.1, last: 70.1 })
		triggered_alerts.index { |a| a.id == @alert.id }.should_not == nil
	end

	it "should not get \"OVER\" alerts when the price falls below the threshold" do 
		triggered_alerts = AlertManager.get_alerts({ second_last: 70.1, last: 50.1 })
		triggered_alerts.index { |a| a.id == @alert.id }.should == nil
	end

	it "should return an array of alerts" do
		triggered_alerts = AlertManager.get_alerts({ second_last: 10, last: 100 })
		triggered_alerts.kind_of?(Array)
	end

	it "should get EMAIL alerts when they are triggered" do
		triggered_alerts = AlertManager.get_alerts({ second_last: 10, last: 100, type: "EMAIL" })
		index = triggered_alerts.index { |a| a.id == @alert2.id }
		index.should_not == nil
		triggered_alerts[index].delivery_type.should == "EMAIL"
	end

	it "should get SMS alerts when they are triggered" do
		triggered_alerts = AlertManager.get_alerts({ second_last: 10, last: 100, type: "SMS" })
		index = triggered_alerts.index { |a| a.id == @alert.id }
		index.should_not == nil
		triggered_alerts[index].delivery_type.should == "SMS"
	end

	it "should trigger an alert when the price breaks the threshold going up" do
		triggered_alerts = AlertManager.get_alerts({ second_last: 60.01, last: 100 })
		triggered_alerts.index { |a| a.id == @alert.id }.should_not == nil
	end

	it "should trigger an alert when the price breaks the threshold going down" do
		triggered_alerts = AlertManager.get_alerts({ second_last: 80.01, last: 50 })
		triggered_alerts.index { |a| a.id == @alert3.id }.should_not == nil
	end
end
