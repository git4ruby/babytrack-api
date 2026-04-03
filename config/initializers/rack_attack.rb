class Rack::Attack
  # Throttle login attempts: 5 per 20 seconds per IP
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/v1/auth/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle signup: 3 per minute per IP
  throttle("signup/ip", limit: 3, period: 60.seconds) do |req|
    if req.path == "/api/v1/auth/sign_up" && req.post?
      req.ip
    end
  end

  # Throttle password reset: 3 per 5 minutes per IP
  throttle("password_reset/ip", limit: 3, period: 5.minutes) do |req|
    if req.path == "/api/v1/password/forgot" && req.post?
      req.ip
    end
  end

  # General API rate limit: 300 requests per minute per IP
  throttle("api/ip", limit: 300, period: 60.seconds) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Respond with 429
  self.throttled_responder = lambda do |env|
    [ 429, { "Content-Type" => "application/json" }, [ '{"error":"Rate limit exceeded. Please try again later."}' ] ]
  end
end
