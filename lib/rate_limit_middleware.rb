class RateLimitMiddleware
  def initialize(app)
    @app = app
    @redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
  rescue Redis::CannotConnectError
    @redis = nil
  end

  def call(env)
    request = Rack::Request.new(env)
    
    # Apply rate limiting to sensitive endpoints
    if should_rate_limit?(request)
      return rate_limited_response if rate_limited?(request)
    end

    @app.call(env)
  end

  private

  def should_rate_limit?(request)
    sensitive_paths = [
      '/checkout',
      '/webhooks/stripe',
      '/users/sign_in',
      '/users/sign_up'
    ]
    
    sensitive_paths.any? { |path| request.path.start_with?(path) }
  end

  def rate_limited?(request)
    return false unless @redis

    key = "rate_limit:#{request.ip}:#{request.path}"
    count = @redis.get(key).to_i

    if count >= limit_for_path(request.path)
      true
    else
      @redis.incr(key)
      @redis.expire(key, window_for_path(request.path))
      false
    end
  end

  def limit_for_path(path)
    case path
    when /\/checkout/
      10 # 10 requests per window
    when /\/webhooks/
      100 # Webhooks might need higher limits
    else
      20 # Default limit
    end
  end

  def window_for_path(path)
    case path
    when /\/checkout/
      900 # 15 minutes
    when /\/webhooks/
      60 # 1 minute
    else
      300 # 5 minutes
    end
  end

  def rate_limited_response
    [429, { 'Content-Type' => 'text/plain' }, ['Too Many Requests']]
  end
end
