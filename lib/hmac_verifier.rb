class HmacVerifier

	def initialize(app, opts = {})
		@app = app
		@secret = opts[:secret].nil? ? 'SECRET' : opts[:secret]
	end

	def call(env)
		if env["HTTP_X_SIGNATURE"].nil?
			return [400, { "Content-Type" => "application/json"},
				['{"status":"failure", "messages":["HMAC signature required"]}']]
		end
		if env["HTTP_X_SIGNATURE"] != compute_signature(env, @secret)
			return [401, { "Content-Type" => "application/json"},
				['{"status":"failure", "messages":["HMAC signature invalid"]}']]
		end
		return [200, {}, ["No app configured"]] if @app.nil?
		@app.call(env)
	end

	private

	def compute_signature env, secret
		full_path = String.new env['PATH_INFO']
		full_path << '?' + env['QUERY_STRING'] unless env['QUERY_STRING'] == ""
		message_body = "#{env['REQUEST_METHOD']}#{full_path}#{env['rack.input'].read}"
		Digest::HMAC.hexdigest(message_body, secret, Digest::SHA1)
	end

end
