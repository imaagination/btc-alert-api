require File.dirname(__FILE__) + '/../lib/hmac_verifier.rb'
require 'json'
require 'pp'
require 'rack/test'
require 'cgi'

RSpec.configure do |config|
	config.include Rack::Test::Methods
end

describe "HmacVerifier" do
	before(:each) do
		@secret = '123ABC'
		@session = Rack::MockSession.new HmacVerifier.new(nil, :secret => @secret)
		@test_session = Rack::Test::Session.new @session
		@body = 'destination=1234567890&delivery_type=EMAIL&alert_when=OVER&threshold=100.2&user_id=test@example.com'
		@host = 'http://alerts.btcpricealerts.com'
		@path = '/alerts'	
		@query = '?' + CGI::escape('user_id=text@example.com')
		@post_digest = Digest::HMAC.hexdigest('POST' + @path + @body, @secret, Digest::SHA1)
		@get_digest = Digest::HMAC.hexdigest('GET' + @path + @query, @secret, Digest::SHA1)
	end
	
	it "should accept requests with a valid signature" do
		@test_session.post(@path, @body, { "HTTP_X_SIGNATURE" => @post_digest })
		@test_session.last_response.status.should == 200
	end

	it "should reject requests with a missing signature" do
		@test_session.post @path, @body
		@test_session.last_response.status.should == 400
	end

	it "should reject requests with an invalid signature" do
		@test_session.post(@path, @body, { "HTTP_X_SIGNATURE" => "WRONG_SIGNATURE" })
		@test_session.last_response.status.should == 401
	end

	it "should accept valid GET requests" do
		@test_session.get(@path + @query, "", { "HTTP_X_SIGNATURE" => @get_digest }) 
		@test_session.last_response.status.should == 200
	end

	it "should reject invalid GET requests" do
		@test_session.get(@path + @query, "", { "HTTP_X_SIGNATURE" => "WRONG_SIGNATURE" }) 
		@test_session.last_response.status.should == 401
	end
end
