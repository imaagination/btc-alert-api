require './app/alert_api'
require './lib/hmac_verifier'

use HmacVerifier, :secret => $config["HMAC_KEY"]
run App.new
